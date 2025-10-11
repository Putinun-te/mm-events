describe('Auth page smoke', () => {
  it('loads login page', () => {
    cy.visit('/login')
    cy.contains(/login/i)
  })
})
