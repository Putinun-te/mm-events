import { test, expect } from '@playwright/test';

// Auth flow E2E: register then login

test.describe('Auth flow', () => {
  test('register then login', async ({ page }) => {
    await page.goto('./');
    await expect(page.locator('h1')).toHaveText(/home/i);

    // Open Register form
    await page.getByRole('button', { name: /Register/i }).click();
    // Fill Register
    await page.getByPlaceholder('Enter your username').fill('e2euser');
    await page.getByPlaceholder('Enter your email').fill('e2euser@example.com');
    await page.getByPlaceholder('Enter your password').fill('Password123!');
    await page.getByRole('button', { name: /Register(ing)?\.\.\.|Register/i }).click();

    // Wait for success or failure message (non-empty)
    const registerMessage = page.locator('div >> text=/Registration|successful|failed/i');
    await registerMessage.first().waitFor({ timeout: 15000 });

    // Toggle off register component to avoid overlay
    await page.getByRole('button', { name: /Register/i }).click();

    // Open Login form
    await page.getByRole('button', { name: /^Login$/i }).click();
    await page.getByPlaceholder('Enter your email or username').fill('e2euser');
    await page.getByPlaceholder('Enter your password').fill('Password123!');
    await page.getByRole('button', { name: /Login(ging)?\.\.\.|Login/i }).click();

    const loginMessage = page.locator('div >> text=/Login successful|Login failed|Welcome back/i');
    await loginMessage.first().waitFor({ timeout: 15000 });

    await expect(loginMessage.first()).toContainText(/Login|Welcome|failed/i);
  });
});
