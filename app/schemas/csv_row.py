from pydantic import BaseModel, Field, field_validator
from datetime import datetime
from decimal import Decimal


class CsvRow(BaseModel):
    date: datetime
    amount: Decimal
    type: str
    category: str | None = None
    origin_wallet: str = Field(alias="originWallet")
    destination_wallet: str | None = Field(default=None, alias="destinationWallet")
    note: str | None = None
    location: str | None = None

    model_config = {"populate_by_name": True}

    @field_validator("type", "category", "origin_wallet", "destination_wallet", "note", "location", mode="before")
    @classmethod
    def strip_whitespace(cls, v: str | None) -> str | None:
        return v.strip() if isinstance(v, str) else v
