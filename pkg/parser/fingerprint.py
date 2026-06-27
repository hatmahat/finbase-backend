import hashlib
from datetime import date
from decimal import Decimal


def make(wallet: str, txn_date: date, amount: Decimal, description: str) -> str:
    raw = f"{wallet}|{txn_date}|{amount}|{description.lower().strip()}"
    return hashlib.sha256(raw.encode()).hexdigest()
