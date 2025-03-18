resource "aws_iam_role" "lambda_role" {
  name = "lambda_redshift_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_s3_access" {
  name = "lambda_s3_access_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.cloudtrail_logs.arn}",
          "${aws_s3_bucket.cloudtrail_logs.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "${aws_s3_bucket.cloudtrail_logs.arn}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_xray" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_redshift" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonRedshiftFullAccess"
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# ✅ Add permission for Lambda to read from S3
resource "aws_iam_role_policy" "lambda_s3_read_access" {
  name = "lambda_s3_read_access"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = "arn:aws:s3:::bg-cloudtrail-logs-bucket-2025/*"
      }
    ]
  })
}

# Add permission for Lambda to access Secrets Manager to fetch Redshift credentials
resource "aws_iam_role_policy" "lambda_secretsmanager_access" {
  name = "lambda_secretsmanager_access_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",   # Permission to get the secret
          "secretsmanager:PutSecretValue"    # Permission to update (put) the secret
        ]
        Resource = "arn:aws:secretsmanager:us-west-1:084375561488:secret:bg-redshift-credentials-*"
      }
    ]
  })
}
