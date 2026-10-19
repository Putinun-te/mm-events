"""AWS deployment from deploy/terraform/aws."""

from diagrams import Cluster, Diagram, Edge
from diagrams.aws.compute import ECR, Fargate
from diagrams.aws.database import RDSMysqlInstance
from diagrams.aws.management import CloudwatchLogs
from diagrams.aws.network import ALB, CloudFront
from diagrams.aws.security import SecretsManager
from diagrams.aws.storage import SimpleStorageServiceS3
from diagrams.onprem.client import Users

from common import diagram_kwargs

with Diagram(**diagram_kwargs("MM Events on AWS (deploy/terraform/aws)", "aws")):
    users = Users("Browser")

    cdn = CloudFront("CloudFront\n/* site, /api/* API")

    with Cluster("AWS region (ap-southeast-1)"):
        site = SimpleStorageServiceS3("S3 bucket\nstatic Nuxt build\n(private, OAC)")
        ecr = ECR("ECR\nbackend image")
        secrets = SecretsManager("Secrets Manager\nDB password, JWT secret")
        logs = CloudwatchLogs("CloudWatch Logs")

        with Cluster("VPC"):
            with Cluster("Public subnets (2 AZ)"):
                alb = ALB("ALB\nCloudFront-only SG")
                api = Fargate("ECS Fargate\nSpring Boot :8080")
            with Cluster("Private subnets (2 AZ)"):
                db = RDSMysqlInstance("RDS MySQL 8\nTLS required")

    users >> Edge(label="HTTPS") >> cdn
    cdn >> Edge(label="static files") >> site
    cdn >> Edge(label="/api/*") >> alb >> api
    api >> Edge(label="JDBC + TLS") >> db
    ecr >> Edge(label="pull", style="dashed") >> api
    secrets >> Edge(label="inject at start", style="dashed") >> api
    api >> Edge(style="dotted") >> logs
