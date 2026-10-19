"""Current live-demo setup: GitHub Pages (frontend) + Railway (backend and MySQL)."""

from diagrams import Cluster, Diagram, Edge
from diagrams.onprem.ci import GithubActions
from diagrams.onprem.client import Users
from diagrams.onprem.database import Mysql
from diagrams.onprem.vcs import Github
from diagrams.programming.framework import Spring

from common import diagram_kwargs

with Diagram(**diagram_kwargs("MM Events - current demo (GitHub Pages + Railway)", "current-railway-pages")):
    users = Users("Browser")

    with Cluster("GitHub"):
        repo = Github("mm-events repo")
        actions = GithubActions("deploy-pages.yml\nnuxt generate")
        pages = Github("GitHub Pages\n/mm-events/ (static SPA)")

    with Cluster("Railway project"):
        api = Spring("Backend service\nmain_backend/Dockerfile\nprofile: railway")
        db = Mysql("MySQL 8\n(private network)")

    repo >> Edge(label="push to main") >> actions >> Edge(label="upload") >> pages
    repo >> Edge(label="build from Dockerfile", style="dashed") >> api

    users >> Edge(label="HTTPS") >> pages
    users >> Edge(label="HTTPS /api/* (CORS)") >> api
    api >> Edge(label="JDBC") >> db
