# Live demo: Railway (backend + MySQL) and GitHub Pages (frontend)

The demo runs the Spring Boot API and MySQL on [Railway](https://railway.com) and the
static Nuxt frontend on GitHub Pages:

```
Browser ──► https://<owner>.github.io/mm-events/      (GitHub Pages, static Nuxt build)
   │
   └─────► https://<backend>.up.railway.app/api/...   (Railway: Dockerfile in main_backend/)
                         │
                         └──► MySQL (Railway database, private network)
```

What is already in the repository:

| File | Purpose |
|---|---|
| `main_backend/railway.json` | Build with `main_backend/Dockerfile`, health check `/actuator/health`, restart on failure |
| `main_backend/src/main/resources/application-railway.properties` | `railway` profile: port from `$PORT`, MySQL and JWT secret from variables, health on the same port |
| `.github/workflows/deploy-pages.yml` | Builds the frontend with base path `/mm-events/` and the backend URL, publishes to GitHub Pages |

No secret is stored in the repository: the JWT secret and database password live only in
Railway's variables.

## 1. Backend on Railway

1. Sign in to Railway with your GitHub account and create a **New Project → Deploy from GitHub
   repo**, then pick `mm-events` (allow Railway's GitHub app to read the repository).
2. Open the new service → **Settings**:
   - **Root Directory**: `main_backend`
   - **Config file path** (Config-as-code): `/main_backend/railway.json`
3. In the project, add a database: **New → Database → Add MySQL**. Keep its name `MySQL`
   (the variable references below use that name).
4. Open the backend service → **Variables** and add:

   | Name | Value |
   |---|---|
   | `SPRING_PROFILES_ACTIVE` | `railway` |
   | `SPRING_DATASOURCE_URL` | `jdbc:mysql://${{MySQL.MYSQLHOST}}:${{MySQL.MYSQLPORT}}/${{MySQL.MYSQLDATABASE}}` |
   | `SPRING_DATASOURCE_USERNAME` | `${{MySQL.MYSQLUSER}}` |
   | `SPRING_DATASOURCE_PASSWORD` | `${{MySQL.MYSQLPASSWORD}}` |
   | `JWT_SECRET` | a random string of at least 64 characters, e.g. the output of `openssl rand -base64 64` |

   The `${{MySQL....}}` values are Railway reference variables; type them exactly like this.
5. **Settings → Networking → Generate Domain** to get a public URL such as
   `https://mm-events-backend.up.railway.app`.
6. After the deploy finishes, open `https://<your-domain>/actuator/health`; it should show
   `{"status":"UP"}`.

## 2. Frontend on GitHub Pages

1. Repository **Settings → Secrets and variables → Actions → Variables → New repository
   variable**: `BACKEND_BASE_URL` = your Railway URL from step 1.5, without a trailing slash.
2. **Settings → Pages → Build and deployment → Source: GitHub Actions**.
3. **Actions → deploy-pages → Run workflow** on `main`.
4. The site is published at `https://<owner>.github.io/mm-events/`.

From then on every merge to `main` that changes `main_frontend/concert1/` redeploys the
site. Until `BACKEND_BASE_URL` is set the workflow is skipped on pushes, and a manual run
stops with a message saying what is missing.

## Limits of the demo

- **Cost**: Railway gives new accounts trial credit; after that the backend and MySQL need a
  paid plan, otherwise the services stop. GitHub Pages is free for public repositories.
- **Empty database**: register an account on the site and create events to fill it.
- **Photo uploads**: event and avatar uploads use AWS S3, which is not configured, so they
  fail in the demo. Everything else (accounts, events, bookings, maps) works.
- **Maps**: venue search uses OpenStreetMap's free Nominatim service (about one search per
  second), which is fine for a demo.
- **CORS**: the API currently accepts requests from any origin. If it is later restricted,
  add `https://<owner>.github.io` to the allowed origins.

## Checked before publishing

The `railway` profile was run locally from the backend's Docker image with `PORT=9090`
against a MySQL 8.0 container: the health check reported `UP`, register, login, create
event and list events worked, requests without a token got 401, and a CORS preflight from
`https://putinun-te.github.io` was allowed. The Pages build was served under `/mm-events/`:
the event list, event detail page and venue map loaded from that backend.
