resource "aws_redshift_cluster" "security_cluster" {
  cluster_identifier   = "security-cluster"
  database_name        = "security_logs"
  master_username      = "admin"
  master_password      = "BgAdmin$123"
  node_type            = "dc2.large"
  cluster_type         = "single-node"
  skip_final_snapshot  = true
  encrypted            = true
}