output "api_base_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

output "http_api_id" {
  value = aws_apigatewayv2_api.http_api.id
}

output "http_api_execution_arn" {
  value = aws_apigatewayv2_api.http_api.execution_arn
}
