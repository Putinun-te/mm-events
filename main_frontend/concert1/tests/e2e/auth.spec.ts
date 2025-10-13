import { test, expect } from '@playwright/test';

// Simple auth flow smoke (adjust selectors if component structure changes)
// baseURL includes /concert so navigate with relative path (no leading /)

test.describe('Auth flow', () => {
  test('homepage loads successfully', async ({ page }) => {
    await page.goto('./');
    // Check for hero carousel title (Welcome to ShopHub or similar)
    await expect(page.locator('body')).toContainText(/Welcome to ShopHub|MM Concerts/i);
  });
  
  test('navigation bar is visible', async ({ page }) => {
    await page.goto('./');
    // Check for navbar brand
    await expect(page.locator('nav')).toContainText(/MM Concerts|Home|Events/i);
  });
});
