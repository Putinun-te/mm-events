import { test, expect, visitAs } from './fixtures'

test.describe('Booking tickets', () => {
  test('books a ticket, shows it in My Bookings and cancels it', async ({ page, api }) => {
    const organizer = await api.user('organizer')
    const title = `Playwright Booking ${Date.now()}${process.pid}`
    const eventId = await api.event(organizer, { title, ticketPrice: 30 })
    const fan = await api.user('fan')
    await visitAs(page, fan, `/product-page-detail/${eventId}`)

    await page.locator('button', { hasText: 'Book 1 Ticket' }).click()
    await expect(page.getByText('Booking Confirmed').first()).toBeVisible()

    await expect(page).toHaveURL(/\/MyBookingsPage/, { timeout: 15_000 })
    const card = page.locator('.booking-card', { hasText: title })
    await expect(card.getByText('CONFIRMED')).toBeVisible()
    await card.locator('button', { hasText: 'Cancel Booking' }).click()
    await page.locator('button', { hasText: 'Yes, Cancel Booking' }).click()

    await expect(card.getByText('CANCELLED')).toBeVisible()
  })

  test('cancels a booking after the access token expired without logging out', async ({ page, api }) => {
    const organizer = await api.user('organizer')
    const title = `Playwright Expired Cancel ${Date.now()}${process.pid}`
    const eventId = await api.event(organizer, { title })
    const fan = await api.user('idle')
    expect((await api.book(fan, eventId, 1)).status()).toBe(200)
    await visitAs(page, fan, '/MyBookingsPage')
    const card = page.locator('.booking-card', { hasText: title })
    await expect(card.getByText('CONFIRMED')).toBeVisible()

    // the user was idle for 15 minutes: the backend no longer accepts the access token
    await page.evaluate(() => localStorage.setItem('jwt_token', 'expired.access.token'))
    const cancelStatuses: number[] = []
    page.on('response', r => {
      if (r.request().method() === 'DELETE' && /\/api\/bookings\/[^/]+$/.test(new URL(r.url()).pathname)) {
        cancelStatuses.push(r.status())
      }
    })
    const refresh = page.waitForResponse(r => r.request().method() === 'POST' && r.url().includes('/api/auth/refresh'))

    await card.locator('button', { hasText: 'Cancel Booking' }).click()
    await page.locator('button', { hasText: 'Yes, Cancel Booking' }).click()

    expect((await refresh).status()).toBe(200)
    await expect.poll(() => cancelStatuses.length).toBeGreaterThanOrEqual(2)
    expect(cancelStatuses[0]).toBe(401)
    expect(cancelStatuses[1]).toBeGreaterThanOrEqual(200)
    expect(cancelStatuses[1]).toBeLessThanOrEqual(299)
    await expect(page.getByText('Booking Cancelled').first()).toBeVisible()
    await expect(card.getByText('CANCELLED')).toBeVisible()
    await expect(page).toHaveURL(/\/MyBookingsPage$/)
  })

  test('shows the server message when the last seats are taken first', async ({ page, api }) => {
    const organizer = await api.user('organizer')
    const eventId = await api.event(organizer, { personLimit: 2 })
    const late = await api.user('late')
    const early = await api.user('early')

    // The page still shows 2 free seats when it loads...
    await visitAs(page, late, `/product-page-detail/${eventId}`)
    const book = page.locator('button', { hasText: 'Book 1 Ticket' })
    await expect(book).toBeVisible()

    // ...then someone else books both of them.
    expect((await api.book(early, eventId, 2)).status()).toBe(200)

    await book.click()
    await expect(page.getByText('Booking Failed').first()).toBeVisible()
    await expect(page.getByText('This event is sold out').first()).toBeVisible()
    await expect(page).toHaveURL(new RegExp(`/product-page-detail/${eventId}`))
  })
})
