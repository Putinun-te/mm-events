# MM Events frontend

Nuxt 4 single-page app (`ssr: false`); the source is in `app/`. It calls the
Spring Boot API directly at `NUXT_PUBLIC_BACKEND_BASE_URL`
(default `http://localhost:8080`).

```bash
npm ci --legacy-peer-deps
npm run dev            # http://localhost:3000
npm run test           # Vitest unit tests (test/unit)
npm run test:e2e       # API end-to-end tests against a running backend
npm run test:cy        # Cypress UI tests against the running stack
npx nuxt generate      # static build (set NUXT_APP_BASE_URL to serve it under a sub-path)
```

Requires Node 22. In code and tests `~/` means `app/`, as in Nuxt.
See the main [README](../../README.md) for the whole stack.
