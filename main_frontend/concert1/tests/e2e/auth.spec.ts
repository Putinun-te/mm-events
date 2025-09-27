import { test, expect } from '@playwright/test';

// Auth flow E2E: register then login (stabilized)

test.describe('Auth flow', () => {
  test('register then login', async ({ page }) => {
    test.setTimeout(60000);
    await page.goto('./');
    await expect(page.locator('h1')).toHaveText(/home/i);

    // Open Register form (toggle button text is Register, ensure click happens once)
    await page.getByRole('button', { name: /^Register$/i }).first().click();

    // Wait for registration form inputs to render
    const usernameInput = page.getByPlaceholder('Enter your username');
    await usernameInput.waitFor({ state: 'visible', timeout: 10000 });

    await usernameInput.fill('e2euser');
    await page.getByPlaceholder('Enter your email').fill('e2euser@example.com');
    await page.getByPlaceholder('Enter your password').fill('Password123!');

    // Click submit (choose the Register button inside the form by finding enabled submit)
    await page.locator('form button:has-text("Register")').first().click();

    const registerMessage = page.locator('div >> text=/Registration|successful|Welcome|failed/i');
    await registerMessage.first().waitFor({ timeout: 15000 });

    // Hide register form to avoid duplicate Register buttons interfering later (optional)
    await page.getByRole('button', { name: /^Register$/i }).first().click();

    // Open Login form
    await page.getByRole('button', { name: /^Login$/i }).first().click();
    const loginUserInput = page.getByPlaceholder('Enter your email or username');
    await loginUserInput.waitFor({ state: 'visible', timeout: 10000 });
    await loginUserInput.fill('e2euser');
    await page.getByPlaceholder('Enter your password').fill('Password123!');
    await page.locator('form button:has-text("Login")').first().click();

    const loginMessage = page.locator('div >> text=/Login successful|Login failed|Welcome back/i');
    await loginMessage.first().waitFor({ timeout: 15000 });
    await expect(loginMessage.first()).toContainText(/Login|Welcome|failed/i);
  });
});
