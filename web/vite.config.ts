import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import {createSvgIconsPlugin} from 'vite-plugin-svg-icons'
import AutoImport from 'unplugin-auto-import/vite'
import Components from 'unplugin-vue-components/vite'
import * as path from "node:path";
import { fileURLToPath, URL } from "node:url";
import { PrimeVueResolver } from "@primevue/auto-import-resolver";
import tailwindcss from '@tailwindcss/vite'

export default defineConfig({
  base: '/',
  server: {
    proxy: {
      "/dev": {
        // target: 'https://kamden-refusable-populously.ngrok-free.dev', changeOrigin: true, rewrite: (path) => path.replace(/^\/dev/, ''),
        target: 'http://127.0.0.1:3000', changeOrigin: true, rewrite: (path) => path.replace(/^\/dev/, ''),
      }
    }
  },
  plugins: [
    vue(),
    tailwindcss(),
    AutoImport({
      eslintrc: {
        enabled: true, filepath: "./.eslintrc-auto-import.json", globalsPropValue: true
      },
      imports: ['vue', 'pinia']
    }),
    Components({
      resolvers: [PrimeVueResolver()]
    }),

    createSvgIconsPlugin({
      // 指定图标文件夹路径（绝对路径）
      iconDirs: [path.resolve(process.cwd(), 'src/assets/svg')],
      symbolId: 'icon-[name]',
      svgoOptions: true,
      inject: 'body-last'
    })
  ],
  resolve: {
    extensions: ['.js', '.vue', '.scss', '.css', '.json', '.ts', '.d.ts'],
    alias: {
      '@': fileURLToPath(new URL('src', import.meta.url))
    }
  }
})
