resource "aws_dynamodb_table" "trips" {
  name         = "${var.project_name}-${var.env_name}-trips"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "trip_id"

  attribute {
    name = "trip_id"
    type = "S"
  }
}

resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-${var.env_name}-workflow-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_workflow_policy" {
  name = "${var.project_name}-${var.env_name}-workflow-policy"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["states:StartExecution"]
        Resource = [aws_sfn_state_machine.trip_workflow.arn]
      },
      {
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:UpdateItem"]
        Resource = [aws_dynamodb_table.trips.arn]
      }
    ]
  })
}

# Workflow Lambdas
resource "aws_lambda_function" "get_flags" {
  function_name    = "${var.project_name}-${var.env_name}-get-flags"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "src.lambdas.get_flags.app.handler"
  runtime          = "python3.12"
  filename         = var.lambda_zip_path
  source_code_hash = var.lambda_zip_hash
  environment { variables = { LOG_LEVEL = var.log_level } }
}

resource "aws_lambda_function" "geocode" {
  function_name    = "${var.project_name}-${var.env_name}-geocode"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "src.lambdas.geocode.app.handler"
  runtime          = "python3.12"
  filename         = var.lambda_zip_path
  source_code_hash = var.lambda_zip_hash
  environment { variables = { LOG_LEVEL = var.log_level } }
}

resource "aws_lambda_function" "route_basic" {
  function_name    = "${var.project_name}-${var.env_name}-route-basic"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "src.lambdas.route_basic.app.handler"
  runtime          = "python3.12"
  filename         = var.lambda_zip_path
  source_code_hash = var.lambda_zip_hash
  environment { variables = { LOG_LEVEL = var.log_level } }
}

resource "aws_lambda_function" "score" {
  function_name    = "${var.project_name}-${var.env_name}-score"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "src.lambdas.score.app.handler"
  runtime          = "python3.12"
  filename         = var.lambda_zip_path
  source_code_hash = var.lambda_zip_hash
  environment { variables = { LOG_LEVEL = var.log_level } }
}

resource "aws_lambda_function" "persist" {
  function_name    = "${var.project_name}-${var.env_name}-persist"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "src.lambdas.persist.app.handler"
  runtime          = "python3.12"
  filename         = var.lambda_zip_path
  source_code_hash = var.lambda_zip_hash
  environment {
    variables = {
      LOG_LEVEL        = var.log_level
      TRIPS_TABLE_NAME = aws_dynamodb_table.trips.name
    }
  }
}

resource "aws_lambda_function" "start_trip" {
  function_name    = "${var.project_name}-${var.env_name}-start-trip"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "src.lambdas.start_trip.app.handler"
  runtime          = "python3.12"
  filename         = var.lambda_zip_path
  source_code_hash = var.lambda_zip_hash
  environment {
    variables = {
      LOG_LEVEL         = var.log_level
      STATE_MACHINE_ARN = aws_sfn_state_machine.trip_workflow.arn
    }
  }
}

# Step Functions
resource "aws_iam_role" "sfn_exec" {
  name = "${var.project_name}-${var.env_name}-sfn-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "states.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "sfn_policy" {
  name = "${var.project_name}-${var.env_name}-sfn-policy"
  role = aws_iam_role.sfn_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = ["lambda:InvokeFunction"]
      Resource = [
        aws_lambda_function.get_flags.arn,
        aws_lambda_function.geocode.arn,
        aws_lambda_function.route_basic.arn,
        aws_lambda_function.score.arn,
        aws_lambda_function.persist.arn
      ]
    }]
  })
}

resource "aws_sfn_state_machine" "trip_workflow" {
  name     = "${var.project_name}-${var.env_name}-trip-workflow"
  role_arn = aws_iam_role.sfn_exec.arn

  definition = jsonencode({
    StartAt = "GetFlags"
    States = {
      GetFlags = {
        Type     = "Task"
        Resource = aws_lambda_function.get_flags.arn
        Next     = "Geocode"
      }
      Geocode = {
        Type     = "Task"
        Resource = aws_lambda_function.geocode.arn
        Next     = "RouteBasic"
      }
      RouteBasic = {
        Type     = "Task"
        Resource = aws_lambda_function.route_basic.arn
        Next     = "Score"
      }
      Score = {
        Type     = "Task"
        Resource = aws_lambda_function.score.arn
        Next     = "Persist"
      }
      Persist = {
        Type     = "Task"
        Resource = aws_lambda_function.persist.arn
        End      = true
      }
    }
  })
}

# API Gateway integration for start_trip
resource "aws_apigatewayv2_integration" "start_trip_integration" {
  api_id                 = var.http_api_id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.start_trip.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "start_trip_route" {
  api_id    = var.http_api_id
  route_key = "POST /trips/start"
  target    = "integrations/${aws_apigatewayv2_integration.start_trip_integration.id}"
}

resource "aws_lambda_permission" "allow_api_invoke_start_trip" {
  statement_id  = "AllowExecutionFromHttpApiStartTrip"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.start_trip.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.http_api_execution_arn}/*/*"
}
