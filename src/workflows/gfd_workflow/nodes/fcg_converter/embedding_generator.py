# File: src/nodes/fcg_converter/embedding_generator.py

import re
from typing import List
import numpy as np
import torch


def clean_function(function_list: List[str]) -> List[str]:
    """
    Cleans a list of function names parsed from Slither output.
    
    It removes hexadecimal address prefixes and replaces underscores
    with periods to create a more readable function signature.

    Args:
        function_list (List[str]): A list of raw function names.

    Returns:
        List[str]: A list of cleaned function names.
    """
    return [
        re.sub(r"0x[0-9a-z]+\.sol_\d+_", "", func).replace("_", ".")
        for func in function_list
    ]


def get_embeddings(tokenizer, model, text: str) -> 'np.ndarray':
    """
    Generates a dense vector embedding for a given text using a transformer model.

    This function tokenizes the input text, feeds it to the model, and returns
    the embedding of the [CLS] token from the last hidden state.

    Args:
        tokenizer: A Hugging Face tokenizer instance.
        model: A Hugging Face transformer model instance.
        text (str): The input text (e.g., a function's source code) to embed.

    Returns:
        np.ndarray: A 1D NumPy array representing the text embedding.
    """
    inputs = tokenizer(text, return_tensors='pt', truncation=True, padding=True)
    inputs = {key: value.to(model.device) for key, value in inputs.items()}
    
    with torch.no_grad():
        outputs = model(**inputs)

    # Use the embedding of the [CLS] token as the sentence representation
    embeddings = outputs.last_hidden_state[:, 0, :].squeeze().cpu().numpy()
    return embeddings


def extract_function_code(source_file: str, start: int, length: int) -> str:
    """
    Extracts a specific slice of text from a source file.

    Reads the content of the file and returns the substring defined by the
    start index and length, typically representing a function's source code.

    Args:
        source_file (str): The path to the source code file.
        start (int): The starting UTF-8 byte offset of the code snippet.
        length (int): The length of the code snippet in bytes.

    Returns:
        str: The extracted source code of the function.
    """
    # Solidity source mappings use UTF-8 byte offsets, not Python characters.
    if start is None or length is None:
        return ""
    with open(source_file, 'rb') as source:
        return source.read()[start:start + length].decode('utf-8')
