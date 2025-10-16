describe('Authentication Flow', () => {
  beforeEach(() => {
    cy.clearLocalStorage()
    cy.clearCookies()
    cy.visit('/', { failOnStatusCode: false })
  })

  it('can open registration and login pages', () => {
    cy.visit('/RegisterPage', { failOnStatusCode: false })
    cy.contains(/register/i).should('exist')

    cy.visit('/LoginPage', { failOnStatusCode: false })
    cy.contains(/login/i).should('exist')
  })
})
