# Event rule
resource "aws_cloudwatch_event_rule" "ec2_rule" {
  name          = "ec2-state-change"
  description   = "EC2 state changes to terminate"
  event_pattern = <<EOF
{
    "detail-type": ["EC2 Instance State-change Notification"],
    "detail": {
      "state": ["shutting-down", "terminated", "stopping", "stopped", "running", "pending"]
    }
}
  EOF
}

# Target for event
resource "aws_cloudwatch_event_target" "health-lambda" {
  rule      = aws_cloudwatch_event_rule.ec2_rule.name
  target_id = "SendToSNS"
  arn       = aws_lambda_function.restore_lambda.arn
}

# Permissions for Event Bridge to trigger the Lambda
resource "aws_lambda_permission" "allow_cloudwatch_to_call_restore" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.restore_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ec2_rule.arn
}
