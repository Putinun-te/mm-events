describe('Booking Flow', () => {
  beforeEach(() => {
    cy.clearLocalStorage()
    cy.visit('/', { failOnStatusCode: false })
  })

  it('shows the home banner and navigation', () => {
    cy.contains('Start Shopping').should('exist')
    cy.get('nav').should('exist')
  })

  it('navigates to login page', () => {
    cy.visit('/LoginPage', { failOnStatusCode: false })
    cy.contains(/login|register/i).should('exist')
  })
})
