import os
from datetime import datetime, timezone


def handler(event, _context):
    table_name = os.environ.get("TRIPS_TABLE_NAME", "")

    event["persisted"] = {
        "table": table_name or "UNCONFIGURED",
        "saved_at": datetime.now(timezone.utc).isoformat(),
    }
    return event
