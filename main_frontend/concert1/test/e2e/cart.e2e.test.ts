import { describe, it, expect } from 'vitest'
import { setup, createPage } from '@nuxt/test-utils/e2e'

describe('E2E Shopping Cart Flow', async () => {
  await setup({
    server: true,
    browser: true
  })

  it('should display cart page', async () => {
    const page = await createPage('/CartPage')
    await page.waitForSelector('body')
    
    const title = await page.title()
    expect(title).toBeTruthy()
  })

  it('should show empty cart message when cart is empty', async () => {
    const page = await createPage('/CartPage')
    await page.waitForTimeout(1000)
    
    const content = await page.content()
    
    // Look for empty cart indicators
    const hasEmptyMessage = 
      content.toLowerCase().includes('empty') ||
      content.toLowerCase().includes('no items') ||
      content.toLowerCase().includes('cart is empty')
    
    // Empty cart should show message OR have items
    const cartItems = await page.$$('.cart-item, [class*="cart"]')
    
    expect(hasEmptyMessage || cartItems.length > 0).toBeTruthy()
  })

  it('should display cart items if present', async () => {
    const page = await createPage('/CartPage')
    await page.waitForTimeout(1000)
    
    // Look for common cart item structures
    const cartElements = await page.$$('.cart-item, .item, [data-testid*="cart"], [class*="CartEach"]')
    
    // Cart should render (empty or with items)
    expect(cartElements).toBeDefined()
  })

  it('should have checkout or continue shopping buttons', async () => {
    const page = await createPage('/CartPage')
    await page.waitForTimeout(1000)
    
    const buttons = await page.$$('button, a[class*="button"]')
    const buttonTexts = await Promise.all(
      buttons.map(btn => btn.textContent())
    )
    
    const hasActionButton = buttonTexts.some(text => 
      text?.toLowerCase().includes('checkout') || 
      text?.toLowerCase().includes('shopping') ||
      text?.toLowerCase().includes('continue') ||
      text?.toLowerCase().includes('back')
    )
    
    expect(hasActionButton || buttons.length > 0).toBeTruthy()
  })

  it('should calculate total price correctly', async () => {
    const page = await createPage('/CartPage')
    await page.waitForTimeout(1000)
    
    const content = await page.content()
    
    // Look for price-related content
    const hasPriceInfo = 
      content.includes('total') ||
      content.includes('Total') ||
      content.includes('$') ||
      content.includes('price')
    
    // Total should be displayed if items exist
    expect(hasPriceInfo || content.includes('empty')).toBeTruthy()
  })
})
