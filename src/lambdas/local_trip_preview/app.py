import json
import logging
import os
from math import asin, cos, radians, sin, sqrt
from urllib.parse import urlencode
from urllib.request import Request, urlopen

from src.common.debugging import maybe_enable_pycharm_debugger
from src.common.responses import json_response

LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO").upper()
logging.basicConfig(level=getattr(logging, LOG_LEVEL, logging.INFO))
logger = logging.getLogger(__name__)
maybe_enable_pycharm_debugger(logger)


def _haversine_km(lat1, lon1, lat2, lon2):
    radius_km = 6371.0
    d_lat = radians(lat2 - lat1)
    d_lon = radians(lon2 - lon1)
    a = sin(d_lat / 2) ** 2 + cos(radians(lat1)) * cos(radians(lat2)) * sin(d_lon / 2) ** 2
    c = 2 * asin(sqrt(a))
    return radius_km * c


def _fallback_geocode(address: str):
    value = abs(hash(address))
    lat = 24.5 + (value % 2300) / 100.0
    lng = -124.0 + (value % 5700) / 100.0
    lat = max(24.5, min(lat, 49.4))
    lng = max(-124.0, min(lng, -66.9))
    return {"lat": round(lat, 5), "lng": round(lng, 5), "source": "fallback"}


def _geocode_address(address: str):
    query = urlencode({"q": address, "format": "json", "limit": 1})
    url = f"https://nominatim.openstreetmap.org/search?{query}"
    request = Request(url, headers={"User-Agent": "trip-planner-local-test/1.0"})

    try:
        with urlopen(request, timeout=3) as response:
            payload = json.loads(response.read().decode("utf-8"))
            if payload:
                return {
                    "lat": float(payload[0]["lat"]),
                    "lng": float(payload[0]["lon"]),
                    "source": "nominatim",
                }
    except Exception:
        pass

    return _fallback_geocode(address)


def handler(event, _context):
    query = event.get("queryStringParameters") or {}
    body = json.loads(event.get("body") or "{}")
    from_address = (query.get("from_address") or body.get("from_address") or "").strip()
    to_address = (query.get("to_address") or body.get("to_address") or "").strip()

    if not from_address or not to_address:
        return json_response(400, {"message": "from_address and to_address are required"})

    origin = _geocode_address(from_address)
    destination = _geocode_address(to_address)

    distance_km = _haversine_km(origin["lat"], origin["lng"], destination["lat"], destination["lng"])
    duration_minutes = int((distance_km / 72.0) * 60)
    score = max(0, 100 - int(distance_km / 12))

    return json_response(
        200,
        {
            "from_address": from_address,
            "to_address": to_address,
            "origin": origin,
            "destination": destination,
            "route": {
                "mode": "basic-local",
                "distance_km": round(distance_km, 2),
                "duration_minutes": duration_minutes,
                "path": [
                    [origin["lat"], origin["lng"]],
                    [destination["lat"], destination["lng"]],
                ],
            },
            "score": score,
            "flags": {
                "use_google_routing": False,
                "enable_weather_risk": False,
            },
            "local_only": True,
        },
    )
