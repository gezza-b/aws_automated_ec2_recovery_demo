# Lambda Restore function
resource "aws_lambda_function" "restore_lambda" {
  filename         = "restore.zip"
  function_name    = "restore"
  role             = aws_iam_role.role_restore.arn
  handler          = "restore.lambda_handler"
  source_code_hash = filebase64sha256("restore.zip")
  runtime          = "python3.9"

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      name = "restore-lambda"
    }
  }
}

# zip file for Lambda upload
data "archive_file" "lambda_source_package" {
  type        = "zip"
  source_file = "./restore.py"
  output_path = "./restore.zip"
}

# Log group
resource "aws_cloudwatch_log_group" "lambda_restore" {
  name              = "/aws/lambda/restore"
  retention_in_days = 3
}
