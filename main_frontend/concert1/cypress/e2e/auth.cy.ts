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

  it('logging out ends the token on the server, not just in the browser', () => {
    cy.apiUser('logout').then(user => {
      cy.visitAs(user, '/')
      cy.contains('a', 'Create Event').should('be.visible')

      cy.intercept('POST', '**/api/auth/logout').as('logout')
      cy.get('nav li.relative > button').click()
      cy.contains('button', 'Logout').click()
      cy.contains('button', 'Yes, Logout').click()

      cy.wait('@logout').its('response.statusCode').should('eq', 204)
      cy.contains('a', 'Login/Register').should('be.visible')
      // a copy of the old token is refused from now on
      cy.request({
        url: `${Cypress.env('apiUrl')}/api/users/me`,
        headers: { Authorization: `Bearer ${user.token}` },
        failOnStatusCode: false
      }).its('status').should('eq', 401)
      // and so is the refresh token, so the session cannot be renewed
      cy.request({
        method: 'POST',
        url: `${Cypress.env('apiUrl')}/api/auth/refresh`,
        body: { refreshToken: user.refreshToken },
        failOnStatusCode: false
      }).its('status').should('eq', 401)
    })
  })

  it('renews an expired access token with the refresh token without logging out', () => {
    cy.apiUser('renew').then(user => {
      cy.intercept('POST', '**/api/auth/refresh').as('refresh')
      // a token the backend no longer accepts, as after 15 minutes
      cy.visitAs({ ...user, token: 'expired.access.token' }, '/MyBookingsPage')

      cy.wait('@refresh').its('response.statusCode').should('eq', 200)
      cy.location('pathname').should('eq', '/MyBookingsPage')
      cy.contains('a', 'Create Event').should('be.visible')
      cy.window().its('localStorage').invoke('getItem', 'jwt_token').should('not.eq', 'expired.access.token')
      cy.window().its('localStorage').invoke('getItem', 'refresh_token').should('not.eq', user.refreshToken)
    })
  })

  it('locks the account for this browser after five wrong passwords', () => {
    cy.apiUser('lockout').then(user => {
      cy.visit('/LoginPage')
      for (let attempt = 0; attempt < 5; attempt++) {
        cy.get('#email').clear().type(user.username)
        cy.get('#password').clear().type('not-the-password')
        cy.get('button[type="submit"]').click()
        cy.contains('Invalid username/email or password!').should('be.visible')
      }

      // even the right password is refused until the lockout ends
      cy.get('#email').clear().type(user.username)
      cy.get('#password').clear().type(user.password)
      cy.get('button[type="submit"]').click()
      cy.contains('Too many failed login attempts').should('be.visible')
      cy.location('pathname').should('include', '/LoginPage')
    })
  })
})
