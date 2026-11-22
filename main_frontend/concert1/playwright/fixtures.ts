import { test as base, expect, type APIRequestContext, type APIResponse, type Page } from '@playwright/test'

// API helpers so every test creates its own users and events (no shared state).

export const API_URL = process.env.PLAYWRIGHT_API_URL || 'http://localhost:8080'

export interface TestUser {
  username: string
  email: string
  password: string
  token?: string
  refreshToken?: string
}

let counter = 0

export class Api {
  constructor(private readonly request: APIRequestContext) {}

  /** Registers a fresh user through the API and returns it with an access and a refresh token. */
  async user(prefix = 'user'): Promise<TestUser> {
    counter += 1
    const id = `${prefix}${Date.now()}${process.pid}${counter}`
    const user: TestUser = { username: id, email: `${id}@example.com`, password: 'playwright-pass-123' }
    expect((await this.request.post(`${API_URL}/api/auth/register`, { data: user })).ok()).toBeTruthy()
    const login = await this.request.post(`${API_URL}/api/auth/login`, {
      data: { usernameOrEmail: user.username, password: user.password }
    })
    expect(login.ok()).toBeTruthy()
    const body = await login.json()
    return { ...user, token: body.token, refreshToken: body.refreshToken }
  }

  /** Creates an event as `user` through the API and returns its id. */
  async event(user: TestUser, overrides: Record<string, unknown> = {}): Promise<number> {
    const event = {
      title: `Playwright Live ${Date.now()}`,
      description: 'Created by a Playwright test',
      location: 'Siam Paragon',
      city: 'Bangkok',
      country: 'Thailand',
      startDate: '2099-05-01T19:00:00',
      endDate: '2099-05-01T22:00:00',
      ticketPrice: 25,
      personLimit: 50,
      ...overrides
    }
    const response = await this.request.post(`${API_URL}/api/events`, {
      headers: { Authorization: `Bearer ${user.token}` },
      data: event
    })
    expect(response.ok()).toBeTruthy()
    return (await response.json()).id as number
  }

  /** Books tickets as `user` through the API. */
  book(user: TestUser, eventId: number, quantity: number): Promise<APIResponse> {
    return this.request.post(`${API_URL}/api/bookings`, {
      headers: { Authorization: `Bearer ${user.token}` },
      data: { eventId: String(eventId), quantity }
    })
  }
}

/** Opens a page with `user` already logged in (the tokens are stored before the app loads, once). */
export async function visitAs(page: Page, user: TestUser, path: string) {
  await page.addInitScript(u => {
    if (sessionStorage.getItem('__pw_seeded')) return
    sessionStorage.setItem('__pw_seeded', '1')
    localStorage.setItem('jwt_token', u.token as string)
    if (u.refreshToken) localStorage.setItem('refresh_token', u.refreshToken)
    localStorage.setItem('profile_data', JSON.stringify({ username: u.username, email: u.email }))
  }, user)
  await page.goto(path)
}

export const test = base.extend<{ api: Api }>({
  api: async ({ request }, use) => {
    await use(new Api(request))
  }
})

export { expect }
