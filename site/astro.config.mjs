import { defineConfig } from 'astro/config';
export default defineConfig({
  site: 'https://agenda.omeu.space',
  outDir: '../docs',
  build: { assets: 'assets' }
});
