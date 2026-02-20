def handler(event, _context):
    event["flags"] = {
        "use_google_routing": False,
        "enable_weather_risk": False,
    }
    return event
