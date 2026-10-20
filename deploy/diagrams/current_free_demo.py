"""Current demo setup on free tiers: GitHub Pages (frontend), Render (backend), Aiven (MySQL)."""

from diagrams import Cluster, Diagram, Edge
from diagrams.onprem.ci import GithubActions
from diagrams.onprem.client import Users
from diagrams.onprem.database import Mysql
from diagrams.onprem.vcs import Github
from diagrams.programming.framework import Spring

from common import diagram_kwargs

with Diagram(**diagram_kwargs("MM Events - free demo (GitHub Pages + Render + Aiven)", "current-free-demo")):
    users = Users("Browser")

    with Cluster("GitHub"):
        repo = Github("mm-events repo")
        actions = GithubActions("deploy-pages.yml\nnuxt generate")
        pages = Github("GitHub Pages\n/mm-events/ (static SPA)")

    with Cluster("Render (free web service)"):
        api = Spring("mm-events-api\nmain_backend/Dockerfile\nprofile: cloud\nsleeps when idle")

    with Cluster("Aiven (free MySQL 8)"):
        db = Mysql("MySQL 8\nTLS required")

    repo >> Edge(label="push to main") >> actions >> Edge(label="upload") >> pages
    repo >> Edge(label="render.yaml\nbuild on push", style="dashed") >> api

    users >> Edge(label="HTTPS") >> pages
    users >> Edge(label="HTTPS /api/* (CORS)") >> api
    api >> Edge(label="JDBC over TLS") >> db
