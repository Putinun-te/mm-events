import { defineConfig } from 'cypress'

const BASE_URL = process.env.CYPRESS_BASE_URL || 'http://localhost:3000/concert'

export default defineConfig({
  e2e: {
    baseUrl: BASE_URL,
    specPattern: 'cypress/e2e/**/*.cy.{js,jsx}',
    supportFile: 'cypress/support/e2e.js',
    video: false,
    screenshotOnRunFailure: true,
    defaultCommandTimeout: 8000,
    requestTimeout: 10000,
  },
})
