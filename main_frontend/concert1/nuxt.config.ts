// https://nuxt.com/docs/api/configuration/nuxt-config

import tailwindcss from "@tailwindcss/vite";

export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },
  ssr: true,
  app: {
    baseURL: '/',
    head: {
      meta: []
    }
  },
  runtimeConfig: {
    public: {
      backendBaseUrl: 'https://d3qkurc1gwuwno.cloudfront.net'
    }
  },
  css: ['~/assets/css/main.css'],
  vite: {
    plugins: [
      tailwindcss(),
    ],
  },
})
