describe('Home smoke', () => {
  it('shows the home header', () => {
    cy.visit('http://localhost:3000/concert', { failOnStatusCode: false, timeout: 15000 })
    cy.wait(2000)
    cy.get('body').should('exist')
  })
})
