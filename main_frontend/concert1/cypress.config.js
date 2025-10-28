module.exports = {
  projectId: "vuxbeo",
  e2e: {
    baseUrl: 'http://localhost:3000/concert/',
    specPattern: 'cypress/e2e/**/*.cy.{js,jsx,ts,tsx}',
    supportFile: 'cypress/support/e2e.ts',
  },
}