from pydantic import BaseModel, Field
from datetime import date
from decimal import Decimal


class ExtractedTransaction(BaseModel):
    txn_date: date
    amount: Decimal = Field(gt=0)
    type: str = Field(description="expense | income | transfer")
    category: str | None = None
    wallet: str = Field(description="source wallet name as it appears on the statement")
    to_wallet: str | None = Field(default=None, description="destination wallet for transfers")
    note: str | None = None
    raw_description: str | None = None
    balance_after: Decimal | None = None
    confidence: float = Field(ge=0, le=1)
