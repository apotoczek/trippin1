output "api_base_url" {
  value = aws_apigatewayv2_api.http_api.api_endpoint
}

output "auth_start_url" {
  value = "${aws_apigatewayv2_api.http_api.api_endpoint}/auth/start"
}
