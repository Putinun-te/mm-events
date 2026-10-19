/// <reference types="cypress" />

// API helpers so every test creates its own users and events (no shared state).

export interface TestUser {
  username: string
  email: string
  password: string
  token?: string
  refreshToken?: string
}

declare global {
  namespace Cypress {
    interface Chainable {
      /** Registers a fresh user through the API and returns it with an access and a refresh token. */
      apiUser(prefix?: string): Chainable<TestUser>
      /** Creates an event as `user` through the API and returns its id. */
      apiEvent(user: TestUser, overrides?: Record<string, unknown>): Chainable<number>
      /** Books tickets as `user` through the API. */
      apiBook(user: TestUser, eventId: number, quantity: number): Chainable<Cypress.Response<any>>
      /** Visits a page with `user` already logged in. */
      visitAs(user: TestUser, path: string): Chainable<Cypress.AUTWindow>
    }
  }
}

let counter = 0
const api = (path: string) => `${Cypress.env('apiUrl')}${path}`

Cypress.Commands.add('apiUser', (prefix = 'user') => {
  counter += 1
  const id = `${prefix}${Date.now()}${counter}`
  const user: TestUser = { username: id, email: `${id}@example.com`, password: 'cypress-pass-123' }
  return cy.request('POST', api('/api/auth/register'), user)
    .then(() => cy.request('POST', api('/api/auth/login'), { usernameOrEmail: user.username, password: user.password }))
    .then(response => ({ ...user, token: response.body.token as string, refreshToken: response.body.refreshToken as string }))
})

Cypress.Commands.add('apiEvent', (user: TestUser, overrides = {}) => {
  const event = {
    title: `Cypress Live ${Date.now()}`,
    description: 'Created by a Cypress test',
    location: 'Siam Paragon',
    city: 'Bangkok',
    country: 'Thailand',
    startDate: '2099-05-01T19:00:00',
    endDate: '2099-05-01T22:00:00',
    ticketPrice: 25,
    personLimit: 50,
    ...overrides
  }
  return cy.request({
    method: 'POST',
    url: api('/api/events'),
    headers: { Authorization: `Bearer ${user.token}` },
    body: event
  }).then(response => response.body.id as number)
})

Cypress.Commands.add('apiBook', (user: TestUser, eventId: number, quantity: number) => {
  return cy.request({
    method: 'POST',
    url: api('/api/bookings'),
    headers: { Authorization: `Bearer ${user.token}` },
    body: { eventId: String(eventId), quantity },
    failOnStatusCode: false
  })
})

Cypress.Commands.add('visitAs', (user: TestUser, path: string) => {
  return cy.visit(path, {
    onBeforeLoad(win) {
      win.localStorage.setItem('jwt_token', user.token as string)
      if (user.refreshToken) win.localStorage.setItem('refresh_token', user.refreshToken)
      win.localStorage.setItem('profile_data', JSON.stringify({ username: user.username, email: user.email }))
    }
  })
})

export {}
