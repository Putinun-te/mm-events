describe('Event detail page', () => {
  const frontendBase = 'http://concert-dev-frontend-142fee22.s3-website-us-east-1.amazonaws.com'
  const eventId = 3
  const eventDetailUrl = `${frontendBase}/ProductPageDetail/${eventId}`
  const apiBase = 'https://t55pviree7.execute-api.us-east-1.amazonaws.com/prod'
  let eventDetailResponse: Cypress.Response<any>

  before(() => {
    return cy.request(`${apiBase}/api/events/${eventId}`).then((response) => {
      eventDetailResponse = response
    })
  })

  it('loads event detail from API Gateway', () => {
    expect(eventDetailResponse?.status).to.eq(200)
  })

  it('renders event detail page without toast errors', () => {
      const event = eventDetailResponse?.body
      expect(event, 'event detail body').to.exist

        cy.visit(eventDetailUrl, {
          failOnStatusCode: false,
          timeout: 30000,
          onBeforeLoad(win) {
            const originalFetch = win.fetch.bind(win)
            ;(win as any).__fetchLogs = []
            ;(win as any).__consoleErrors = []
            const originalConsoleError = win.console.error.bind(win.console)
            win.console.error = (...args: any[]) => {
              ;(win as any).__consoleErrors.push(args.map(a => (typeof a === 'object' ? JSON.stringify(a) : String(a))).join(' '))
              return originalConsoleError(...args)
            }
            win.fetch = ((input: RequestInfo | URL, init?: RequestInit) => {
              const url = typeof input === 'string' ? input : (input as Request).url
              ;(win as any).__fetchLogs.push({ url, startedAt: Date.now() })
              return originalFetch(input, init)
                .then((response: Response) => {
                  ;(win as any).__fetchLogs.push({ url, status: response.status })
                  return response
                })
                .catch(error => {
                  ;(win as any).__fetchLogs.push({ url, error: error?.message })
                  throw error
                })
            }) as typeof win.fetch
          }
        })

        cy.location('pathname', { timeout: 20000 }).should('eq', `/ProductPageDetail/${eventId}`)
        cy.location('pathname').then(path => cy.task('log', `PATHNAME: ${path}`))
        cy.url().then(url => cy.task('log', `URL: ${url}`))
        cy.get('body').should('not.contain', 'Failed to load event details')
        cy.get('body').invoke('text').then(text => {
          cy.task('log', `BODY SNIPPET: ${text?.slice(0, 400)}`)
        })
        cy.window().then((win) => {
          const logs = (win as any).__fetchLogs || []
          cy.task('log', `FETCH LOGS: ${JSON.stringify(logs, null, 2)}`)
          const consoleErrors = (win as any).__consoleErrors || []
          if (consoleErrors.length) {
            cy.task('log', `CONSOLE ERRORS: ${JSON.stringify(consoleErrors, null, 2)}`)
          }
        })
        cy.contains('Event not found').should('not.exist')
        cy.contains(event.title, { timeout: 20000 }).should('be.visible')
        cy.contains(event.description, { timeout: 20000 }).should('exist')
  })
})
