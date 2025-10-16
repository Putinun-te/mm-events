describe('Home smoke', () => {
  it('shows the home header', () => {
    cy.visit('/', { failOnStatusCode: false })
    cy.contains('h1', /home|mm concerts/i).should('be.visible')
  })
})
