import { request as playwrightRequest, chromium } from '@playwright/test';
import fs from 'fs';
import path from 'path';

/**
 * Robust global setup: perform a direct backend login using Playwright's request API
 * and seed the browser context with the returned SSO cookie. This avoids flaky
 * UI-level proxy timing issues and makes the stored `storageState` deterministic.
 */
async function globalSetup() {
  const backendUrl = process.env.BACKEND_URL || 'http://localhost:8081';
  const baseURL = process.env.BASE_URL || 'http://localhost:3000';

  const users = [
    { key: 'student', email: 'demo.student@uwm.edu', password: 'password' },
    { key: 'admin', email: 'demo.admin@uwm.edu', password: 'password' },
  ];

  const stateDir = path.resolve(__dirname, './storageStates');
  await fs.promises.mkdir(stateDir, { recursive: true });

  for (const u of users) {
    // Use a request context to POST credentials directly to the backend auth endpoint
    const requestContext = await playwrightRequest.newContext({ baseURL: backendUrl });
    try {
      const resp = await requestContext.post('/auth/login', {
        headers: { 'Content-Type': 'application/json', 'X-Service-Origin': 'student-portal' },
        data: { email: u.email, password: u.password },
      });

      if (!resp.ok()) {
        console.warn(`[global-setup] Backend login failed for ${u.key}: ${resp.status()}`);
        // Fall back to UI login if backend auth failed
        await requestContext.dispose();
        await runUiLoginAndPersist(u, baseURL, stateDir);
        continue;
      }

      // Parse Set-Cookie header to extract PAWS360_SESSION value
      const setCookie = resp.headers()['set-cookie'] || resp.headers()['Set-Cookie'] || '';
      const match = /PAWS360_SESSION=([^;]+)/.exec(setCookie);
      if (!match) {
        console.warn(`[global-setup] No PAWS360_SESSION cookie in backend response for ${u.key}. Falling back to UI login.`);
        await requestContext.dispose();
        await runUiLoginAndPersist(u, baseURL, stateDir);
        continue;
      }

      const cookieValue = match[1];

      // Create a browser context and add the cookie for the frontend domain (localhost)
      const browser = await chromium.launch();
      const context = await browser.newContext({ baseURL });

      // Add cookie so the browser context is authenticated
      await context.addCookies([
        {
          name: 'PAWS360_SESSION',
          value: cookieValue,
          domain: 'localhost',
          path: '/',
          httpOnly: true,
          sameSite: 'Lax',
          secure: false,
        },
      ]);

      const statePath = path.join(stateDir, `${u.key}.json`);
      await context.storageState({ path: statePath });

      await context.close();
      await browser.close();
      await requestContext.dispose();
    } catch (e) {
      console.warn(`[global-setup] Exception during backend login for ${u.key}:`, e);
      try {
        await requestContext.dispose();
      } catch {}
      // Attempt UI fallback
      await runUiLoginAndPersist(u, baseURL, stateDir);
    }
  }
}

async function runUiLoginAndPersist(u: { key: string; email: string; password: string }, baseURL: string, stateDir: string) {
  const browser = await chromium.launch();
  const context = await browser.newContext({ baseURL });
  const page = await context.newPage();
  try {
    await page.goto('/login');
    await page.fill('input[name="email"]', u.email);
    await page.fill('input[name="password"]', u.password);
    const loginResponsePromise = page.waitForResponse(r => r.url().includes('/auth/login'));
    await page.click('button[type="submit"]');
    const loginResponse = await loginResponsePromise;
    if (!loginResponse.ok()) console.warn(`[global-setup] UI login fallback failed for ${u.key}: ${loginResponse.status()}`);
    await page.waitForURL(/\/homepage/, { timeout: 10000 }).catch(() => {});
    const statePath = path.join(stateDir, `${u.key}.json`);
    await context.storageState({ path: statePath });
  } catch (e) {
    console.warn(`[global-setup] Exception during UI fallback login for ${u.key}:`, e);
  } finally {
    await context.close();
    await browser.close();
  }
}

export default globalSetup;
