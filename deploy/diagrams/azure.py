"""Azure deployment from deploy/terraform/azure."""

from diagrams import Cluster, Diagram, Edge
from diagrams.azure.compute import ContainerApps
from diagrams.azure.containers import ContainerRegistries
from diagrams.azure.databases import AzureDatabaseMysqlServer
from diagrams.azure.identity import ManagedIdentities
from diagrams.azure.monitor import LogAnalyticsWorkspaces
from diagrams.azure.network import DNSPrivateZones
from diagrams.azure.security import KeyVaults
from diagrams.azure.web import StaticApps
from diagrams.onprem.client import Users

from common import diagram_kwargs

with Diagram(**diagram_kwargs("MM Events on Azure (deploy/terraform/azure)", "azure")):
    users = Users("Browser")

    site = StaticApps("Static Web Apps (Free)\nstatic Nuxt build")

    with Cluster("Resource group rg-mm-events (southeastasia)"):
        acr = ContainerRegistries("Container Registry\nbackend image")
        vault = KeyVaults("Key Vault (RBAC)\nDB password, JWT secret")
        identity = ManagedIdentities("User-assigned identity\nAcrPull + Secrets User")
        logs = LogAnalyticsWorkspaces("Log Analytics")

        with Cluster("VNet"):
            with Cluster("snet-apps (/23)"):
                api = ContainerApps("Container Apps\nSpring Boot :8080")
            with Cluster("snet-mysql (/24)"):
                db = AzureDatabaseMysqlServer("MySQL Flexible Server 8.0\nno public access")
            dns = DNSPrivateZones("Private DNS zone")

    users >> Edge(label="HTTPS") >> site
    users >> Edge(label="HTTPS /api/* (CORS)") >> api
    api >> Edge(label="JDBC + TLS") >> db
    dns >> Edge(style="dotted") >> db
    identity >> Edge(style="dashed") >> api
    acr >> Edge(label="pull", style="dashed") >> api
    vault >> Edge(label="secret refs", style="dashed") >> api
    api >> Edge(style="dotted") >> logs
