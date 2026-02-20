from src.lambdas.route_basic.app import handler as route_handler


def test_route_basic_smoke():
    event = {"origin": {}, "destination": {}}
    result = route_handler(event, None)
    assert result["route"]["mode"] == "basic"
