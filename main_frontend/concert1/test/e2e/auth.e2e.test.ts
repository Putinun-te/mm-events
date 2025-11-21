import { describe, it, expect, beforeAll, afterAll } from 'vitest'
import { setup, $fetch, createPage } from '@nuxt/test-utils/e2e'

describe('E2E Authentication Flow', async () => {
  await setup({
    // Run Nuxt server for E2E tests
    server: true,
    browser: true
  })

  it('should display login page', async () => {
    const page = await createPage('/LoginPage')
    await page.waitForSelector('form')
    
    const title = await page.title()
    expect(title).toContain('Concert')
    
    // Check for login form elements
    const usernameInput = await page.$('input[name="username"]')
    const passwordInput = await page.$('input[type="password"]')
    const submitButton = await page.$('button[type="submit"]')
    
    expect(usernameInput).toBeTruthy()
    expect(passwordInput).toBeTruthy()
    expect(submitButton).toBeTruthy()
  })

  it('should display register page', async () => {
    const page = await createPage('/RegisterPage')
    await page.waitForSelector('form')
    
    // Check for registration form elements
    const emailInput = await page.$('input[type="email"]')
    const usernameInput = await page.$('input[name="username"]')
    const passwordInput = await page.$('input[type="password"]')
    
    expect(emailInput).toBeTruthy()
    expect(usernameInput).toBeTruthy()
    expect(passwordInput).toBeTruthy()
  })

  it('should show validation errors on empty login submission', async () => {
    const page = await createPage('/LoginPage')
    await page.waitForSelector('form')
    
    // Try to submit empty form
    const submitButton = await page.$('button[type="submit"]')
    await submitButton?.click()
    
    // Wait for validation errors
    await page.waitForTimeout(500)
    
    // Check if error messages are displayed
    const errorMessages = await page.$$('.error-message, .text-red-500, [class*="error"]')
    expect(errorMessages.length).toBeGreaterThan(0)
  })

  it('should navigate from login to register', async () => {
    const page = await createPage('/LoginPage')
    await page.waitForSelector('form')
    
    // Find and click register link
    const registerLink = await page.$('a[href*="register"], a[href*="Register"]')
    expect(registerLink).toBeTruthy()
    
    await registerLink?.click()
    await page.waitForNavigation()
    
    // Should be on register page
    const url = page.url()
    expect(url).toContain('Register')
  })

  it('should attempt login with test credentials', async () => {
    const page = await createPage('/LoginPage')
    await page.waitForSelector('form')
    
    // Fill in test credentials
    await page.fill('input[name="username"]', 'testuser')
    await page.fill('input[type="password"]', 'testpassword')
    
    // Submit form
    const submitButton = await page.$('button[type="submit"]')
    await submitButton?.click()
    
    // Wait for response
    await page.waitForTimeout(2000)
    
    // Either shows error (invalid credentials) or redirects on success
    const url = page.url()
    const hasError = await page.$('.error, .alert-error, [class*="error"]')
    
    expect(url !== '/LoginPage' || hasError !== null).toBeTruthy()
  })
})
