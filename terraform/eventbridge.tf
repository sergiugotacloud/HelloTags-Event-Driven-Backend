resource "aws_cloudwatch_event_rule" "tap_rule" {
  event_pattern = jsonencode({
    source = ["hellotags.tap"]
  })
}

resource "aws_cloudwatch_event_target" "notification" {
  rule = aws_cloudwatch_event_rule.tap_rule.name
  arn  = aws_lambda_function.notification_handler.arn
}

resource "aws_cloudwatch_event_target" "analytics" {
  rule = aws_cloudwatch_event_rule.tap_rule.name
  arn  = aws_lambda_function.analytics_handler.arn
}

resource "aws_lambda_permission" "event_notification" {
  statement_id  = "AllowEventBridgeNotification"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notification_handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.tap_rule.arn
}

resource "aws_lambda_permission" "event_analytics" {
  statement_id  = "AllowEventBridgeAnalytics"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.analytics_handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.tap_rule.arn
}
