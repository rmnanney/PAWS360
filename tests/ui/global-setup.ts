import { chromium } from '@playwright/test';
import fs from 'fs';
import path from 'path';

/**
 * Global setup to pre-authenticate common users and persist storage state.
 * This dramatically speeds up tests by avoiding UI logins in every test.
 */
async function globalSetup() {
  const backendUrl = process.env.BACKEND_URL || 'http://localhost:8081';
  const baseURL = process.env.BASE_URL || 'http://localhost:3000';

  const users = [
    { key: 'student', email: 'demo.student@uwm.edu', password: 'password' },
    { key: 'admin', email: 'demo.admin@uwm.edu', password: 'password' },
  ];

  for (const u of users) {
    const browser = await chromium.launch();
    const context = await browser.newContext({ baseURL });
    const page = await context.newPage();

    // Perform real UI login to ensure cookies set via CORS with credentials
    try {
      await page.goto('/login');
      await page.fill('input[name="email"]', u.email);
      await page.fill('input[name="password"]', u.password);

      // Intercept login response for success confirmation
      const loginResponsePromise = page.waitForResponse(r => r.url().includes('/auth/login'));
      await page.click('button[type="submit"]');
      const loginResponse = await loginResponsePromise;

      if (!loginResponse.ok()) {
        console.warn(`[global-setup] Login HTTP status not OK for ${u.key}: ${loginResponse.status()}`);
      }

      // Wait for redirect to homepage (best-effort; ignore if fails)
      await page.waitForURL(/\/homepage/, { timeout: 5000 }).catch(() => {});

      // Persist storage state
      const stateDir = path.resolve(__dirname, './storageStates');
      await fs.promises.mkdir(stateDir, { recursive: true });
      const statePath = path.join(stateDir, `${u.key}.json`);
      await context.storageState({ path: statePath });
    } catch (e) {
      console.warn(`[global-setup] Exception during UI login for ${u.key}:`, e);
    } finally {
      await browser.close();
    }
  }
}

export default globalSetup;
