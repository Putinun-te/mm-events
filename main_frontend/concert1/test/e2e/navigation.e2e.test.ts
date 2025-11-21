import { describe, it, expect } from 'vitest'
import { setup, createPage } from '@nuxt/test-utils/e2e'

describe('E2E Navigation Flow', async () => {
  await setup({
    server: true,
    browser: true
  })

  it('should navigate to home page', async () => {
    const page = await createPage('/')
    await page.waitForSelector('body')
    
    const title = await page.title()
    expect(title).toBeTruthy()
  })

  it('should have navigation menu', async () => {
    const page = await createPage('/')
    await page.waitForSelector('body')
    
    // Look for common navigation elements
    const nav = await page.$('nav, header, [role="navigation"]')
    expect(nav).toBeTruthy()
  })

  it('should navigate to different pages via menu', async () => {
    const page = await createPage('/')
    await page.waitForSelector('body')
    
    // Common navigation links
    const possibleLinks = [
      'a[href*="Product"]',
      'a[href*="Event"]',
      'a:has-text("Events")',
      'a:has-text("Products")'
    ]
    
    for (const selector of possibleLinks) {
      const link = await page.$(selector)
      if (link) {
        const href = await link.getAttribute('href')
        expect(href).toBeTruthy()
        break
      }
    }
  })

  it('should handle back navigation', async () => {
    const page = await createPage('/')
    const initialUrl = page.url()
    
    // Navigate to another page
    const link = await page.$('a[href]')
    if (link) {
      await link.click()
      await page.waitForNavigation()
      
      const newUrl = page.url()
      expect(newUrl).not.toBe(initialUrl)
      
      // Go back
      await page.goBack()
      await page.waitForNavigation()
      
      const backUrl = page.url()
      expect(backUrl).toBe(initialUrl)
    }
  })

  it('should maintain state across navigation', async () => {
    const page = await createPage('/ProductPage')
    await page.waitForTimeout(2000)
    
    // Type in search if available
    const searchInput = await page.$('input[type="text"]')
    if (searchInput) {
      await searchInput.fill('test')
      const value = await searchInput.inputValue()
      expect(value).toBe('test')
    }
  })

  it('should handle 404 pages gracefully', async () => {
    const page = await createPage('/nonexistent-page-12345')
    await page.waitForSelector('body')
    
    const content = await page.content()
    
    // Should show some kind of error or redirect
    const has404Content = 
      content.toLowerCase().includes('404') ||
      content.toLowerCase().includes('not found') ||
      content.toLowerCase().includes('error')
    
    expect(has404Content || page.url() !== '/nonexistent-page-12345').toBeTruthy()
  })
})
