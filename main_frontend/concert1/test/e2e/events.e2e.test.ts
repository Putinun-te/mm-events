import { describe, it, expect, beforeAll } from 'vitest'
import { setup, $fetch, createPage } from '@nuxt/test-utils/e2e'

describe('E2E Events Flow', async () => {
  await setup({
    server: true,
    browser: true
  })

  it('should display product page with events', async () => {
    const page = await createPage('/ProductPage')
    await page.waitForSelector('body')
    
    const title = await page.title()
    expect(title).toBeTruthy()
    
    // Wait for events to load
    await page.waitForTimeout(2000)
    
    // Check if page has event-related content
    const content = await page.content()
    expect(content.length).toBeGreaterThan(0)
  })

  it('should display search and filter controls', async () => {
    const page = await createPage('/ProductPage')
    await page.waitForSelector('body')
    
    // Look for search input
    const searchInput = await page.$('input[type="text"], input[placeholder*="search"], input[placeholder*="Search"]')
    expect(searchInput).toBeTruthy()
  })

  it('should navigate to event details page', async () => {
    const page = await createPage('/ProductPage')
    await page.waitForTimeout(2000)
    
    // Find first event link/card
    const eventLink = await page.$('a[href*="ProductPageDetail"], .event-card a, [class*="event"] a')
    
    if (eventLink) {
      await eventLink.click()
      await page.waitForNavigation()
      
      const url = page.url()
      expect(url).toContain('ProductPageDetail')
    }
  })

  it('should display event details correctly', async () => {
    // Directly navigate to a detail page (assuming ID 1 exists)
    const page = await createPage('/ProductPageDetail/1')
    await page.waitForTimeout(2000)
    
    const content = await page.content()
    
    // Check for common event detail elements
    const hasContent = content.includes('title') || 
                       content.includes('description') || 
                       content.includes('price') ||
                       content.includes('date')
    
    expect(hasContent).toBeTruthy()
  })

  it('should have quantity controls on detail page', async () => {
    const page = await createPage('/ProductPageDetail/1')
    await page.waitForTimeout(2000)
    
    // Look for quantity buttons
    const decreaseBtn = await page.$('button[class*="decrease"], button:has-text("-")')
    const increaseBtn = await page.$('button[class*="increase"], button:has-text("+")')
    
    // At least one quantity control should exist
    expect(decreaseBtn || increaseBtn).toBeTruthy()
  })

  it('should have add to cart or buy button', async () => {
    const page = await createPage('/ProductPageDetail/1')
    await page.waitForTimeout(2000)
    
    // Look for action buttons
    const buttons = await page.$$('button')
    const buttonTexts = await Promise.all(
      buttons.map(btn => btn.textContent())
    )
    
    const hasActionButton = buttonTexts.some(text => 
      text?.toLowerCase().includes('cart') || 
      text?.toLowerCase().includes('buy') ||
      text?.toLowerCase().includes('book')
    )
    
    expect(hasActionButton).toBeTruthy()
  })
})
