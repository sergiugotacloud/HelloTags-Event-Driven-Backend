resource "aws_dynamodb_table" "tap_events" {
  name         = "tap-events"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "card_id"
  range_key = "timestamp"

  attribute {
    name = "card_id"
    type = "S"
  }

  # Use STRING for timestamp (matches Lambda behavior)
  attribute {
    name = "timestamp"
    type = "S"
  }

  tags = {
    Name    = "hellotags-tap-events"
    Project = "hellotags"
  }
}
