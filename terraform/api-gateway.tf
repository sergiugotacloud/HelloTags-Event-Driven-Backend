resource "aws_apigatewayv2_api" "api" {
  name          = "hellotags-api"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_integration" "lambda" {
  api_id           = aws_apigatewayv2_api.api.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.tap_handler.invoke_arn
}

resource "aws_apigatewayv2_route" "tap" {
  api_id    = aws_apigatewayv2_api.api.id
  route_key = "POST /tap"
  target    = "integrations/${aws_apigatewayv2_integration.lambda.id}"
}

resource "aws_lambda_permission" "api" {
  statement_id  = "AllowAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.tap_handler.function_name
  principal     = "apigateway.amazonaws.com"
}
