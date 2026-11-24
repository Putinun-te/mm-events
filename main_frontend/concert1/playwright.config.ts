import { defineConfig, devices } from '@playwright/test'

// Runs against the Docker Compose stack: frontend on :3000, backend on :8080.
// Override with PLAYWRIGHT_BASE_URL / PLAYWRIGHT_API_URL.
export default defineConfig({
  testDir: './playwright',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI ? [['list'], ['html', { open: 'never' }]] : 'list',
  // The Nuxt dev server compiles a page on first visit
  timeout: 120_000,
  expect: { timeout: 10_000 },
  use: {
    baseURL: process.env.PLAYWRIGHT_BASE_URL || 'http://localhost:3000',
    navigationTimeout: 120_000,
    actionTimeout: 10_000,
    trace: 'on-first-retry',
    screenshot: 'only-on-failure'
  },
  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } }
  ]
})
