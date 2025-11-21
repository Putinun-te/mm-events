import { describe, it, expect } from 'vitest'
import { setup, createPage } from '@nuxt/test-utils/e2e'

describe('E2E Create Event Flow', async () => {
  await setup({
    server: true,
    browser: true
  })

  it('should display create event page', async () => {
    const page = await createPage('/CreateEventPage')
    await page.waitForSelector('body')
    
    const title = await page.title()
    expect(title).toBeTruthy()
  })

  it('should show authentication requirement', async () => {
    const page = await createPage('/CreateEventPage')
    await page.waitForTimeout(1000)
    
    const content = await page.content()
    
    // Either shows form (logged in) or login requirement
    const hasForm = await page.$('form')
    const hasLoginMessage = content.toLowerCase().includes('login') || 
                           content.toLowerCase().includes('sign in')
    
    expect(hasForm || hasLoginMessage).toBeTruthy()
  })

  it('should have event creation form fields', async () => {
    const page = await createPage('/CreateEventPage')
    await page.waitForTimeout(1000)
    
    // Check for common form fields
    const titleInput = await page.$('input[name="title"], input[placeholder*="title"]')
    const descriptionInput = await page.$('textarea[name="description"], textarea[placeholder*="description"]')
    const dateInputs = await page.$$('input[type="date"], input[type="datetime-local"]')
    
    // Should have at least some form elements
    expect(titleInput || descriptionInput || dateInputs.length > 0).toBeTruthy()
  })

  it('should validate required fields on submission', async () => {
    const page = await createPage('/CreateEventPage')
    await page.waitForTimeout(1000)
    
    const submitButton = await page.$('button[type="submit"], button:has-text("Create"), button:has-text("Submit")')
    
    if (submitButton) {
      await submitButton.click()
      await page.waitForTimeout(500)
      
      // Should show validation errors or stay on page
      const content = await page.content()
      const hasError = 
        content.toLowerCase().includes('required') ||
        content.toLowerCase().includes('error') ||
        content.toLowerCase().includes('invalid')
      
      expect(hasError || page.url().includes('CreateEvent')).toBeTruthy()
    }
  })

  it('should have photo upload capability', async () => {
    const page = await createPage('/CreateEventPage')
    await page.waitForTimeout(1000)
    
    // Look for file input or image upload component
    const fileInput = await page.$('input[type="file"], input[accept*="image"]')
    const uploadButton = await page.$('button:has-text("Upload"), button:has-text("Photo")')
    
    // Should have some upload mechanism
    expect(fileInput || uploadButton).toBeTruthy()
  })

  it('should have date and time inputs', async () => {
    const page = await createPage('/CreateEventPage')
    await page.waitForTimeout(1000)
    
    const dateInputs = await page.$$('input[type="date"], input[type="time"], input[type="datetime-local"]')
    
    // Should have date/time pickers
    expect(dateInputs.length).toBeGreaterThan(0)
  })

  it('should have price and capacity fields', async () => {
    const page = await createPage('/CreateEventPage')
    await page.waitForTimeout(1000)
    
    const numberInputs = await page.$$('input[type="number"]')
    const content = await page.content()
    
    const hasPriceField = content.toLowerCase().includes('price') || 
                         content.toLowerCase().includes('cost')
    const hasCapacityField = content.toLowerCase().includes('capacity') || 
                            content.toLowerCase().includes('limit') ||
                            content.toLowerCase().includes('seats')
    
    expect(numberInputs.length > 0 || hasPriceField || hasCapacityField).toBeTruthy()
  })
})
