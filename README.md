# MM Events – Concert Booking Platform

MM Events is a concert and event booking web application built as a team project
for **ITDS323 (DevOps)** at Mahidol University. Visitors browse upcoming concerts,
register and log in, book tickets and manage their bookings; organizers create,
edit and delete their own events with photos and a venue map.

The course focus was the delivery pipeline around the app: containerisation,
automated testing, CI/CD, Kubernetes and infrastructure as code on AWS.

> **Status:** the AWS infrastructure (EC2, RDS, ElastiCache, S3/CloudFront,
> Cognito, API Gateway, EKS) was used during the course and **has been
> decommissioned**. The Terraform and Kubernetes code is kept for reference and
> can be redeployed to your own account; nothing in this repository points at
> live resources.
>
> This repository is a cleaned copy of the team repository
> [MorningMores/develop](https://github.com/MorningMores/develop). Commit history
> and authorship are preserved; credentials, Terraform state, keys and build
> artifacts were removed from all history.

## Features

- Event catalogue with details, photos and a Longdo map of the venue
- Registration and login with JWT (Spring Security); optional AWS Cognito sign-in
- Create, edit and delete events; join/leave events
- Ticket bookings, booking cancellation and a "My bookings" page
- Profile and account settings with avatar upload (local disk or S3 presigned URLs)

## Tech stack

| Layer | Technologies |
|---|---|
| Frontend | Nuxt 4 (SPA), Vue 3, Tailwind CSS 4, Axios, AWS Amplify (Cognito) |
| Backend | Java 21, Spring Boot 3.5 (Web, Data JPA, Security, Validation, Actuator, Data Redis, Mail), JJWT, AWS SDK v2 (S3) |
| Data | MySQL 8, Redis 7 |
| Testing | JUnit 5, Spring Boot Test, Testcontainers, JaCoCo; Vitest, Vue Test Utils, Testing Library; Cypress |
| Containers | Docker (multi-stage images), Docker Compose |
| Orchestration | Kubernetes on Amazon EKS (Deployment, Service, HPA), Prometheus, Grafana, Actions Runner Controller |
| Infrastructure | Terraform: VPC, EC2, RDS, ElastiCache, S3, CloudFront, Cognito, API Gateway, Lambda, ECS Fargate, CloudWatch |
| CI/CD | GitHub Actions, Dependabot, gitleaks |

## Architecture

```mermaid
flowchart LR
  subgraph Dev["Developer"]
    code["Source code"]
  end

  subgraph GH["GitHub"]
    repo["Repository"]
    subgraph CI["GitHub Actions (ci.yml, GitHub-hosted runners)"]
      be_test["Backend tests<br/>JUnit + Testcontainers"]
      fe_test["Frontend tests + build<br/>Vitest / Nuxt"]
      e2e["API e2e tests<br/>on Docker Compose stack"]
      img["Docker image builds"]
      leaks["gitleaks history scan"]
    end
  end

  subgraph Local["Local: docker compose"]
    fe["frontend<br/>Nuxt dev :3000"]
    be["backend<br/>Spring Boot :8080"]
    db[("MySQL 8 :3306")]
    cache[("Redis 7 :6379")]
    fe -->|REST + JWT| be
    be --> db
    be --> cache
  end

  subgraph AWS["AWS (used during the course, decommissioned)"]
    subgraph TF["Terraform: aws/ and infra/terraform/"]
      cdn["S3 + CloudFront<br/>static frontend"]
      apigw["API Gateway"]
      compute["EC2 / ECS Fargate / Lambda"]
      rds[("RDS MySQL")]
      redis[("ElastiCache Redis")]
      cognito["Cognito"]
      s3img["S3 uploads"]
      cw["CloudWatch"]
    end
    subgraph K8S["Kubernetes: k8s/ on EKS"]
      dep["backend Deployment + HPA"]
      kredis["Redis"]
      mon["Prometheus + Grafana"]
      arc["Actions Runner Controller"]
    end
  end

  code -->|git push / PR| repo
  repo --> CI
  e2e -.->|same compose file| Local
  cdn --> apigw --> compute
  compute --> rds
  compute --> redis
  compute --> s3img
  cdn -.-> cognito
  dep --> rds
  dep --> kredis
  mon -.-> dep
```

## Repository layout

| Path | Contents |
|---|---|
| `main_backend/` | Spring Boot API (`src/main`), tests (`src/test`), Dockerfile |
| `main_frontend/concert1/` | Nuxt 4 app (`app/`), unit tests (`test/unit`), e2e tests (`test/e2e`), Cypress specs, Dockerfile + nginx config |
| `docker-compose.yml` | Local stack: MySQL, Redis, backend, frontend (and a `tests` profile for Dockerised backend tests) |
| `docker-compose.prod.yml` | Backend + frontend images against an external RDS database (reads `.env`) |
| `k8s/` | EKS manifests: backend Deployment/Service/HPA, Redis, Prometheus/Grafana, runner deployment |
| `aws/` | Terraform for the EC2-based deployment (VPC, EC2, RDS, ElastiCache, S3, Cognito, API Gateway, CloudWatch, IAM) |
| `infra/terraform/` | Terraform for the serverless (`serverless/`, `production/`) and ECS Fargate (`ecs-fargate/`) variants |
| `.github/workflows/ci.yml` | CI pipeline (see below) |
| `scripts/` | Optional helpers for a self-hosted runner on EC2 |
| `docs/` | Design notes, testing guides and course write-ups; `docs/archive/` holds old deployment notes |

## Run locally

Requirements: Docker with Docker Compose v2.

```bash
docker compose up -d --build
```

| Service | URL |
|---|---|
| Frontend | http://localhost:3000 |
| Backend API | http://localhost:8080 |
| Health check | http://localhost:8080/actuator/health |

The first start takes a few minutes: the backend image is built with Maven and
the frontend container runs `npm install`. No `.env` file is needed for local
use; all values in `docker-compose.yml` are local-only defaults. To show the
venue map, copy `.env.example` to `.env` and set `NUXT_PUBLIC_LONGDO_MAP_KEY`.

Stop everything and delete the database volume:

```bash
docker compose down -v
```

### Frontend without Docker

Start only the data stores and the API in Docker, then run Nuxt with hot reload:

```bash
docker compose up -d --build mysql redis backend
cd main_frontend/concert1
npm ci --legacy-peer-deps
npm run dev
```

## Tests

| What | Command | Notes |
|---|---|---|
| Backend unit + integration | `cd main_backend && mvn verify` | Needs Docker for Testcontainers. JaCoCo report in `target/site/jacoco/` |
| Backend in Docker | `docker compose --profile tests run --rm backend-tests` | No local JDK/Maven needed |
| Frontend unit | `cd main_frontend/concert1 && npm run test` | `npm run test:coverage` for coverage |
| API end-to-end | `docker compose up -d --build --wait`, then `cd main_frontend/concert1 && npm run test:e2e` | Runs against the local stack on :3000 / :8080 |
| Cypress UI tests | `cd main_frontend/concert1 && npm run test:cy:headless` | Needs the local stack running |

## CI/CD

`.github/workflows/ci.yml` runs on every push to `main` and on pull requests,
using GitHub-hosted runners only:

1. **backend** – `mvn verify` with Testcontainers and a JaCoCo report
2. **frontend** – `npm ci`, Vitest unit tests, `nuxt build`
3. **e2e** – starts the Docker Compose stack and runs the API e2e suite
4. **docker-images** – builds the backend and frontend images (not pushed)
5. **secret-scan** – gitleaks over the full git history (`.gitleaks.toml`)

During the course the pipeline also pushed images to GHCR and deployed to EKS
through self-hosted runners; those jobs needed AWS credentials and were removed
together with the infrastructure. Their history is in the git log and on the
`archive/*` branches.

## Deploying again (optional)

Everything below creates billable AWS resources in **your** account.

- **Terraform:** `cd aws` (or `infra/terraform/<variant>`), copy
  `terraform.tfvars.example` to `terraform.tfvars`, fill in your values, then
  `terraform init && terraform plan && terraform apply`. State and `*.tfvars`
  files are git-ignored.
- **Kubernetes:** replace the placeholder values in the `backend-secrets` Secret
  inside `k8s/backend-deployment.yaml` (or create the Secret with `kubectl create
  secret`), set your image, then `kubectl apply -f k8s/`.
- **Docker Compose on a VM:** copy `.env.example` to `.env`, fill in the
  production section and run `docker compose -f docker-compose.prod.yml up -d --build`.

## Branches

`main` holds the final state of the project. The `archive/*` branches keep
earlier lines of work (test branches, the Kubernetes and AWS experiments and
individual frontend branches) so that every team member's commits remain in the
history.

## My role

**Fullstack Developer and Tester** – Putinun ([@Putinun-te](https://github.com/Putinun-te)).
I worked on both the Spring Boot backend and the Nuxt frontend, and wrote and
maintained the backend and frontend test suites (JUnit with Testcontainers,
Vitest, API end-to-end tests). I also contributed to the project's Docker,
CI/CD, Kubernetes and Terraform setup.

## Credits

MM Events was built by the ITDS323 project team. The original repository, with
the full team and contributor history, is
[MorningMores/develop](https://github.com/MorningMores/develop).

## License

[MIT](LICENSE) – Copyright (c) 2025 PANAIYAKORN, PORAMEE, THANASON, PICHITCHAI,
PUTINUN, SUVEEWAT, KANTANAT.
