describe('Browsing events', () => {
  it('lists a new event and opens its detail page', () => {
    cy.apiUser('organizer').then(organizer => {
      const title = `Cypress Jazz ${Date.now()}`
      cy.apiEvent(organizer, { title, ticketPrice: 42 }).then(eventId => {
        cy.visit('/ProductPage')

        cy.contains(title).click()

        cy.location('pathname').should('eq', `/product-page-detail/${eventId}`)
        cy.contains('h1', title).should('be.visible')
        cy.contains('Siam Paragon').should('be.visible')
        cy.contains('$42').should('be.visible')
        cy.get('#map').should('exist')
      })
    })
  })

  it('shows "Event not found" for an unknown event id', () => {
    cy.visit('/product-page-detail/999999999')

    cy.contains('Event not found').should('be.visible')
  })
})
