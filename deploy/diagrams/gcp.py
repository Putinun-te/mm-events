"""GCP deployment: deploy/terraform/gcp + deploy/helm/mm-events on GKE."""

from diagrams import Cluster, Diagram, Edge
from diagrams.gcp.compute import GKE, ComputeEngine
from diagrams.gcp.database import SQL
from diagrams.gcp.devtools import ContainerRegistry
from diagrams.gcp.network import NAT, LoadBalancing
from diagrams.gcp.security import Iam, SecretManager
from diagrams.k8s.clusterconfig import HPA
from diagrams.k8s.compute import Deployment, Pod
from diagrams.k8s.podconfig import Secret
from diagrams.onprem.client import Users

from common import diagram_kwargs

with Diagram(**diagram_kwargs("MM Events on Google Kubernetes Engine (deploy/terraform/gcp + deploy/helm)", "gcp")):
    users = Users("Browser")

    lb = LoadBalancing("External Application LB\nfrom the GKE Ingress\n(reserved static IP)")

    with Cluster("Project (asia-southeast1)"):
        registry = ContainerRegistry("Artifact Registry\nbackend + frontend images")
        secrets = SecretManager("Secret Manager\nDB password, JWT secret")
        wi = Iam("Workload Identity\nKSA -> Google SA")

        with Cluster("VPC (VPC-native subnet, Private Google Access)"):
            nat = NAT("Cloud NAT")

            with Cluster("GKE Standard, zonal, private nodes"):
                control = GKE("GKE control plane")

                with Cluster("Node pool (2 x e2-medium, 1-3)"):
                    nodes = ComputeEngine("nodes")
                    eso = Pod("External Secrets\nOperator")
                    frontend = Deployment("frontend\nnginx + Nuxt build")
                    backend = Deployment("backend\nSpring Boot")
                    hpa = HPA("HPA 2-4")
                    k8s_secret = Secret("Secret\nDB password, JWT")

            db = SQL("Cloud SQL MySQL 8\nprivate IP, TLS")

    users >> Edge(label="HTTP :80") >> lb
    lb >> Edge(label="/  (NEG)") >> frontend
    lb >> Edge(label="/api/*  (NEG)") >> backend
    backend >> Edge(label="JDBC + TLS\n(Private Service Access)") >> db
    hpa >> Edge(style="dotted") >> backend
    secrets >> Edge(label="Workload Identity", style="dashed") >> eso
    wi >> Edge(style="dotted") >> eso
    eso >> Edge(style="dashed") >> k8s_secret >> Edge(style="dashed") >> backend
    registry >> Edge(label="pull", style="dashed") >> nodes
    nodes >> Edge(style="dotted") >> nat
    control >> Edge(style="dotted") >> nodes
