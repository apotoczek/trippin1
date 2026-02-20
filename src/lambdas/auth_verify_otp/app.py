import json
import os
import boto3
from botocore.exceptions import ClientError

from src.common.responses import json_response


cognito = boto3.client("cognito-idp")
USER_POOL_CLIENT_ID = os.environ.get("USER_POOL_CLIENT_ID", "")


def handler(event, _context):
    body = json.loads(event.get("body") or "{}")
    phone_number = body.get("phone_number")
    otp_code = body.get("otp_code")
    session = body.get("session")

    if not USER_POOL_CLIENT_ID:
        return json_response(500, {"message": "USER_POOL_CLIENT_ID is not configured"})
    if not phone_number or not otp_code:
        return json_response(400, {"message": "phone_number and otp_code are required"})

    try:
        response = cognito.respond_to_auth_challenge(
            ClientId=USER_POOL_CLIENT_ID,
            ChallengeName="CUSTOM_CHALLENGE",
            Session=session,
            ChallengeResponses={
                "USERNAME": phone_number,
                "ANSWER": otp_code,
            },
        )

        auth = response.get("AuthenticationResult", {})
        return json_response(
            200,
            {
                "access_token": auth.get("AccessToken"),
                "id_token": auth.get("IdToken"),
                "refresh_token": auth.get("RefreshToken"),
                "expires_in": auth.get("ExpiresIn"),
                "token_type": auth.get("TokenType"),
            },
        )
    except ClientError as exc:
        return json_response(401, {"message": str(exc)})
