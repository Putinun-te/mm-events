output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.main.name
}

output "kubeconfig_command" {
  description = "Writes a kubeconfig entry for the cluster."
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.main.name}"
}

output "vpc_id" {
  description = "VPC ID (the Load Balancer Controller needs it)."
  value       = aws_vpc.main.id
}

output "lb_controller_role_arn" {
  description = "IAM role for the AWS Load Balancer Controller's service account."
  value       = aws_iam_role.lb_controller.arn
}

output "backend_role_arn" {
  description = "IAM role for the backend's service account (reads the two secrets)."
  value       = aws_iam_role.backend.arn
}

output "ecr_backend_url" {
  description = "Push the backend image here."
  value       = aws_ecr_repository.app["backend"].repository_url
}

output "ecr_frontend_url" {
  description = "Push the frontend image here."
  value       = aws_ecr_repository.app["frontend"].repository_url
}

output "db_endpoint" {
  description = "RDS endpoint (private; reachable from the VPC only)."
  value       = aws_db_instance.mysql.address
}

output "db_password_secret_arn" {
  description = "Secrets Manager secret holding the RDS master password (created by RDS)."
  value       = aws_db_instance.mysql.master_user_secret[0].secret_arn
}

output "jwt_secret_name" {
  description = "Secrets Manager secret holding the JWT signing key."
  value       = aws_secretsmanager_secret.jwt.name
}

# Values for deploy/helm/mm-events, together with values-aws.yaml. Contains no secret
# values, only names and ARNs:
#   terraform output -raw helm_values > mm-events-values.yaml
output "helm_values" {
  description = "Cloud-specific values for the Helm chart (no secrets)."
  value = yamlencode({
    backend = {
      image = { repository = aws_ecr_repository.app["backend"].repository_url }
      datasource = {
        host     = aws_db_instance.mysql.address
        port     = aws_db_instance.mysql.port
        database = var.db_name
        username = var.db_username
      }
      serviceAccount = {
        name        = var.k8s_service_account
        annotations = { "eks.amazonaws.com/role-arn" = aws_iam_role.backend.arn }
      }
    }
    frontend = {
      image = { repository = aws_ecr_repository.app["frontend"].repository_url }
    }
    secrets = {
      externalSecrets = {
        provider = {
          aws = {
            service = "SecretsManager"
            region  = var.region
            auth    = { jwt = { serviceAccountRef = { name = var.k8s_service_account } } }
          }
        }
        dbPassword = { key = aws_db_instance.mysql.master_user_secret[0].secret_arn, property = "password" }
        jwtSecret  = { key = aws_secretsmanager_secret.jwt.name }
      }
    }
  })
}
