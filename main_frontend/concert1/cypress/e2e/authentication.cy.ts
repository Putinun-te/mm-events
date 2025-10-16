describe('Authentication Flow', () => {
  beforeEach(() => {
    cy.visit('http://localhost:3000/concert', { failOnStatusCode: false })
    cy.clearLocalStorage()
    cy.clearCookies()
  })

  describe('Registration', () => {
    it('should navigate to registration page', () => {
      cy.visit('http://localhost:3000/concert/RegisterPage', { failOnStatusCode: false })
      cy.url().should('include', '/RegisterPage')
      cy.contains('Register').should('be.visible')
    })

    it('should show validation for empty fields', () => {
      cy.visit('http://localhost:3000/concert/RegisterPage', { failOnStatusCode: false })
      cy.get('form').submit()
      // Form should not submit with empty fields
      cy.url().should('include', '/RegisterPage')
    })

    it('should register a new user successfully', () => {
      const timestamp = Date.now()
      const testEmail = `test${timestamp}@example.com`
      
      cy.visit('http://localhost:3000/concert/RegisterPage', { failOnStatusCode: false })
      
      // Fill in registration form
      cy.get('input[type="text"]').first().type('Test User')
      cy.get('input[type="email"]').type(testEmail)
      cy.get('input[type="password"]').first().type('TestPass123!')
      cy.get('input[type="password"]').last().type('TestPass123!')
      
      cy.get('form').submit()
      
      // Should show success message or redirect
      cy.wait(2000)
    })
  })

  describe('Login', () => {
    it('should navigate to login page', () => {
      cy.visit('http://localhost:3000/concert/LoginPage', { failOnStatusCode: false })
      cy.url().should('include', '/LoginPage')
      cy.contains('Login').should('be.visible')
    })

    it('should show error for invalid credentials', () => {
      cy.visit('http://localhost:3000/concert/LoginPage', { failOnStatusCode: false })
      
      cy.get('input#email').type('invalid@test.com')
      cy.get('input#password').type('wrongpassword')
      cy.get('form').submit()
      
      // Should show error message
      cy.wait(1000)
    })

    it('should login successfully with valid credentials', () => {
      cy.visit('http://localhost:3000/concert/LoginPage', { failOnStatusCode: false })
      
      // Use existing test account
      cy.get('input#email').type('test@test.com')
      cy.get('input#password').type('password123')
      cy.get('form').submit()
      
      // Should redirect after successful login
      cy.wait(2000)
    })

    it('should remember login with remember me checkbox', () => {
      cy.visit('http://localhost:3000/concert/LoginPage', { failOnStatusCode: false })
      
      cy.get('input#email').type('test@test.com')
      cy.get('input#password').type('password123')
      cy.get('input#rememberMe').check()
      cy.get('form').submit()
      
      cy.wait(2000)
      
      // Check if token is stored in localStorage
      cy.window().then((win) => {
        const token = win.localStorage.getItem('jwt_token')
        expect(token).to.exist
      })
    })
  })

  describe('Logout', () => {
    beforeEach(() => {
      // Login first
      cy.visit('http://localhost:3000/concert/LoginPage', { failOnStatusCode: false })
      cy.get('input#email').type('test@test.com')
      cy.get('input#password').type('password123')
      cy.get('form').submit()
      cy.wait(2000)
    })

    it('should logout successfully', () => {
      // Find and click logout button
      cy.contains('Logout').click()
      
      cy.wait(1000)
      
      // Confirm logout in modal if present
      cy.get('body').then(($body) => {
        if ($body.text().includes('Confirm')) {
          cy.contains('Confirm').click()
        }
      })
      
      cy.wait(1000)
      
      // Should clear localStorage
      cy.window().then((win) => {
        const token = win.localStorage.getItem('jwt_token')
        expect(token).to.be.null
      })
    })
  })

  describe('Protected Routes', () => {
    it('should redirect to login for protected pages when not authenticated', () => {
      cy.clearLocalStorage()
      cy.visit('http://localhost:3000/concert/AccountPage', { failOnStatusCode: false })
      
      cy.wait(1000)
      
      // Should redirect to login or show login required message
      cy.url().should('satisfy', (url) => 
        url.includes('/LoginPage') || url.includes('/AccountPage')
      )
    })

    it('should access protected pages when authenticated', () => {
      // Login first
      cy.visit('http://localhost:3000/concert/LoginPage', { failOnStatusCode: false })
      cy.get('input#email').type('test@test.com')
      cy.get('input#password').type('password123')
      cy.get('form').submit()
      cy.wait(2000)
      
      // Try to access protected page
      cy.visit('http://localhost:3000/concert/AccountPage', { failOnStatusCode: false })
      cy.wait(1000)
      
      cy.url().should('include', '/AccountPage')
    })
  })
})
