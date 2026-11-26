from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from typing import List, Optional
from src.services.token_service import TokenService, SourceNotVerified, RateLimited, TokenNotFound
# Assuming project_service is available to create projects
# from src.services.project_service import project_service 
import logging
from .authentication_router import get_current_user

router = APIRouter(prefix="/token", tags=["token"], dependencies=[Depends(get_current_user)])  # each call spends our explorer API quota
logger = logging.getLogger("TokenRouter")
token_service = TokenService() #Or instantiate properly if singleton

class TokenSearchQuery(BaseModel):
    query: str

class TokenSearchResult(BaseModel):
    id: str
    name: str
    symbol: str
    thumb: Optional[str] = None

class TokenAnalyzeRequest(BaseModel):
    chain: str
    address: str
    name: str

@router.get("/search", response_model=List[TokenSearchResult])
def search_tokens(query: str):
    """
    Search for tokens by name or symbol.
    """
    try:
        results = token_service.search_token(query)
        # Transform to response model
        return [
            TokenSearchResult(
                id=c.get("id"),
                name=c.get("name"),
                symbol=c.get("symbol"),
                thumb=c.get("thumb") or c.get("large") 
            ) for c in results
        ]
    except RateLimited:
        raise HTTPException(status_code=429, detail="The token directory is busy right now. Wait a minute and search again.")
    except Exception as e:
        logger.error(f"Search failed: {e}")
        raise HTTPException(status_code=502, detail="Token lookup failed upstream; try again later.")

@router.get("/platforms/{coin_id}")
def get_token_platforms(coin_id: str):
    """
    Get supported platforms/addresses for a token.
    """
    try:
        details = token_service.get_token_details(coin_id)
        return token_service.supported_platforms(details.get("platforms", {}))
    except RateLimited:
        raise HTTPException(status_code=429, detail="The token directory is busy right now. Wait a minute and pick the token again.")
    except TokenNotFound:
        raise HTTPException(status_code=404, detail="This token was not found in the token directory.")
    except Exception as e:
        logger.error(f"Get details failed: {e}")
        raise HTTPException(status_code=502, detail="Token lookup failed upstream; try again later.")

@router.post("/analyze")
async def analyze_token(request: TokenAnalyzeRequest):
    """
    Fetch source code for a token and return it for the frontend to process/create project.
    """
    try:
        # Fetch source code in a non-blocking way
        import asyncio
        loop = asyncio.get_event_loop()
        
        contract_data = await loop.run_in_executor(
            None, 
            token_service.fetch_source_code, 
            request.address, 
            request.chain
        )
        
        source_code = contract_data.get("source_code")
        if not source_code:
            raise HTTPException(status_code=404, detail="Source code not found or not verified.")

        return {
            "source_code": source_code,
            "contract_name": contract_data.get("name"),
            "file_name": f"{request.address}.sol",
            "abi": contract_data.get("abi")
        }

    except HTTPException:
        raise
    except SourceNotVerified:
        raise HTTPException(status_code=404, detail="This contract's source code is not published on the block explorer, so it cannot be scanned.")
    except ValueError:
        raise HTTPException(status_code=400, detail="This network is not supported.")
    except Exception as e:
        # requests errors embed the full URL, apikey included: log it, never return it.
        logger.error(f"Analysis setup failed: {e}")
        raise HTTPException(status_code=502, detail="Could not fetch the contract source from the explorer; check the chain and address.")
