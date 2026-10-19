"""Azure deployment: deploy/terraform/azure + deploy/helm/mm-events on AKS."""

from diagrams import Cluster, Diagram, Edge
from diagrams.azure.compute import VMScaleSets
from diagrams.azure.containers import ContainerRegistries, KubernetesServices
from diagrams.azure.databases import AzureDatabaseMysqlServer
from diagrams.azure.identity import ManagedIdentities
from diagrams.azure.monitor import LogAnalyticsWorkspaces
from diagrams.azure.networking import ApplicationGateways
from diagrams.azure.security import KeyVaults
from diagrams.k8s.clusterconfig import HPA
from diagrams.k8s.compute import Deployment, Pod
from diagrams.k8s.podconfig import Secret
from diagrams.onprem.client import Users

from common import diagram_kwargs

with Diagram(**diagram_kwargs("MM Events on Azure Kubernetes Service (deploy/terraform/azure + deploy/helm)", "azure")):
    users = Users("Browser")

    with Cluster("Resource group rg-mm-events (southeastasia)"):
        acr = ContainerRegistries("Container Registry\nbackend + frontend images")
        vault = KeyVaults("Key Vault (RBAC)\nDB password, JWT secret")
        identities = ManagedIdentities("Workload Identity\nbackend, ALB Controller")
        logs = LogAnalyticsWorkspaces("Log Analytics\nContainer Insights")

        with Cluster("VNet"):
            with Cluster("snet-agc (delegated)"):
                agc = ApplicationGateways("Application Gateway\nfor Containers")

            with Cluster("snet-aks: AKS (Free tier, Azure CNI)"):
                control = KubernetesServices("AKS control plane")

                with Cluster("System node pool (2 x Standard_B2s, 1-3)"):
                    nodes = VMScaleSets("VM scale set")
                    alb_ctrl = Pod("ALB Controller")
                    eso = Pod("External Secrets\nOperator")
                    frontend = Deployment("frontend\nnginx + Nuxt build")
                    backend = Deployment("backend\nSpring Boot")
                    hpa = HPA("HPA 2-4")
                    k8s_secret = Secret("Secret\nDB password, JWT")

            with Cluster("snet-mysql (delegated)"):
                db = AzureDatabaseMysqlServer("MySQL Flexible Server 8.0\nno public access")

    users >> Edge(label="HTTP :80") >> agc
    agc >> Edge(label="/") >> frontend
    agc >> Edge(label="/api/*") >> backend
    backend >> Edge(label="JDBC + TLS") >> db
    hpa >> Edge(style="dotted") >> backend
    alb_ctrl >> Edge(label="configures", style="dotted") >> agc
    vault >> Edge(label="Workload Identity", style="dashed") >> eso
    identities >> Edge(style="dotted") >> alb_ctrl
    eso >> Edge(style="dashed") >> k8s_secret >> Edge(style="dashed") >> backend
    acr >> Edge(label="pull (AcrPull)", style="dashed") >> nodes
    control >> Edge(style="dotted") >> logs
