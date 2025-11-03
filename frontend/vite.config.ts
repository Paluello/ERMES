import { defineConfig } from 'vite'

export default defineConfig({
  server: {
    port: 3000,
    proxy: {
      '/api': {
        target: 'http://100.84.46.19:8000',
        changeOrigin: true
      },
      '/ws': {
        target: 'ws://100.84.46.19:8000',
        ws: true
      }
    }
  }
})

