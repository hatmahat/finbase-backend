from datetime import date, datetime
from decimal import Decimal
from supabase import Client


def _serialize(row: dict) -> dict:
    """Convert Python types that aren't JSON-serializable to strings."""
    return {
        k: (v.isoformat() if isinstance(v, (datetime, date)) else
            str(v) if isinstance(v, Decimal) else v)
        for k, v in row.items()
    }


def upsert_transactions(client: Client, rows: list[dict]) -> tuple[int, int]:
    """Insert rows, ignoring fingerprint conflicts. Returns (inserted, skipped)."""
    if not rows:
        return 0, 0

    result = (
        client.table("transactions")
        .upsert([_serialize(r) for r in rows], on_conflict="fingerprint", ignore_duplicates=True)
        .execute()
    )

    inserted = len(result.data) if result.data else 0
    skipped = len(rows) - inserted
    return inserted, skipped
