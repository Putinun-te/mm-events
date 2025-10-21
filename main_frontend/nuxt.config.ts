// https://nuxt.com/docs/api/configuration/nuxt-config

import tailwindcss from "@tailwindcss/vite";

export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },
  app: {
    baseURL: '/index'
  },
  runtimeConfig: {
    public: {
      backendBaseUrl: process.env.BACKEND_BASE_URL || 'http://localhost:8080'
    }
  },
  css: ['~/assets/css/main.css'],
    vite: {
    plugins: [
      tailwindcss(),
    ],
  },
})
