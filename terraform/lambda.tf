resource "aws_lambda_function" "tap_handler" {
  function_name = "tap-handler"
  role          = aws_iam_role.lambda_role.arn
  handler       = "tap_handler.lambda_handler"
  runtime       = "python3.12"
  filename      = "lambda/tap_handler.zip"

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id]
    security_group_ids = [aws_security_group.ec2_sg.id]
  }

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.tap_events.name
    }
  }
}

resource "aws_lambda_function" "notification_handler" {
  function_name = "notification-handler"
  role          = aws_iam_role.lambda_role.arn
  handler       = "notification_handler.lambda_handler"
  runtime       = "python3.12"
  filename      = "lambda/notification_handler.zip"
}

resource "aws_lambda_function" "analytics_handler" {
  function_name = "analytics-handler"
  role          = aws_iam_role.lambda_role.arn
  handler       = "analytics_handler.lambda_handler"
  runtime       = "python3.12"
  filename      = "lambda/analytics_handler.zip"
}
