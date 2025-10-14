// Cypress E2E support file
// This file is processed and loaded automatically before test files

// Import commands.js
import './commands'

// Alternatively you can use CommonJS syntax:
// require('./commands')

// Global before hook
before(() => {
  cy.log('Starting Backend API E2E Tests')
})

// Global after hook
after(() => {
  cy.log('Completed Backend API E2E Tests')
})
