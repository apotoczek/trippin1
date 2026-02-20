def handler(event, _context):
    event["route"] = {
        "mode": "basic",
        "distance_km": 560,
        "duration_minutes": 380,
    }
    return event
