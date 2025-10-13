import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath } from 'url'

export default defineConfig({
  plugins: [vue()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./vitest.setup.ts'],
    include: ['test/**/*.spec.ts'],
    exclude: ['tests/e2e/**', 'node_modules/**'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      exclude: [
        'node_modules/',
        'test/',
        'tests/',
        '**/*.config.*',
        '**/dist/**',
        // Exclude pages - tested by E2E tests
        'app/pages/**',
        // Exclude layouts - integration-level
        'app/layouts/**',
        // Exclude dynamic routes
        '**/[id].vue',
        // Exclude generated types and Nuxt internals
        '.nuxt/**',
        '**/*.d.ts',
        // Exclude server-side API routes (backend integration tests)
        'server/**',
        // Exclude Cypress E2E tests
        'cypress/**',
        // Exclude root composables (duplicate of app/composables)
        'composables/**',
        // Exclude legacy/unused components
        'app/components/CartEach.vue',
        'app/components/CategoriesTop.vue',
        'app/components/DatabaseInfo.vue',
        'app/components/ProductPreselection.vue',
        'app/components/ProductTag.vue',
        'app/components/SearchBar.vue',
        // Exclude components used only in pages (tested via E2E)
        'app/components/LoadingSpinner.vue',
        'app/components/LoginModal.vue'
      ]
    }
  },
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./app', import.meta.url)),
      '~': fileURLToPath(new URL('./', import.meta.url)),
      '~~': fileURLToPath(new URL('./', import.meta.url)),
      'assets': fileURLToPath(new URL('./app/assets', import.meta.url))
    }
  }
})
