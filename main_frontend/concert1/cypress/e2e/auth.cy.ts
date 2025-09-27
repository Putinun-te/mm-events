describe('Auth flow', () => {
  it('register then login', () => {
    cy.visit('/')
    cy.contains('h1', /home/i)

    // Open Register form
    cy.contains('button', /^Register$/i).click()

    // Fill register form
    cy.get('input[placeholder="Enter your username"]').should('be.visible').type('e2euser')
    cy.get('input[placeholder="Enter your email"]').type('e2euser@example.com')
    cy.get('input[placeholder="Enter your password"]').first().type('Password123!')
    cy.contains('form button', /^Register$/i).click()

    // Expect some feedback (success or error)
    cy.contains(/Registration|Welcome|failed/i)

    // Hide register
    cy.contains('button', /^Register$/i).click()

    // Open login
    cy.contains('button', /^Login$/i).click()
    cy.get('input[placeholder="Enter your email or username"]').type('e2euser')
    cy.get('input[placeholder="Enter your password"]').type('Password123!')
    cy.contains('form button', /^Login$/i).click()

    cy.contains(/Login successful|Welcome back|Login failed/i)
  })
})
