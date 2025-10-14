import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath } from 'node:url'

export default defineConfig({
  plugins: [vue()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./vitest.setup.ts'],
    include: ['test/unit/**/*.test.{js,ts}'],
    exclude: ['node_modules', '.nuxt', 'cypress', 'test/components/**', 'tests/e2e/**'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html', 'lcov'],
      reportsDirectory: './coverage',
      include: [
        'app/**/*.{js,ts,vue}',
        'composables/**/*.{js,ts}'
      ],
      exclude: [
        'node_modules/**',
        '.nuxt/**',
        'dist/**',
        'coverage/**',
        'cypress/**',
        '**/*.d.ts',
        '**/*.config.*',
        '**/mockData',
        'test/**',
        '**/*.spec.ts',
        '**/*.test.ts'
      ],
      all: true,
      thresholds: {
        lines: 40,
        functions: 50,
        branches: 70,
        statements: 40
      }
    }
  },
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./', import.meta.url)),
      '~': fileURLToPath(new URL('./', import.meta.url)),
      '~~': fileURLToPath(new URL('./', import.meta.url)),
      'assets': fileURLToPath(new URL('./app/assets', import.meta.url))
    }
  }
})
