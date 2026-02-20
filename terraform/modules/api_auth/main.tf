resource "aws_iam_role" "lambda_exec" {
  name = "${var.project_name}-${var.env_name}-auth-lambda-role"

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

resource "aws_iam_role_policy" "cognito_initiate_auth" {
  name = "${var.project_name}-${var.env_name}-cognito-init-auth"
  role = aws_iam_role.lambda_exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "cognito-idp:InitiateAuth"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_lambda_function" "auth_start_otp" {
  function_name    = "${var.project_name}-${var.env_name}-auth-start-otp"
  role             = aws_iam_role.lambda_exec.arn
  handler          = "src.lambdas.auth_start_otp.app.handler"
  runtime          = "python3.12"
  timeout          = 15
  memory_size      = 256
  filename         = var.lambda_zip_path
  source_code_hash = var.lambda_zip_hash

  environment {
    variables = {
      USER_POOL_CLIENT_ID = var.cognito_user_pool_client_id
      LOG_LEVEL           = var.log_level
    }
  }
}

resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project_name}-${var.env_name}-http-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_methods = ["POST", "OPTIONS"]
    allow_origins = ["*"]
    allow_headers = ["content-type", "authorization"]
    max_age       = 300
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_apigatewayv2_integration" "auth_start_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.auth_start_otp.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "auth_start_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "POST /auth/start"
  target    = "integrations/${aws_apigatewayv2_integration.auth_start_integration.id}"
}

resource "aws_lambda_permission" "allow_api_invoke" {
  statement_id  = "AllowExecutionFromHttpApi"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth_start_otp.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.http_api.execution_arn}/*/*"
}
