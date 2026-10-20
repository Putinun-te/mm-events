# Free demo: GitHub Pages + Render + Aiven

The demo runs on three free tiers, with no time limit (check each provider's current terms;
free plans change):

| Part | Where | Free plan limits |
|---|---|---|
| Frontend (static Nuxt build) | GitHub Pages, `https://putinun-te.github.io/mm-events/` | free for public repositories |
| Backend (Spring Boot API) | Render free web service, built from `main_backend/Dockerfile` | 512 MB RAM, sleeps after ~15 minutes without requests; the first request after that takes about a minute while it starts |
| Database (MySQL 8) | Aiven free MySQL plan | 1 GB storage, a few connections; TLS required |

![Free demo architecture](../deploy/diagrams/current-free-demo.png)

What the repository already contains:

| File | Purpose |
|---|---|
| `render.yaml` | Render Blueprint: Docker service from `main_backend/`, health check `/actuator/health`, `cloud` profile, JVM sized for 512 MB, CORS for the Pages site; asks for the database and JWT values |
| `main_backend/src/main/resources/application-cloud.properties` | `cloud` profile: port from `$PORT`, datasource and JWT secret from the environment (no defaults), pool of 3 connections, health on the same port |
| `.github/workflows/deploy-pages.yml` | Builds the frontend with `nuxt generate` for `/mm-events/` and publishes it to Pages |
| `main_backend/src/main/resources/db/migration/` | Flyway creates the tables on the first start |

Nothing secret is stored in the repository; the values below are entered once in the
providers' dashboards.

## 1. Database on Aiven

1. Sign up at [aiven.io](https://aiven.io) and create a service: **MySQL**, plan **Free**,
   in a region close to Render's (the blueprint uses Singapore).
2. When it is running, open **Overview → Connection information** and note host, port,
   user (`avnadmin`), password and database (`defaultdb`).
3. The JDBC URL for the next step is
   `jdbc:mysql://<host>:<port>/defaultdb?sslMode=REQUIRED`.

## 2. Backend on Render

1. Sign up at [render.com](https://render.com) with your GitHub account.
2. **New → Blueprint**, pick the `mm-events` repository. Render reads `render.yaml` and
   asks for the values marked `sync: false`:

   | Name | Value |
   |---|---|
   | `SPRING_DATASOURCE_URL` | the JDBC URL from step 1.3 |
   | `SPRING_DATASOURCE_USERNAME` | `avnadmin` |
   | `SPRING_DATASOURCE_PASSWORD` | the Aiven password |
   | `JWT_SECRET` | at least 64 random characters, e.g. the output of `openssl rand -base64 64` |

3. **Apply**. The first build takes several minutes (Maven inside Docker). The service URL
   looks like `https://mm-events-api.onrender.com`.
4. Open `https://<service>.onrender.com/actuator/health`; it should show `{"status":"UP"}`.
   The API docs are at `/swagger-ui.html`. On the first start Flyway creates the tables.

Every push to `main` that changes `main_backend/` redeploys the backend.

## 3. Frontend on GitHub Pages

1. Repository **Settings → Secrets and variables → Actions → Variables → New repository
   variable**: `BACKEND_BASE_URL` = the Render URL from step 2.3, without a trailing slash.
2. **Settings → Pages → Build and deployment → Source: GitHub Actions**.
3. **Actions → deploy-pages → Run workflow** on `main`.
4. The site is at `https://putinun-te.github.io/mm-events/`.

From then on every merge to `main` that changes `main_frontend/concert1/` redeploys the
site. Until `BACKEND_BASE_URL` is set the workflow is skipped on pushes, and a manual run
stops with a message saying what is missing.

## Limits of the demo

- **Cold start**: after ~15 idle minutes Render stops the backend; the next request wakes it
  and takes about a minute, so the first page load may show "Failed to load events" until
  it is up. Reload after a minute.
- **Empty database**: register an account on the site and create events to fill it.
- **Photo uploads**: event and avatar uploads use AWS S3, which is not configured, so they
  fail in the demo. Everything else (accounts, events, bookings, maps) works.
- **Login rate limit**: counted in memory, so it resets when the backend restarts. Revoked
  tokens and refresh tokens are in MySQL and survive restarts.
- **CORS**: the API only accepts browser requests from `APP_CORS_ALLOWED_ORIGINS`
  (`https://putinun-te.github.io` in `render.yaml`). A fork published under another
  account must change it to its own `https://<owner>.github.io`.
- **Free plans change**: any host that runs a Docker image with the environment variables
  above works the same way; the `cloud` profile is not tied to Render.

## Checked before publishing

The backend image was run locally the way Render runs it: `cloud` profile, `PORT=10000`,
the `JAVA_OPTS` from `render.yaml` and a 512 MB memory limit, against MySQL 8 with
`sslMode=REQUIRED`. Flyway applied all migrations, the health check reported `UP`,
register, login (access + refresh token) and the event list worked, the database
connections used TLS 1.3, a CORS preflight from `https://putinun-te.github.io` was allowed,
and memory stayed at about 390 MB of the 512 MB limit.
