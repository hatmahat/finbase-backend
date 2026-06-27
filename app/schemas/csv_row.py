from pydantic import BaseModel, Field
from datetime import date
from decimal import Decimal


class CsvRow(BaseModel):
    date: date
    amount: Decimal
    type: str
    category: str | None = None
    origin_wallet: str = Field(alias="originWallet")
    destination_wallet: str | None = Field(default=None, alias="destinationWallet")
    note: str | None = None
    location: str | None = None

    model_config = {"populate_by_name": True}
