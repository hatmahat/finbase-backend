from supabase import Client


def get_name_to_id(client: Client) -> dict[str, int]:
    result = client.table("categories").select("id, name").execute()
    return {row["name"]: row["id"] for row in result.data}
