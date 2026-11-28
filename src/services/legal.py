"""Versioned legal texts a user accepts before using the service, in English and Vietnamese (src/legal/<key>.<lang>.md).
Bump a version and every user is asked again at their next sign-in. Both languages share one version."""
from pathlib import Path

from src.utils.language import normalize_language

DIR = Path(__file__).resolve().parent.parent / "legal"

# key -> (title by language, version, required). training_data is the workspace's choice, made by its admin.
DOCUMENTS = {
    "terms": ({"en": "Terms of use and software licence", "vi": "Điều khoản sử dụng và giấy phép phần mềm"}, "v1", True),
    "privacy": ({"en": "Personal data and source code policy", "vi": "Chính sách xử lý dữ liệu cá nhân và mã nguồn"}, "v1", True),
    "upload_rights": ({"en": "Right to upload the code", "vi": "Cam kết quyền tải mã lên"}, "v1", True),
    "training_data": ({"en": "Use of code as training data", "vi": "Cho dùng mã làm dữ liệu huấn luyện"}, "v1", False),
}


def documents(language: str = "vi") -> list:
    lang = normalize_language(language)
    return [{"key": k, "title": t[lang], "version": v, "required": r, "language": lang,
             "content": (DIR / f"{k}.{lang}.md").read_text(encoding="utf-8")}
            for k, (t, v, r) in DOCUMENTS.items()]


def missing_consents(user) -> list:
    """Required documents whose current version this user has not accepted."""
    accepted = getattr(user, "consents", None) or {}
    return [k for k, (_, v, required) in DOCUMENTS.items() if required and accepted.get(k) != v]
