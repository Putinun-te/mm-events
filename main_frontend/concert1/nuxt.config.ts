// https://nuxt.com/docs/api/configuration/nuxt-config

import tailwindcss from "@tailwindcss/vite";

export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },
  ssr: false,
  app: {
    baseURL: '/',
    head: {
      meta: []
    }
  },
  runtimeConfig: {
    public: {
      backendBaseUrl: process.env.NUXT_PUBLIC_BACKEND_BASE_URL || 'http://13.215.52.174:8080'
    }
  },
  css: ['~/assets/css/main.css'],
  vite: {
    plugins: [
      tailwindcss(),
    ],
  },
})
