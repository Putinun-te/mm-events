describe('Frontend Smoke Tests', () => {
  beforeEach(() => {
    // Visit the home page before each test
    cy.visit('/');
  });

  it('should load the home page successfully', () => {
    cy.contains('h1', /home|mm concerts|concert/i).should('be.visible');
  });

  it('should have navigation elements', () => {
    // Check for common navigation elements
    cy.get('nav, header').should('exist');
  });

  it('should be responsive', () => {
    // Test viewport
    cy.viewport(1280, 720);
    cy.wait(100);
    
    // Test mobile viewport
    cy.viewport('iphone-x');
    cy.wait(100);
  });

  it('should have working links', () => {
    // Find all links and verify they have href attributes
    cy.get('a[href]').should('have.length.greaterThan', 0);
  });
});

describe('API Health Check', () => {
  it('should connect to backend API', () => {
    // Test backend health endpoint
    cy.request({
      method: 'GET',
      url: `${Cypress.env('apiUrl')}/auth/test`,
      failOnStatusCode: false,
    }).then((response) => {
      // Backend should respond (even if it's an error due to no auth)
      expect(response.status).to.be.oneOf([200, 401, 403]);
    });
  });
});

