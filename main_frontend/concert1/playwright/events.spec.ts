import { test, expect } from './fixtures'

test.describe('Browsing events', () => {
  test('lists a new event and opens its detail page', async ({ page, api }) => {
    const organizer = await api.user('organizer')
    const title = `Playwright Jazz ${Date.now()}${process.pid}`
    // Starts tomorrow, so it sorts before the far-future test events and is on the first page
    const start = new Date(Date.now() + 24 * 60 * 60 * 1000)
    const end = new Date(start.getTime() + 3 * 60 * 60 * 1000)
    const localDateTime = (date: Date) => date.toISOString().slice(0, 19)
    const eventId = await api.event(organizer, {
      title, ticketPrice: 42, startDate: localDateTime(start), endDate: localDateTime(end)
    })
    await page.goto('/product-page')

    // the card's title sits in .text-center; "More" is in the same card
    await page.locator('h2', { hasText: title }).locator('xpath=../..').locator('button', { hasText: 'More' }).click()

    await expect(page).toHaveURL(new RegExp(`/product-page-detail/${eventId}$`))
    await expect(page.locator('h1', { hasText: title })).toBeVisible()
    await expect(page.getByText('Siam Paragon').first()).toBeVisible()
    await expect(page.getByText('$42').first()).toBeVisible()
    await expect(page.locator('#map')).toBeAttached()
  })

  test('shows "Event not found" for an unknown event id', async ({ page }) => {
    await page.goto('/product-page-detail/999999999')

    await expect(page.getByText('Event not found').first()).toBeVisible()
  })
})
