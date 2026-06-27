from supabase import Client


def upsert_transactions(client: Client, rows: list[dict]) -> tuple[int, int]:
    """Insert rows, ignoring fingerprint conflicts. Returns (inserted, skipped)."""
    if not rows:
        return 0, 0

    result = (
        client.table("transactions")
        .upsert(rows, on_conflict="fingerprint", ignore_duplicates=True)
        .execute()
    )

    inserted = len(result.data) if result.data else 0
    skipped = len(rows) - inserted
    return inserted, skipped
