from supabase import Client
from app.models.transaction import Transaction
from app.repositories.base import upsert_transactions
from dataclasses import asdict


def insert_many(client: Client, transactions: list[Transaction]) -> tuple[int, int]:
    rows = [asdict(t) for t in transactions]
    return upsert_transactions(client, rows)
