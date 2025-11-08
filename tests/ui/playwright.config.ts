import { defineConfig, devices } from '@playwright/test';

/**
 * @see https://playwright.dev/docs/test-configuration
 */
export default defineConfig({
  testDir: './tests',
  globalSetup: require.resolve('./global-setup'),
  /* Run tests in files in parallel (can be overridden) */
  fullyParallel: true,
  /* Fail the build on CI if you accidentally left test.only in the source code. */
  forbidOnly: !!process.env.CI,
  /* Retry on CI only (allow override) */
  retries: process.env.PW_RETRIES ? Number(process.env.PW_RETRIES) : (process.env.CI ? 1 : 0),
  /* Allow overriding workers; default to 1 on CI for stability unless PW_WORKERS provided */
  workers: process.env.PW_WORKERS ? Number(process.env.PW_WORKERS) : (process.env.CI ? 1 : undefined),
  /* Reporter to use. See https://playwright.dev/docs/test-reporters */
  reporter: process.env.CI ? 'html' : 'list',
  /* Shared settings for all the projects below. See https://playwright.dev/docs/api/class-testoptions. */
  use: {
    /* Base URL to use in actions like `await page.goto('/')`. */
    baseURL: process.env.BASE_URL || 'http://localhost:3000',

    /* Collect trace when retrying the failed test. See https://playwright.dev/docs/trace-viewer */
    // Keep traces only on retry to reduce overhead (allow simple override of known modes)
    trace: ((): any => {
      const mode = process.env.PW_TRACE;
      if (!mode) return 'on-first-retry';
      // Accept only documented string literals
      if (['on', 'off', 'retain-on-failure', 'on-first-retry'].includes(mode)) return mode as any;
      return 'on-first-retry';
    })(),

    /* Take screenshot only when test fails */
    screenshot: ((): any => {
      const mode = process.env.PW_SCREENSHOT;
      if (!mode) return 'only-on-failure';
      if (['on', 'off', 'only-on-failure'].includes(mode)) return mode as any;
      return 'only-on-failure';
    })(),

    /* Record video only when test fails */
    video: ((): any => {
      const mode = process.env.PW_VIDEO;
      if (!mode) return 'retain-on-failure';
      if (['on', 'off', 'retain-on-failure', 'on-first-retry'].includes(mode)) return mode as any;
      return 'retain-on-failure';
    })(),

    /* SSO Authentication context */
    extraHTTPHeaders: {
      'X-Service-Origin': 'student-portal'
    },

    /* Accept cookies for SSO session management */
    acceptDownloads: true,
  },

  /* Configure projects for major browsers */
  projects: [
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'] },
    },
  ],

  /* Configure multiple web servers for E2E SSO testing */
  // When running against externally managed servers (docker-compose, GitHub Actions services), skip spawning local servers
  webServer: (process.env.CI || process.env.PW_EXTERNAL_SERVERS) ? undefined : [
    {
      command: 'cd ../../ && npm run dev',
      url: 'http://localhost:3000',
      reuseExistingServer: !process.env.CI,
      timeout: 120 * 1000,
    },
    {
      command: 'cd ../../ && ./mvnw spring-boot:run -Dspring-boot.run.profiles=test',
      url: 'http://localhost:8081/actuator/health',
      reuseExistingServer: !process.env.CI,
      timeout: 120 * 1000,
    }
  ],
});