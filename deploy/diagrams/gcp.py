"""GCP deployment from deploy/terraform/gcp."""

from diagrams import Cluster, Diagram, Edge
from diagrams.gcp.compute import Run
from diagrams.gcp.database import SQL
from diagrams.gcp.devtools import ContainerRegistry
from diagrams.gcp.network import CDN, LoadBalancing
from diagrams.gcp.security import SecretManager
from diagrams.gcp.storage import GCS
from diagrams.onprem.client import Users

from common import diagram_kwargs

with Diagram(**diagram_kwargs("MM Events on Google Cloud (deploy/terraform/gcp)", "gcp")):
    users = Users("Browser")

    with Cluster("Global external Application Load Balancer"):
        lb = LoadBalancing("URL map\n/* site, /api/* API")
        cdn = CDN("Cloud CDN")

    with Cluster("Region (asia-southeast1)"):
        site = GCS("Cloud Storage\nstatic Nuxt build")
        registry = ContainerRegistry("Artifact Registry\nbackend image")
        secrets = SecretManager("Secret Manager\nDB password, JWT secret")
        api = Run("Cloud Run\nSpring Boot\n(ingress: LB only)")

        with Cluster("VPC (Private Service Access)"):
            db = SQL("Cloud SQL MySQL 8\nprivate IP, TLS")

    users >> Edge(label="HTTP / HTTPS\n(with a domain)") >> lb
    lb >> cdn >> Edge(label="backend bucket") >> site
    lb >> Edge(label="serverless NEG") >> api
    api >> Edge(label="Direct VPC egress\nJDBC + TLS") >> db
    registry >> Edge(label="pull", style="dashed") >> api
    secrets >> Edge(label="env from secrets", style="dashed") >> api
