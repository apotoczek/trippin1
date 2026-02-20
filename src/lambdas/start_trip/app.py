import json
import os
import boto3

from src.common.responses import json_response


sfn = boto3.client("stepfunctions")
STATE_MACHINE_ARN = os.environ.get("STATE_MACHINE_ARN", "")


def handler(event, _context):
    body = json.loads(event.get("body") or "{}")

    if not STATE_MACHINE_ARN:
        return json_response(500, {"message": "STATE_MACHINE_ARN is not configured"})

    response = sfn.start_execution(
        stateMachineArn=STATE_MACHINE_ARN,
        input=json.dumps(body),
    )
    return json_response(
        202,
        {
            "message": "trip workflow started",
            "execution_arn": response["executionArn"],
            "start_date": response["startDate"].isoformat(),
        },
    )
