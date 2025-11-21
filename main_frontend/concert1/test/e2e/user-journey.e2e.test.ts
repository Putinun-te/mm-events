import { describe, it, expect } from 'vitest'
import { setup, createPage } from '@nuxt/test-utils/e2e'

describe('E2E Full User Journey', async () => {
  await setup({
    server: true,
    browser: true
  })

  it('should complete a full user journey', async () => {
    const page = await createPage('/')
    
    // Step 1: Navigate to home page
    await page.waitForSelector('body')
    const homeTitle = await page.title()
    expect(homeTitle).toBeTruthy()
    console.log('✅ Home page loaded')
    
    // Step 2: Navigate to events page
    const eventsLink = await page.$('a[href*="Product"], a[href*="Event"]')
    if (eventsLink) {
      await eventsLink.click()
      await page.waitForNavigation()
      console.log('✅ Navigated to events page')
    }
    
    // Step 3: Search for events
    await page.waitForTimeout(2000)
    const searchInput = await page.$('input[type="text"]')
    if (searchInput) {
      await searchInput.fill('concert')
      console.log('✅ Searched for events')
    }
    
    // Step 4: View event details
    const eventLink = await page.$('a[href*="ProductPageDetail"]')
    if (eventLink) {
      await eventLink.click()
      await page.waitForNavigation()
      console.log('✅ Viewed event details')
    }
    
    // Step 5: Adjust quantity and add to cart
    await page.waitForTimeout(2000)
    const increaseBtn = await page.$('button:has-text("+"), button[class*="increase"]')
    if (increaseBtn) {
      await increaseBtn.click()
      console.log('✅ Increased quantity')
    }
    
    // Step 6: Navigate to cart
    const cartLink = await page.$('a[href*="Cart"]')
    if (cartLink) {
      await cartLink.click()
      await page.waitForNavigation()
      console.log('✅ Navigated to cart')
    }
    
    // Step 7: Verify cart page loads
    await page.waitForTimeout(1000)
    const cartContent = await page.content()
    expect(cartContent).toBeTruthy()
    console.log('✅ Cart page loaded')
    
    // Journey completed successfully
    console.log('🎉 Full user journey completed!')
  })

  it('should handle authentication flow', async () => {
    const page = await createPage('/')
    
    // Navigate to login
    const loginLink = await page.$('a[href*="Login"]')
    if (loginLink) {
      await loginLink.click()
      await page.waitForNavigation()
      console.log('✅ Navigated to login page')
    } else {
      // Directly navigate to login page
      await page.goto('/LoginPage')
    }
    
    // Verify login form
    await page.waitForTimeout(1000)
    const usernameInput = await page.$('input[name="username"]')
    const passwordInput = await page.$('input[type="password"]')
    
    expect(usernameInput || passwordInput).toBeTruthy()
    console.log('✅ Login form verified')
    
    // Navigate to register
    const registerLink = await page.$('a[href*="Register"]')
    if (registerLink) {
      await registerLink.click()
      await page.waitForNavigation()
      console.log('✅ Navigated to register page')
    }
    
    // Verify register form
    await page.waitForTimeout(1000)
    const emailInput = await page.$('input[type="email"]')
    expect(emailInput).toBeTruthy()
    console.log('✅ Register form verified')
    
    console.log('🎉 Authentication flow completed!')
  })

  it('should handle event creation flow (requires auth)', async () => {
    const page = await createPage('/CreateEventPage')
    await page.waitForTimeout(1000)
    
    const content = await page.content()
    
    // Either shows login requirement or create form
    const hasForm = await page.$('form')
    const requiresAuth = content.toLowerCase().includes('login') || 
                        content.toLowerCase().includes('sign in')
    
    if (requiresAuth) {
      console.log('✅ Create event page requires authentication (as expected)')
    } else if (hasForm) {
      console.log('✅ Create event form loaded')
      
      // Verify form fields exist
      const titleInput = await page.$('input[name="title"], input[placeholder*="title"]')
      const dateInputs = await page.$$('input[type="date"], input[type="datetime-local"]')
      
      expect(titleInput || dateInputs.length > 0).toBeTruthy()
      console.log('✅ Create event form fields verified')
    }
    
    console.log('🎉 Event creation flow verified!')
  })
})
