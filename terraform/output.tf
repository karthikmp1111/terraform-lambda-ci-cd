output "lambda_function_arn" {
  value = aws_lambda_function.process_logs.arn
}

output "redshift_endpoint" {
  value = aws_redshift_cluster.security_cluster.endpoint
}