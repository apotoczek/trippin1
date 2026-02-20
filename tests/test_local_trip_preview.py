import json

from src.lambdas.local_trip_preview.app import handler


def test_local_trip_preview_smoke():
    event = {
        "queryStringParameters": {
            "from_address": "Seattle, WA",
            "to_address": "Portland, OR",
        }
    }
    response = handler(event, None)

    assert response["statusCode"] == 200
    payload = json.loads(response["body"])
    assert payload["local_only"] is True
    assert payload["route"]["distance_km"] >= 0
