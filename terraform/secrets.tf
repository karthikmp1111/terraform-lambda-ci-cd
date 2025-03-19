# Fetch the existing secret from Secrets Manager by name
data "aws_secretsmanager_secret" "redshift_secret" {
  name = "bg-redshift-credentials"
}

# Fetch the current version of the secret (to retain other values)
data "aws_secretsmanager_secret_version" "current_redshift_secret_version" {
  secret_id = data.aws_secretsmanager_secret.redshift_secret.id
}

# Update the Redshift credentials in the existing secret
resource "aws_secretsmanager_secret_version" "redshift_secret_version" {
  secret_id     = data.aws_secretsmanager_secret.redshift_secret.id  # Reference the existing secret by ID
  secret_string = jsonencode({
    REDSHIFT_USER     = jsondecode(data.aws_secretsmanager_secret_version.current_redshift_secret_version.secret_string).REDSHIFT_USER,
    REDSHIFT_PASSWORD = jsondecode(data.aws_secretsmanager_secret_version.current_redshift_secret_version.secret_string).REDSHIFT_PASSWORD,
    REDSHIFT_HOST     = split(":", aws_redshift_cluster.security_cluster.endpoint)[0],
    REDSHIFT_DBNAME   = jsondecode(data.aws_secretsmanager_secret_version.current_redshift_secret_version.secret_string).REDSHIFT_DBNAME,
    REDSHIFT_PORT     = jsondecode(data.aws_secretsmanager_secret_version.current_redshift_secret_version.secret_string).REDSHIFT_PORT
  })

  depends_on = [
    aws_redshift_cluster.security_cluster
  ]
}
