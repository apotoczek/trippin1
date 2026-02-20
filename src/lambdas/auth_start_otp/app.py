import os
import boto3
from botocore.exceptions import ClientError

from src.common.responses import json_response


cognito = boto3.client("cognito-idp")
USER_POOL_CLIENT_ID = os.environ.get("USER_POOL_CLIENT_ID", "")


def handler(event, _context):
    body = event.get("body") or "{}"
    phone_number = __import__("json").loads(body).get("phone_number")

    if not USER_POOL_CLIENT_ID:
        return json_response(500, {"message": "USER_POOL_CLIENT_ID is not configured"})
    if not phone_number:
        return json_response(400, {"message": "phone_number is required"})

    try:
        response = cognito.initiate_auth(
            ClientId=USER_POOL_CLIENT_ID,
            AuthFlow="CUSTOM_AUTH",
            AuthParameters={"USERNAME": phone_number},
        )
        return json_response(
            200,
            {
                "message": "OTP challenge started",
                "session": response.get("Session"),
                "challenge_name": response.get("ChallengeName"),
            },
        )
    except ClientError as exc:
        return json_response(400, {"message": str(exc)})
