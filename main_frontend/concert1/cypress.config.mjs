import { defineConfig } from 'cypress'

// Runs against the Docker Compose stack: frontend on :3000, backend on :8080.
// Override with CYPRESS_BASE_URL / CYPRESS_API_URL.
export default defineConfig({
  e2e: {
    baseUrl: process.env.CYPRESS_BASE_URL || 'http://localhost:3000',
    specPattern: 'cypress/e2e/**/*.cy.{ts,js}',
    supportFile: 'cypress/support/e2e.ts',
    video: false,
    screenshotOnRunFailure: true,
    defaultCommandTimeout: 10000,
    // The Nuxt dev server compiles a page on first visit
    pageLoadTimeout: 120000,
    retries: { runMode: 1, openMode: 0 }
  },
  env: {
    apiUrl: process.env.CYPRESS_API_URL || 'http://localhost:8080'
  }
})
