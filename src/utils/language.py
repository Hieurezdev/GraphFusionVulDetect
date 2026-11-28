LANGUAGES = {"en": "English", "vi": "Vietnamese"}


def normalize_language(value) -> str:
    return value if value in LANGUAGES else "en"


PLAIN = ("\nThe reader does not program (a manager, an investor, a lawyer). Use everyday words, short sentences and an "
         "example of what could go wrong with money or access. Avoid jargon such as 'reentrancy', 'external call', "
         "'state variable', 'modifier', 'gas' or 'compiler'; when a technical word cannot be avoided, explain it in a few "
         "plain words. Keep any required headings, line citations and code blocks.")


def language_instruction(value, plain: bool = False) -> str:
    """Line appended to every LLM prompt so the answer follows the user's language setting (and, for a non-technical
    reader, avoids jargon)."""
    if normalize_language(value) == "vi":
        text = ("\n\nWrite the whole answer in Vietnamese (tiếng Việt). "
                "Keep code, identifiers, function names and Solidity keywords exactly as they are.")
    else:
        text = "\n\nWrite the whole answer in English."
    return text + (PLAIN if plain else "")
