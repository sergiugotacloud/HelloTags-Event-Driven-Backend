resource "aws_lambda_function" "tap_handler" {
  function_name = "tap-handler"
  role          = aws_iam_role.lambda_role.arn

  handler = "tap_handler.lambda_handler"
  runtime = "python3.12"

  filename         = "${path.module}/../lambda/tap-handler.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/tap-handler.zip")

  timeout = 10

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.tap_events.name
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id]
    security_group_ids = [aws_security_group.ec2_sg.id]
  }

  tags = {
    Project = "hellotags"
  }
}

resource "aws_lambda_function" "notification_handler" {
  function_name = "notification-handler"
  role          = aws_iam_role.lambda_role.arn

  handler = "notification_handler.lambda_handler"
  runtime = "python3.12"

  filename         = "${path.module}/../lambda/notification-handler.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/notification-handler.zip")

  timeout = 10

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id]
    security_group_ids = [aws_security_group.ec2_sg.id]
  }

  tags = {
    Project = "hellotags"
  }
}

resource "aws_lambda_function" "analytics_handler" {
  function_name = "analytics-handler"
  role          = aws_iam_role.lambda_role.arn

  handler = "analytics_handler.lambda_handler"
  runtime = "python3.12"

  filename         = "${path.module}/../lambda/analytics-handler.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/analytics-handler.zip")

  timeout = 10

  environment {
    variables = {
      # Dynamic reference instead of hardcoded IP
      EC2_API_URL = "http://${aws_instance.admin.private_ip}:5000/analytics"
    }
  }

  vpc_config {
    subnet_ids         = [aws_subnet.private_a.id]
    security_group_ids = [aws_security_group.ec2_sg.id]
  }

  depends_on = [aws_instance.admin]

  tags = {
    Project = "hellotags"
  }
}
