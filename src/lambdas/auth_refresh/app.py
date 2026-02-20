import json
import os
import boto3
from botocore.exceptions import ClientError

from src.common.responses import json_response


cognito = boto3.client("cognito-idp")
USER_POOL_CLIENT_ID = os.environ.get("USER_POOL_CLIENT_ID", "")


def handler(event, _context):
    body = json.loads(event.get("body") or "{}")
    refresh_token = body.get("refresh_token")

    if not USER_POOL_CLIENT_ID:
        return json_response(500, {"message": "USER_POOL_CLIENT_ID is not configured"})
    if not refresh_token:
        return json_response(400, {"message": "refresh_token is required"})

    try:
        response = cognito.initiate_auth(
            ClientId=USER_POOL_CLIENT_ID,
            AuthFlow="REFRESH_TOKEN_AUTH",
            AuthParameters={"REFRESH_TOKEN": refresh_token},
        )
        auth = response.get("AuthenticationResult", {})
        return json_response(
            200,
            {
                "access_token": auth.get("AccessToken"),
                "id_token": auth.get("IdToken"),
                "expires_in": auth.get("ExpiresIn"),
                "token_type": auth.get("TokenType"),
            },
        )
    except ClientError as exc:
        return json_response(401, {"message": str(exc)})
