describe('Event detail page', () => {
  const frontendBase = 'http://concert-dev-frontend-142fee22.s3-website-us-east-1.amazonaws.com'
  const eventId = 3
  const eventDetailUrl = `${frontendBase}/ProductPageDetail/${eventId}`
  const apiBase = 'https://t55pviree7.execute-api.us-east-1.amazonaws.com/prod'

  it('loads event detail from API Gateway', () => {
    cy.request(`${apiBase}/api/events/${eventId}`).its('status').should('eq', 200)
  })

  it('renders event detail page without toast errors', () => {
    cy.intercept('GET', `${apiBase}/api/events/${eventId}`).as('eventDetail')
    cy.intercept('GET', `${apiBase}/api/events/json/${eventId}`, (req) => {
      req.on('response', (res) => {
        Cypress.log({ name: 'jsonFallback', message: `status ${res.statusCode}` })
      })
    }).as('jsonFallback')

    cy.visit(eventDetailUrl, { failOnStatusCode: false, timeout: 30000 })

    cy.wait('@eventDetail').its('response.statusCode').should('eq', 200)

    cy.get('h1', { timeout: 10000 }).should('contain.text', 'Event')

    cy.contains('Failed to load event details', { timeout: 2000 }).should('not.exist')
  })
})
