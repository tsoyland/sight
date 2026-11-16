/// <reference types="vitest/config" />
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// In development the .NET API runs on :5042 (see api/src/Sight.Api/Properties/launchSettings.json).
const apiTarget = process.env.SIGHT_API_URL ?? 'http://localhost:5042'

export default defineConfig({
  plugins: [react()],
  server: {
    proxy: {
      '/api': apiTarget,
      '/health': apiTarget,
      '/hubs': { target: apiTarget, ws: true },
    },
  },
  test: {
    environment: 'jsdom',
    setupFiles: ['./src/test/setup.ts'],
  },
})
