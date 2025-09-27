import { defineConfig } from 'cypress';

export default defineConfig({
  e2e: {
    baseUrl: 'http://localhost:3000/concert',
    supportFile: false,
    video: false,
    defaultCommandTimeout: 10000,
    specPattern: 'cypress/e2e/**/*.cy.{js,jsx}' // TS specs removed
  },
});
