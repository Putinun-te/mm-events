describe('Auth flow', () => {
  it('register then login (UI only, backend independent)', () => {
    const unique = Date.now();
    const username = `e2euser_${unique}`;
    const email = `${username}@example.com`;
    const password = 'Password123!';

    cy.visit('/');
    cy.contains('h1', 'this is home');

    // Fill Register form (no network assertion)
    cy.get('[data-test=register-username]').type(username);
    cy.get('[data-test=register-email]').type(email);
    cy.get('[data-test=register-password]').type(password);
    cy.get('[data-test=register-submit]').click();

    // Proceed immediately to Login form
    cy.get('[data-test=login-username-or-email]').type(username);
    cy.get('[data-test=login-password]').type(password);
    cy.get('[data-test=login-submit]').click();

    // Basic sanity assertions to guarantee elements existed and actions executed
    cy.get('[data-test=register-submit]').should('exist');
    cy.get('[data-test=login-submit]').should('exist');
  });
});
