"""AWS deployment: deploy/terraform/aws + deploy/helm/mm-events on EKS."""

from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import EC2AutoScaling, ECR, EKS
from diagrams.aws.database import RDSMysqlInstance
from diagrams.aws.management import CloudwatchLogs
from diagrams.aws.network import ALB, NATGateway
from diagrams.aws.security import IAMRole, SecretsManager
from diagrams.k8s.clusterconfig import HPA
from diagrams.k8s.compute import Deployment, Pod
from diagrams.k8s.podconfig import Secret
from diagrams.onprem.client import Users

from common import diagram_kwargs

with Diagram(**diagram_kwargs("MM Events on AWS EKS (deploy/terraform/aws + deploy/helm)", "aws")):
    users = Users("Browser")

    with Cluster("AWS region (ap-southeast-1)"):
        ecr = ECR("ECR\nbackend + frontend images")
        secrets = SecretsManager("Secrets Manager\nDB password (RDS-managed)\nJWT secret")
        irsa = IAMRole("IRSA roles\nbackend, LB controller")
        logs = CloudwatchLogs("CloudWatch Logs\ncontrol plane")

        with Cluster("VPC"):
            with Cluster("Public subnets (2 AZ)"):
                alb = ALB("ALB\nfrom the Ingress")
                nat = NATGateway("NAT gateway")

            with Cluster("Private subnets (2 AZ)"):
                control = EKS("EKS control plane")

                with Cluster("Managed node group (2 x t3.medium, 1-3)"):
                    nodes = EC2AutoScaling("nodes")
                    lbc = Pod("AWS Load Balancer\nController")
                    eso = Pod("External Secrets\nOperator")
                    frontend = Deployment("frontend\nnginx + Nuxt build")
                    backend = Deployment("backend\nSpring Boot")
                    hpa = HPA("HPA 2-4")
                    k8s_secret = Secret("Secret\nDB password, JWT")

                db = RDSMysqlInstance("RDS MySQL 8\nTLS required")

    users >> Edge(label="HTTP :80") >> alb
    alb >> Edge(label="/") >> frontend
    alb >> Edge(label="/api/*") >> backend
    backend >> Edge(label="JDBC + TLS") >> db
    hpa >> Edge(style="dotted") >> backend
    lbc >> Edge(label="creates", style="dotted") >> alb
    secrets >> Edge(label="IRSA", style="dashed") >> eso
    eso >> Edge(style="dashed") >> k8s_secret >> Edge(style="dashed") >> backend
    irsa >> Edge(style="dotted") >> lbc
    ecr >> Edge(label="pull", style="dashed") >> nodes
    nodes >> Edge(style="dotted") >> nat
    control >> Edge(style="dotted") >> logs
