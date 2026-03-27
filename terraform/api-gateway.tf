resource "aws_apigatewayv2_api" "public_api" {
  name          = "hellotags-public-api"
  protocol_type = "HTTP"

  tags = {
    Project = "hellotags"
  }
}

resource "aws_apigatewayv2_integration" "tap_lambda_integration" {
  api_id = aws_apigatewayv2_api.public_api.id

  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.tap_handler.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "tap_route" {
  api_id = aws_apigatewayv2_api.public_api.id

  route_key = "POST /tap"
  target    = "integrations/${aws_apigatewayv2_integration.tap_lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.public_api.id
  name        = "prod"
  auto_deploy = true

  tags = {
    Environment = "prod"
  }
}

resource "aws_lambda_permission" "api_gw_permission" {
  statement_id  = "AllowAPIGatewayInvokeTapHandler"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tap_handler.function_name
  principal     = "apigateway.amazonaws.com"

  # Restrict ONLY to this API + route
  source_arn = "${aws_apigatewayv2_api.public_api.execution_arn}/prod/POST/tap"
}
