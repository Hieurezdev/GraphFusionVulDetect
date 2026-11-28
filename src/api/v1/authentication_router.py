import jwt
from datetime import timedelta
from typing import Optional
from src.utils.helper import get_password_hash, verify_password
from fastapi import APIRouter, Depends, HTTPException, status, Request, Response
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from bson import ObjectId
from bson.errors import InvalidId
from src.models.entity import UserRegister, UserLogin, Token, UserProfile, UserInDB, PasswordChange, ConsentSubmit, AccountDelete
from src.infrastructure.database import get_users_collection
from src.utils.timezone import now_utc, now_vietnam, ensure_utc_for_db
from src.config.settings import settings


# Security configuration
SECRET_KEY = settings.SECRET_KEY
JWT_SECRET = settings.JWT_SECRET
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = int(settings.ACCESS_TOKEN_EXPIRE_MINUTES)

# HTTP Bearer token
security = HTTPBearer(auto_error=False)

# Step 2.5: the browser keeps the token in an httpOnly cookie (JavaScript cannot read it, so XSS cannot steal it).
# API clients and scripts keep sending "Authorization: Bearer". A request authenticated by the cookie that changes
# something must also carry X-Requested-With: a page on another site cannot add that header without a CORS preflight.
CSRF_HEADER, CSRF_VALUE = "X-Requested-With", "ScanGuard"
SAFE_METHODS = {"GET", "HEAD", "OPTIONS"}


def set_auth_cookie(response: Response, token: str) -> None:
    response.set_cookie(settings.AUTH_COOKIE_NAME, token, max_age=ACCESS_TOKEN_EXPIRE_MINUTES * 60, httponly=True,
                        secure=settings.AUTH_COOKIE_SECURE, samesite=settings.AUTH_COOKIE_SAMESITE, path="/")


def clear_auth_cookie(response: Response) -> None:
    response.delete_cookie(settings.AUTH_COOKIE_NAME, path="/", secure=settings.AUTH_COOKIE_SECURE,
                           httponly=True, samesite=settings.AUTH_COOKIE_SAMESITE)
router = APIRouter(prefix="/auth", tags=["authentication"])


def create_access_token(data: dict, expires_delta: Optional[timedelta] = None):
    """Create a JWT access token"""
    to_encode = data.copy()
    if expires_delta:
        expire = now_vietnam() + expires_delta
    else:
        expire = now_vietnam() + timedelta(minutes=15)
    
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, JWT_SECRET, algorithm=ALGORITHM)
    return encoded_jwt


async def get_user(username: str) -> Optional[UserInDB]:
    """Get user from database by username, else by email (username first, so the lookup is deterministic)"""
    users_collection = await get_users_collection()
    user_doc = await users_collection.find_one({"username": username}) or await users_collection.find_one({"email": username})
    if user_doc:
        user_doc["_id"] = str(user_doc["_id"])
        return UserInDB(**user_doc)
    return None


async def authenticate_user(username: str, password: str) -> Optional[UserInDB]:
    """Authenticate user with username/email and password"""
    user = await get_user(username)
    if not user:
        return None
    if not verify_password(password, user.hashed_password):
        return None
    return user


async def get_current_user(request: Request, credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)) -> UserInDB:
    """Get current authenticated user from the bearer token, or from the httpOnly session cookie (browser)"""
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    if credentials is not None:
        token = credentials.credentials
    else:
        token = request.cookies.get(settings.AUTH_COOKIE_NAME)
        if not token:
            raise credentials_exception
        if request.method not in SAFE_METHODS and request.headers.get(CSRF_HEADER) != CSRF_VALUE:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Missing anti-CSRF header")

    try:
        payload = jwt.decode(token, JWT_SECRET, algorithms=[ALGORITHM])
        user_id = ObjectId(payload["user_id"])
    except (jwt.PyJWTError, KeyError, TypeError, ValueError, InvalidId):
        raise credentials_exception

    # Resolve by the immutable id, never by name: a username may equal someone else's email.
    user_doc = await (await get_users_collection()).find_one({"_id": user_id})
    if user_doc is None:
        raise credentials_exception
    user_doc["_id"] = str(user_doc["_id"])
    user = UserInDB(**user_doc)
    if payload.get("ver", 0) != user.token_version or not user.is_active:
        raise credentials_exception
    from src.services.organizations import get_organization
    user.organization = await get_organization(user.organization_id)
    # Nothing but reading and accepting the legal texts (or leaving) until the current versions are accepted
    from src.services.legal import missing_consents
    missing = missing_consents(user)
    if missing and not request.url.path.rstrip("/").endswith(CONSENT_FREE_PATHS):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail={"code": "consent_required", "missing": missing})
    return user


CONSENT_FREE_PATHS = ("/auth/me", "/auth/consents", "/auth/logout", "/auth/logout-all", "/auth/change-password", "/auth/account")


def profile_of(user: UserInDB) -> UserProfile:
    from src.services.access import allowed, is_personal
    from src.services.legal import missing_consents
    from src.services.organizations import policy_of, llm_is_external
    return UserProfile(
        user_id=user.id, username=user.username, email=user.email, full_name=user.full_name,
        created_at=user.created_at, last_login=user.last_login, role=user.role if user.role != "user" else "admin",
        organization_id=user.organization_id, organization_name=(user.organization or {}).get("name"),
        personal_workspace=is_personal(user), permissions=allowed(user), policy=policy_of(user.organization) if user.organization else {},
        llm_external=llm_is_external(), consents_required=missing_consents(user))


def issue_token(user: UserInDB, token_version: int) -> Token:
    """Create a bearer token bound to the user's current token version"""
    access_token = create_access_token(
        data={"sub": user.username, "user_id": user.id, "ver": token_version},
        expires_delta=timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    )
    return Token(access_token=access_token, token_type="bearer", expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60)


@router.post("/register", response_model=UserProfile)
async def register_user(user_data: UserRegister):
    """Register a new user"""
    users_collection = await get_users_collection()

    
    # Check if user already exists
    names = [user_data.username, user_data.email]
    existing_user = await users_collection.find_one({
        "$or": [{"username": {"$in": names}}, {"email": {"$in": names}}]
    })
    
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username or email already registered"
        )
    
    # Create new user: a self-registered account gets its own workspace and is its admin. A personal (guest) workspace
    # stays one person; a business one is an organisation the admin fills with members.
    business = user_data.account_type == "business"
    if business and not (user_data.organization_name or "").strip():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="A business account needs the organisation's name")
    from src.services.organizations import create_organization
    org = await create_organization((user_data.organization_name or "").strip() if business else (user_data.full_name or user_data.username),
                                    personal=not business)
    hashed_password = get_password_hash(user_data.password)
    user_doc = {
        "username": user_data.username,
        "email": user_data.email,
        "full_name": user_data.full_name,
        "hashed_password": hashed_password,
        "is_active": True,
        "role": "admin",
        "organization_id": str(org["_id"]),
        "consents": {},
        "created_at": ensure_utc_for_db(now_vietnam()),
        "last_login": None
    }
    
    # Insert user into database
    result = await users_collection.insert_one(user_doc)
    user_doc["_id"] = str(result.inserted_id)
    
    # Return user profile (without password)
    return UserProfile(
        user_id=user_doc["_id"],
        username=user_doc["username"],
        email=user_doc["email"],
        full_name=user_doc["full_name"],
        created_at=user_doc["created_at"]
    )


@router.post("/login", response_model=Token)
async def login_for_access_token(user_data: UserLogin, response: Response):
    """Authenticate user and return access token"""
    users_collection = await get_users_collection()
    
    user = await authenticate_user(user_data.username, user_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Update last login timestamp
    await users_collection.update_one(
        {"_id": ObjectId(user.id)},
        {"$set": {"last_login": ensure_utc_for_db(now_vietnam())}}
    )
    
    # Create access token
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user.username, "user_id": user.id, "ver": user.token_version},
        expires_delta=access_token_expires
    )
    set_auth_cookie(response, access_token)
    return Token(
        access_token=access_token,
        token_type="bearer",
        expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60
    )


@router.get("/me", response_model=UserProfile)
async def read_users_me(current_user: UserInDB = Depends(get_current_user)):
    """Get current user profile, with the workspace, permissions and the legal texts still to accept"""
    return profile_of(current_user)


@router.post("/logout")
async def logout(response: Response, current_user: UserInDB = Depends(get_current_user)):
    """Logout user: the session cookie is cleared (an API client discards its bearer token)"""
    clear_auth_cookie(response)
    return {"message": "Successfully logged out"}


@router.put("/profile", response_model=UserProfile)
async def update_profile(
    profile_data: dict,
    current_user: UserInDB = Depends(get_current_user)
):
    """Update user profile"""
    users_collection = await get_users_collection()
    
    # Remove sensitive fields that shouldn't be updated
    update_data = {k: v for k, v in profile_data.items() 
                   if k in ["full_name", "bio"] and v is not None}
    
    if not update_data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No valid fields to update"
        )
    
    # Update user in database
    await users_collection.update_one(
        {"_id": ObjectId(current_user.id)},
        {"$set": update_data}
    )
    
    # Get updated user
    updated_user = await get_user(current_user.username)
    updated_user.organization = current_user.organization
    return profile_of(updated_user)


@router.post("/change-password", response_model=Token)
async def change_password(
    password_data: PasswordChange,
    response: Response,
    current_user: UserInDB = Depends(get_current_user)
):
    """Change the password, sign out every other session and return a fresh token"""
    if not verify_password(password_data.current_password, current_user.hashed_password):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Current password is incorrect")
    if verify_password(password_data.new_password, current_user.hashed_password):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="New password must differ from the current one")

    users_collection = await get_users_collection()
    new_version = current_user.token_version + 1
    await users_collection.update_one(
        {"_id": ObjectId(current_user.id)},
        {"$set": {
            "hashed_password": get_password_hash(password_data.new_password),
            "token_version": new_version,
            "password_changed_at": ensure_utc_for_db(now_vietnam()),
        }}
    )
    token = issue_token(current_user, new_version)
    set_auth_cookie(response, token.access_token)
    return token


@router.post("/logout-all")
async def logout_all(response: Response, current_user: UserInDB = Depends(get_current_user)):
    """Invalidate every token issued for this user, this one included"""
    users_collection = await get_users_collection()
    await users_collection.update_one(
        {"_id": ObjectId(current_user.id)},
        {"$inc": {"token_version": 1}}
    )
    clear_auth_cookie(response)
    return {"message": "Signed out on every device"}


# ---- Legal texts, consent and account deletion (docs/KE_HOACH_BAO_VE_MA_NGUON.md, section 5) -----------------------
@router.get("/legal")
async def legal_documents(lang: str = "vi"):
    """The terms and licence, privacy policy, upload commitment and training-data text, in English or Vietnamese (public)."""
    from src.services.legal import documents
    return documents(lang)


@router.post("/consents", response_model=UserProfile)
async def submit_consents(body: ConsentSubmit, current_user: UserInDB = Depends(get_current_user)):
    """Accept the current versions of the required documents. A workspace admin also chooses whether its code may be
    used for training; for other members that is their admin's decision, so their answer is ignored."""
    from src.services.legal import DOCUMENTS
    from src.services.access import can
    from src.services import audit
    from src.infrastructure.database import get_collection
    required = [k for k, (_, _, req) in DOCUMENTS.items() if req]
    refused = [k for k in required if not getattr(body, k)]
    if refused:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail={"code": "consent_refused", "missing": refused})
    now = ensure_utc_for_db(now_vietnam())
    accepted = {k: DOCUMENTS[k][1] for k in required}
    rows = [{"user_id": current_user.id, "document": k, "version": v, "accepted": True, "at": now} for k, v in accepted.items()]
    if body.training_data is not None and current_user.organization_id and can(current_user, "manage_organization"):
        rows.append({"user_id": current_user.id, "document": "training_data", "version": DOCUMENTS["training_data"][1],
                     "accepted": bool(body.training_data), "organization_id": current_user.organization_id, "at": now})
        from src.api.v1.organization_router import apply_policy
        await apply_policy(current_user, {"training_data": bool(body.training_data)})
    await (await get_collection("consents")).insert_many(rows)
    await (await get_users_collection()).update_one({"_id": ObjectId(current_user.id)},
                                                    {"$set": {f"consents.{k}": v for k, v in accepted.items()}})
    await audit.record(current_user, "consent", current_user.organization_id, detail={r["document"]: r["accepted"] for r in rows})
    current_user.consents = {**current_user.consents, **accepted}
    if body.training_data is not None and current_user.organization:
        current_user.organization = {**current_user.organization,
                                     "policy": {**(current_user.organization.get("policy") or {}), "training_data": bool(body.training_data)}}
    return profile_of(current_user)


def pseudonym(user: UserInDB) -> str:
    import hashlib
    return "deleted-user-" + hashlib.sha256(user.id.encode()).hexdigest()[:8]


@router.delete("/account")
async def delete_account(body: AccountDelete, response: Response, current_user: UserInDB = Depends(get_current_user)):
    """Delete this account. Alone in a workspace: the workspace with all its projects, scans and code goes too. In a
    shared workspace the scans stay with the organisation that owns them. The name on expert verdicts becomes a pseudonym."""
    from src.services import audit, data_lifecycle
    from src.services.access import is_personal, role_of
    from src.services.label_log import scrub
    from src.infrastructure.database import (get_collection, get_analysis_sessions_collection, get_projects_collection,
                                             get_label_events_collection)
    if not verify_password(body.password, current_user.hashed_password):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Password is incorrect")
    users = await get_users_collection()
    org_id = current_user.organization_id
    others = await users.count_documents({"organization_id": org_id, "_id": {"$ne": ObjectId(current_user.id)}}) if org_id else 0
    if org_id and others and role_of(current_user) == "admin" and not await users.count_documents(
            {"organization_id": org_id, "role": "admin", "is_active": True, "_id": {"$ne": ObjectId(current_user.id)}}):
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Make another member an admin before deleting the last admin account")
    name, removed = pseudonym(current_user), {}
    if org_id and not others:  # alone: the workspace and everything in it
        sessions, projects = await get_analysis_sessions_collection(), await get_projects_collection()
        n = 0
        async for p in projects.find({"organization_id": org_id}):
            n += (await data_lifecycle.delete_project(p, name))["sessions"]
        async for s in sessions.find({"organization_id": org_id}):
            await data_lifecycle.delete_session(s, name, reason="account_deleted")
            n += 1
        await (await get_collection("organizations")).delete_one({"_id": ObjectId(org_id)})
        removed["sessions"] = n
    elif not org_id:  # a ScanGuard reviewer: their own uploads
        sessions = await get_analysis_sessions_collection()
        async for s in sessions.find({"user_id": current_user.id}):
            await data_lifecycle.delete_session(s, name, reason="account_deleted")
    u = current_user.username
    removed["label_events_pseudonymised"] = await scrub(await get_label_events_collection(), {"reviewer": u}, {"reviewer": name})
    sessions = await get_analysis_sessions_collection()
    await sessions.update_many({"reviews.reviewer": u}, {"$set": {"reviews.$[r].reviewer": name}}, array_filters=[{"r.reviewer": u}])
    for field, value in (("checked_by", u), ("checked_by", f"{u} (repair agent)"), ("decided_by", u)):
        await sessions.update_many({f"fixes.{field}": value}, {"$set": {f"fixes.$[f].{field}": value.replace(u, name, 1)}},
                                   array_filters=[{f"f.{field}": value}])
    await users.delete_one({"_id": ObjectId(current_user.id)})
    if org_id and others:
        await audit.record(name, "delete_account", org_id, detail=removed)
    await data_lifecycle.log_deletion(org_id if others else None, "account", name, name, "manual", removed)
    clear_auth_cookie(response)
    return {"message": "Account deleted", "removed": removed}
