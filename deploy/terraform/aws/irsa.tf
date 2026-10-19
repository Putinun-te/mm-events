# IAM roles for service accounts (IRSA): pods assume an IAM role through the cluster's
# OIDC provider, without node-wide credentials.

resource "aws_iam_openid_connect_provider" "eks" {
  url            = aws_eks_cluster.main.identity[0].oidc[0].issuer
  client_id_list = ["sts.amazonaws.com"]
}

locals {
  oidc_issuer = replace(aws_iam_openid_connect_provider.eks.url, "https://", "")
}

# Trust policy for one Kubernetes service account
data "aws_iam_policy_document" "irsa_assume" {
  for_each = {
    backend       = "system:serviceaccount:${var.k8s_namespace}:${var.k8s_service_account}"
    lb_controller = "system:serviceaccount:kube-system:aws-load-balancer-controller"
  }

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:sub"
      values   = [each.value]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

# --- Backend: read the two secrets (used by the External Secrets Operator through the
#     backend's service account) --------------------------------------------------------

resource "aws_iam_role" "backend" {
  name               = "${var.project}-backend"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume["backend"].json
}

data "aws_iam_policy_document" "read_secrets" {
  statement {
    actions = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = [
      aws_secretsmanager_secret.jwt.arn,
      aws_db_instance.mysql.master_user_secret[0].secret_arn,
    ]
  }
}

resource "aws_iam_role_policy" "backend_secrets" {
  name   = "read-app-secrets"
  role   = aws_iam_role.backend.id
  policy = data.aws_iam_policy_document.read_secrets.json
}

# --- AWS Load Balancer Controller --------------------------------------------------------

# Policy published with the controller (docs/install/iam_policy.json, v3.6.0)
resource "aws_iam_policy" "lb_controller" {
  name        = "${var.project}-aws-load-balancer-controller"
  description = "Permissions of the AWS Load Balancer Controller"
  policy      = file("${path.module}/policies/aws-load-balancer-controller.json")
}

resource "aws_iam_role" "lb_controller" {
  name               = "${var.project}-aws-load-balancer-controller"
  assume_role_policy = data.aws_iam_policy_document.irsa_assume["lb_controller"].json
}

resource "aws_iam_role_policy_attachment" "lb_controller" {
  role       = aws_iam_role.lb_controller.name
  policy_arn = aws_iam_policy.lb_controller.arn
}
