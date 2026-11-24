"""Overview for the top-level README: Docker Compose locally and the Helm chart in deploy/."""

from diagrams import Cluster, Diagram, Edge, Node
from diagrams.aws.compute import EKS
from diagrams.aws.database import RDSMysqlInstance
from diagrams.aws.security import SecretsManager
from diagrams.aws.storage import S3
from diagrams.k8s.clusterconfig import HPA
from diagrams.k8s.compute import Deployment, Pod
from diagrams.k8s.network import Ingress
from diagrams.onprem.client import Users
from diagrams.onprem.database import Mysql
from diagrams.onprem.network import Nginx
from diagrams.programming.framework import Spring, Vue

from common import diagram_kwargs

kwargs = diagram_kwargs("MM Events architecture", "overview")
kwargs["graph_attr"] = {**kwargs["graph_attr"], "ranksep": "1.3", "dpi": "200"}

with Diagram(**kwargs):
    browser = Users("Browser")
    osm = Node(
        "OpenStreetMap tiles\nLeaflet from unpkg",
        shape="box", style="rounded,dashed", fixedsize="false", labelloc="c", width="2", height="0.8",
    )
    s3 = S3("Amazon S3\nphoto and avatar uploads")

    with Cluster("Local: docker compose"):
        fe1 = Vue("frontend\nNuxt dev server :3000")
        be1 = Spring("backend\nSpring Boot :8080")
        db1 = Mysql("MySQL 8 :3306")
        be1 >> Edge(label="JPA, Flyway") >> db1

    with Cluster("deploy/: Helm chart on EKS, GKE or AKS (validated in CI, not applied)"):
        eks = EKS("Amazon EKS\n(or GKE / AKS)")
        ing = Ingress("Ingress")
        fe2 = Nginx("frontend\nnginx, static Nuxt build")
        be2 = Deployment("backend\nSpring Boot")
        hpa = HPA("HPA")
        eso = Pod("External Secrets\nOperator")
        db2 = RDSMysqlInstance("Managed MySQL 8\nRDS (or Cloud SQL /\nMySQL Flexible Server)")
        sm = SecretsManager("AWS Secrets Manager\n(or Key Vault /\nSecret Manager)")

        eks >> Edge(style="dotted", label="runs") >> ing
        ing >> Edge(label="everything else") >> fe2
        ing >> Edge(label="/api, /actuator/health,\n/swagger-ui, /v3/api-docs") >> be2
        be2 >> Edge(label="JDBC + TLS") >> db2
        hpa >> Edge(style="dotted") >> be2
        sm >> Edge(style="dashed", label="DB password,\nJWT secret") >> eso >> Edge(style="dashed") >> be2

    browser >> Edge(label="load SPA") >> fe1
    browser >> Edge(label="REST + Bearer JWT") >> be1
    browser >> Edge(label="same origin") >> ing
    browser >> Edge(style="dotted") >> osm
    be1 >> Edge(style="dashed", label="presigned URLs") >> s3
    be2 >> Edge(style="dashed", label="presigned URLs") >> s3
