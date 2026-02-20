def handler(event, _context):
    origin = event.get("origin", {})
    destination = event.get("destination", {})

    event["origin_geocode"] = {
        "lat": origin.get("lat", 37.7749),
        "lng": origin.get("lng", -122.4194),
    }
    event["destination_geocode"] = {
        "lat": destination.get("lat", 34.0522),
        "lng": destination.get("lng", -118.2437),
    }
    return event
