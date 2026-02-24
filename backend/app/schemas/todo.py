from __future__ import annotations

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, ConfigDict, Field, field_validator, model_validator


class TodoCreate(BaseModel):
    title: str = Field(min_length=1, max_length=200)

    @field_validator("title")
    @classmethod
    def validate_title(cls, value: str) -> str:
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("제목은 비어 있을 수 없습니다.")
        return cleaned


class TodoUpdate(BaseModel):
    title: Optional[str] = Field(default=None, min_length=1, max_length=200)
    is_completed: Optional[bool] = None

    @field_validator("title")
    @classmethod
    def validate_title(cls, value: Optional[str]) -> Optional[str]:
        if value is None:
            return None
        cleaned = value.strip()
        if not cleaned:
            raise ValueError("제목은 비어 있을 수 없습니다.")
        return cleaned

    @model_validator(mode="after")
    def ensure_any_field(self) -> "TodoUpdate":
        if self.title is None and self.is_completed is None:
            raise ValueError("수정할 필드가 필요합니다.")
        return self


class TodoRead(BaseModel):
    id: int
    title: str
    is_completed: bool
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
