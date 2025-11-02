// https://nuxt.com/docs/api/configuration/nuxt-config

import tailwindcss from "@tailwindcss/vite";

export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },
  app: {
    baseURL: '/'  // Changed from '/concert/' for S3 root deployment
  },
  runtimeConfig: {
    public: {
      backendBaseUrl: process.env.API_GATEWAY_URL || process.env.BACKEND_BASE_URL || 'http://localhost:8080'
    }
  },
  css: ['~/assets/css/main.css'],
    vite: {
    plugins: [
      tailwindcss(),
    ],
  },
})
