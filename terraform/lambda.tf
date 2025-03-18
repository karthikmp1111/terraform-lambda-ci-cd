# Create a ZIP archive of the Lambda function code
# data "archive_file" "lambda_zip" {
#   type        = "zip"
#   source_file = "lambda_function.py"
#   output_path = "lambda_function.zip"
# }

# Define the Lambda function using the generated ZIP file
resource "aws_lambda_function" "process_logs" {
  # filename         = data.archive_file.lambda_zip.output_path
  filename         = "../lambda/lambda_function.zip"
  function_name    = "ProcessSecurityLogs"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9"
  timeout          = 60
  memory_size      = 128
  layers           = ["arn:aws:lambda:us-west-1:084375561488:layer:psycopg2-layer:1"]

  # source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  source_code_hash = filebase64sha256("../lambda/lambda_function.zip")

  environment {
    variables = {
      SECRET_NAME = "bg-redshift-credentials"
      REGION      = "us-west-1"
    }
  }

  tracing_config {
    mode = "Active"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ✅ Allow S3 to invoke the Lambda function
resource "aws_lambda_permission" "s3_invoke_lambda" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.process_logs.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.cloudtrail_logs.arn
  source_account = data.aws_caller_identity.current.account_id
}

# ✅ Configure S3 bucket to trigger Lambda on new object creation
resource "aws_s3_bucket_notification" "s3_event" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.process_logs.arn
    events              = ["s3:ObjectCreated:*"]
  }

  depends_on = [aws_lambda_permission.s3_invoke_lambda]
}
