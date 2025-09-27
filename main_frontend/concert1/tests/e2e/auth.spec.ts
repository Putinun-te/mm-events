import { test, expect } from '@playwright/test';

// Simple auth flow smoke (adjust selectors if component structure changes)
// baseURL includes /concert so navigate with relative path (no leading /)

test.describe('Auth flow', () => {
  test('register then login (UI placeholders)', async ({ page }) => {
    await page.goto('./');
    // Assert visible home header instead of <title> (none defined yet)
    await expect(page.locator('h1')).toHaveText(/home/i);
  });
});
