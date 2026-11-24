import { test, expect, visitAs, API_URL } from './fixtures'

const link = (page: import('@playwright/test').Page, text: string) => page.locator('a', { hasText: text })
const storage = (page: import('@playwright/test').Page, area: 'localStorage' | 'sessionStorage', key: string) =>
  page.evaluate(([a, k]) => window[a as 'localStorage' | 'sessionStorage'].getItem(k), [area, key])

test.describe('Sign up and log in', () => {
  test('registers through the form and is sent to the login page', async ({ page }) => {
    const id = `signup${Date.now()}${process.pid}`
    await page.goto('/RegisterPage')

    await page.locator('#username').fill(id)
    await page.locator('#email').fill(`${id}@example.com`)
    await page.locator('#password').fill('playwright-pass-123')
    await page.locator('#terms').check()
    await page.locator('button[type="submit"]').click()

    await expect(page).toHaveURL(/\/LoginPage/)
  })

  test('logs in through the form and shows the logged-in navigation', async ({ page, api }) => {
    const user = await api.user('login')
    await page.goto('/LoginPage')
    await expect(link(page, 'Login/Register').first()).toBeVisible()

    await page.locator('#email').fill(user.username)
    await page.locator('#password').fill(user.password)
    await page.locator('button[type="submit"]').click()

    await expect(page).not.toHaveURL(/\/LoginPage/)
    await expect(link(page, 'Create Event').first()).toBeVisible()
    await expect(link(page, 'Login/Register')).toHaveCount(0)
    // Without "Remember me" the token only lives for this browser session
    await expect.poll(() => storage(page, 'sessionStorage', 'jwt_token')).toEqual(expect.any(String))
    expect(await storage(page, 'localStorage', 'jwt_token')).toBeNull()
  })

  test('keeps the token across browser sessions with "Remember me"', async ({ page, api }) => {
    const user = await api.user('remember')
    await page.goto('/LoginPage')

    await page.locator('#email').fill(user.username)
    await page.locator('#password').fill(user.password)
    await page.locator('#rememberMe').check()
    await page.locator('button[type="submit"]').click()

    await expect(link(page, 'Create Event').first()).toBeVisible()
    await expect.poll(() => storage(page, 'localStorage', 'jwt_token')).toEqual(expect.any(String))
  })

  test('rejects a wrong password with the API message', async ({ page, api }) => {
    const user = await api.user('wrongpw')
    await page.goto('/LoginPage')

    await page.locator('#email').fill(user.username)
    await page.locator('#password').fill('not-the-password')
    await page.locator('button[type="submit"]').click()

    await expect(page.getByText('Invalid username/email or password!').first()).toBeVisible()
    await expect(page).toHaveURL(/\/LoginPage/)
  })

  test('logging out ends the token on the server, not just in the browser', async ({ page, api, request }) => {
    const user = await api.user('logout')
    await visitAs(page, user, '/')
    await expect(link(page, 'Create Event').first()).toBeVisible()

    const logout = page.waitForResponse(r => r.request().method() === 'POST' && r.url().includes('/api/auth/logout'))
    await page.locator('nav li.relative > button').click()
    await page.locator('button', { hasText: 'Logout' }).first().click()
    await page.locator('button', { hasText: 'Yes, Logout' }).click()

    expect((await logout).status()).toBe(204)
    await expect(link(page, 'Login/Register').first()).toBeVisible()
    // a copy of the old token is refused from now on
    const me = await request.get(`${API_URL}/api/users/me`, { headers: { Authorization: `Bearer ${user.token}` } })
    expect(me.status()).toBe(401)
    // and so is the refresh token, so the session cannot be renewed
    const refresh = await request.post(`${API_URL}/api/auth/refresh`, { data: { refreshToken: user.refreshToken } })
    expect(refresh.status()).toBe(401)
  })

  test('renews an expired access token with the refresh token without logging out', async ({ page, api }) => {
    const user = await api.user('renew')
    const refresh = page.waitForResponse(r => r.request().method() === 'POST' && r.url().includes('/api/auth/refresh'))
    // a token the backend no longer accepts, as after 15 minutes
    await visitAs(page, { ...user, token: 'expired.access.token' }, '/MyBookingsPage')

    expect((await refresh).status()).toBe(200)
    await expect(page).toHaveURL(/\/MyBookingsPage$/)
    await expect(link(page, 'Create Event').first()).toBeVisible()
    await expect.poll(() => storage(page, 'localStorage', 'jwt_token')).not.toBe('expired.access.token')
    await expect.poll(() => storage(page, 'localStorage', 'refresh_token')).not.toBe(user.refreshToken)
  })

  test('locks the account for this browser after five wrong passwords', async ({ page, api }) => {
    const user = await api.user('lockout')
    await page.goto('/LoginPage')
    for (let attempt = 0; attempt < 5; attempt++) {
      await page.locator('#email').fill(user.username)
      await page.locator('#password').fill('not-the-password')
      await page.locator('button[type="submit"]').click()
      await expect(page.getByText('Invalid username/email or password!').first()).toBeVisible()
    }

    // even the right password is refused until the lockout ends
    await page.locator('#email').fill(user.username)
    await page.locator('#password').fill(user.password)
    await page.locator('button[type="submit"]').click()
    await expect(page.getByText('Too many failed login attempts').first()).toBeVisible()
    await expect(page).toHaveURL(/\/LoginPage/)
  })
})
