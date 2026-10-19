describe('Browsing events', () => {
  it('lists a new event and opens its detail page', () => {
    cy.apiUser('organizer').then(organizer => {
      const title = `Cypress Jazz ${Date.now()}`
      // Starts tomorrow, so it sorts before the far-future test events and is on the first page
      const start = new Date(Date.now() + 24 * 60 * 60 * 1000)
      const end = new Date(start.getTime() + 3 * 60 * 60 * 1000)
      const localDateTime = (date: Date) => date.toISOString().slice(0, 19)
      cy.apiEvent(organizer, { title, ticketPrice: 42, startDate: localDateTime(start), endDate: localDateTime(end) }).then(eventId => {
        cy.visit('/product-page')

        // the card's title sits in .text-center; "More" is in the same card
        cy.contains('h2', title).parent().parent().contains('button', 'More').click()

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
