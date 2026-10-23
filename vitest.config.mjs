import {defineConfig} from 'vitest/config';

// JavaScript tests live next to the code they test, as *.test.js or *.test.jsx
// under app/javascript. Run them with `yarn test`.
export default defineConfig({
  oxc: {jsx: {runtime: 'automatic'}},
  test: {
    environment: 'jsdom',
    include: ['app/javascript/**/*.test.{js,jsx}'],
    setupFiles: ['app/javascript/test/setup.js'],
    // `yarn test:coverage`; CI uploads coverage/lcov.info to Codecov.
    coverage: {
      provider: 'v8',
      reporter: ['text-summary', 'lcov'],
      include: ['app/javascript/**/*.{js,jsx}'],
      exclude: ['app/javascript/**/*.test.{js,jsx}', 'app/javascript/test/**'],
    },
  },
});
