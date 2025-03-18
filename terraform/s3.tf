# Declare the S3 bucket for CloudTrail logs
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket = "bg-cloudtrail-logs-bucket-2025"
  force_destroy = true
}

# Declare the aws_caller_identity data source to get the account id
data "aws_caller_identity" "current" {}

# Define the S3 bucket policy for CloudTrail
resource "aws_s3_bucket_policy" "cloudtrail_policy" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs.id}"
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs.id}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Sid       = "AllowAccountWrite"
        Effect    = "Allow"
        Principal = { "AWS" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
        Action    = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource  = "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs.id}/*"
      },
      {
        Sid       = "AllowLambdaRead"
        Effect    = "Allow"
        Principal = { "AWS" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/lambda_redshift_role" }
        Action    = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource  = [
          "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs.id}",
          "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs.id}/*"
        ]
      }
    ]
  })
}
