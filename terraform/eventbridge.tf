resource "aws_cloudwatch_event_rule" "tap_events_rule" {
  name        = "tap-events-rule"
  description = "Routes tap events to downstream consumers"

  event_pattern = jsonencode({
    source      = ["hellotags.tap"]
    detail-type = ["TapEvent"]
  })

  tags = {
    Project = "hellotags"
  }
}

# Notification Lambda target
resource "aws_cloudwatch_event_target" "notification_target" {
  rule      = aws_cloudwatch_event_rule.tap_events_rule.name
  target_id = "NotificationLambda"
  arn       = aws_lambda_function.notification_handler.arn
}

resource "aws_lambda_permission" "allow_eventbridge_notification" {
  statement_id  = "AllowEventBridgeNotification"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.notification_handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.tap_events_rule.arn
}

# Analytics Lambda target
resource "aws_cloudwatch_event_target" "analytics_target" {
  rule      = aws_cloudwatch_event_rule.tap_events_rule.name
  target_id = "AnalyticsLambda"
  arn       = aws_lambda_function.analytics_handler.arn
}

resource "aws_lambda_permission" "allow_eventbridge_analytics" {
  statement_id  = "AllowEventBridgeAnalytics"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.analytics_handler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.tap_events_rule.arn
}
