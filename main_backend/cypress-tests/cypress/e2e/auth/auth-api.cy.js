describe('Auth API E2E Tests', () => {
  const apiUrl = Cypress.env('apiUrl')
  const timestamp = Date.now()
  const testUser = {
    username: `testuser${timestamp}`,
    email: `test${timestamp}@example.com`,
    password: 'SecurePass123!',
    name: 'Test User'
  }

  describe('POST /api/auth/register', () => {
    it('should register a new user successfully', () => {
      cy.request({
        method: 'POST',
        url: `${apiUrl}/auth/register`,
        body: testUser
      }).then((response) => {
        expect(response.status).to.eq(200)
        expect(response.body).to.have.property('token')
        expect(response.body).to.have.property('username', testUser.username)
        expect(response.body).to.have.property('email', testUser.email)
        expect(response.body.token).to.be.a('string').and.not.be.empty
      })
    })

    it('should fail to register with duplicate username', () => {
      // Register first time
      cy.request({
        method: 'POST',
        url: `${apiUrl}/auth/register`,
        body: {
          username: `duplicate${timestamp}`,
          email: `unique${timestamp}@example.com`,
          password: 'password123',
          name: 'Duplicate Test'
        }
      }).then(() => {
        // Try to register again with same username
        cy.request({
          method: 'POST',
          url: `${apiUrl}/auth/register`,
          body: {
            username: `duplicate${timestamp}`,
            email: `different${timestamp}@example.com`,
            password: 'password123',
            name: 'Duplicate Test'
          },
          failOnStatusCode: false
        }).then((response) => {
          expect(response.status).to.be.oneOf([400, 409, 500])
        })
      })
    })

    it('should fail to register with invalid email', () => {
      cy.request({
        method: 'POST',
        url: `${apiUrl}/auth/register`,
        body: {
          username: `invalidmail${timestamp}`,
          email: 'invalid-email',
          password: 'password123',
          name: 'Invalid Email Test'
        },
        failOnStatusCode: false
      }).then((response) => {
        expect(response.status).to.be.oneOf([400, 422])
      })
    })
  })

  describe('POST /api/auth/login', () => {
    before(() => {
      // Register a user for login tests
      cy.request({
        method: 'POST',
        url: `${apiUrl}/auth/register`,
        body: {
          username: `loginuser${timestamp}`,
          email: `loginuser${timestamp}@example.com`,
          password: 'LoginPass123!',
          name: 'Login User'
        }
      })
    })

    it('should login successfully with valid credentials', () => {
      cy.request({
        method: 'POST',
        url: `${apiUrl}/auth/login`,
        body: {
          usernameOrEmail: `loginuser${timestamp}`,
          password: 'LoginPass123!'
        }
      }).then((response) => {
        expect(response.status).to.eq(200)
        expect(response.body).to.have.property('token')
        expect(response.body).to.have.property('username', `loginuser${timestamp}`)
        expect(response.body.token).to.be.a('string').and.not.be.empty
      })
    })

    it('should fail login with incorrect password', () => {
      cy.request({
        method: 'POST',
        url: `${apiUrl}/auth/login`,
        body: {
          usernameOrEmail: `loginuser${timestamp}`,
          password: 'WrongPassword123!'
        },
        failOnStatusCode: false
      }).then((response) => {
        expect(response.status).to.be.oneOf([401, 403])
      })
    })

    it('should fail login with non-existent user', () => {
      cy.request({
        method: 'POST',
        url: `${apiUrl}/auth/login`,
        body: {
          usernameOrEmail: 'nonexistentuser999999',
          password: 'password123'
        },
        failOnStatusCode: false
      }).then((response) => {
        expect(response.status).to.eq(401)
      })
    })
  })

  describe('GET /api/auth/test', () => {
    let authToken

    before(() => {
      // Register and login to get token
      cy.request({
        method: 'POST',
        url: `${apiUrl}/auth/register`,
        body: {
          username: `authtest${timestamp}`,
          email: `authtest${timestamp}@example.com`,
          password: 'AuthTest123!',
          name: 'Auth Test User'
        }
      }).then((response) => {
        authToken = response.body.token
      })
    })

    it('should access protected endpoint with valid token', () => {
      cy.request({
        method: 'GET',
        url: `${apiUrl}/auth/test`,
        headers: {
          Authorization: `Bearer ${authToken}`
        }
      }).then((response) => {
        expect(response.status).to.eq(200)
      })
    })

    it('should deny access without token', () => {
      cy.request({
        method: 'GET',
        url: `${apiUrl}/auth/test`,
        failOnStatusCode: false
      }).then((response) => {
        expect(response.status).to.be.oneOf([401, 403])
      })
    })

    it('should deny access with invalid token', () => {
      cy.request({
        method: 'GET',
        url: `${apiUrl}/auth/test`,
        headers: {
          Authorization: 'Bearer invalid.token.here'
        },
        failOnStatusCode: false
      }).then((response) => {
        expect(response.status).to.be.oneOf([401, 403])
      })
    })
  })
})
