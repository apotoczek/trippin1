def handler(event, _context):
    route = event.get("route", {})
    distance = route.get("distance_km", 0)
    event["score"] = max(0, 100 - int(distance / 10))
    return event
