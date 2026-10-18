describe('Sign up and log in', () => {
  it('registers through the form and is sent to the login page', () => {
    const id = `signup${Date.now()}`
    cy.visit('/RegisterPage')

    cy.get('#username').type(id)
    cy.get('#email').type(`${id}@example.com`)
    cy.get('#password').type('cypress-pass-123')
    cy.get('#terms').check()
    cy.get('button[type="submit"]').click()

    cy.location('pathname').should('include', '/LoginPage')
  })

  it('logs in through the form and shows the logged-in navigation', () => {
    cy.apiUser('login').then(user => {
      cy.visit('/LoginPage')
      cy.contains('a', 'Login/Register').should('be.visible')

      cy.get('#email').type(user.username)
      cy.get('#password').type(user.password)
      cy.get('button[type="submit"]').click()

      cy.location('pathname').should('not.include', '/LoginPage')
      cy.contains('a', 'Create Event').should('be.visible')
      cy.contains('a', 'Login/Register').should('not.exist')
      // Without "Remember me" the token only lives for this browser session
      cy.window().its('sessionStorage').invoke('getItem', 'jwt_token').should('be.a', 'string')
      cy.window().its('localStorage').invoke('getItem', 'jwt_token').should('be.null')
    })
  })

  it('keeps the token across browser sessions with "Remember me"', () => {
    cy.apiUser('remember').then(user => {
      cy.visit('/LoginPage')

      cy.get('#email').type(user.username)
      cy.get('#password').type(user.password)
      cy.get('#rememberMe').check()
      cy.get('button[type="submit"]').click()

      cy.contains('a', 'Create Event').should('be.visible')
      cy.window().its('localStorage').invoke('getItem', 'jwt_token').should('be.a', 'string')
    })
  })

  it('rejects a wrong password with the API message', () => {
    cy.apiUser('wrongpw').then(user => {
      cy.visit('/LoginPage')

      cy.get('#email').type(user.username)
      cy.get('#password').type('not-the-password')
      cy.get('button[type="submit"]').click()

      cy.contains('Invalid username/email or password!').should('be.visible')
      cy.location('pathname').should('include', '/LoginPage')
    })
  })
})
