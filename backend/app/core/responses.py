from __future__ import annotations

from datetime import datetime, timezone
from typing import Any


def _timestamp() -> str:
    return datetime.now(timezone.utc).isoformat()


def success_response(data: Any, status: str = "success") -> dict[str, Any]:
    return {
        "status": status,
        "data": data,
        "error": None,
        "metadata": {"timestamp": _timestamp()},
    }


def error_response(message: str, code: str, *, details: Any = None, status: str = "error") -> dict[str, Any]:
    return {
        "status": status,
        "data": None,
        "error": {
            "code": code,
            "message": message,
            "details": details,
        },
        "metadata": {"timestamp": _timestamp()},
    }
