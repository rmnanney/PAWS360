import { test, expect } from '@playwright/test';

// Lightweight Playwright test used by CI smoke to set localStorage auth and
// verify the authenticated homepage. The script reads SESSION_TOKEN and BASE_URL
// from environment variables.

test('set authToken and visit homepage', async ({ page }) => {
  const token = process.env.SESSION_TOKEN || '';
  const base = process.env.BASE_URL || 'http://localhost:3000';

  if (!token) {
    throw new Error('SESSION_TOKEN not provided');
  }

  // Ensure our init script runs before the app loads so client-side code sees authToken
  await page.context().addInitScript((value: string) => {
    try {
      localStorage.setItem('authToken', value);
    } catch (e) {
      // noop
    }
  }, token);

  // Navigate to homepage and assert the UI that indicates successful login
  await page.goto(`${base}/homepage`, { waitUntil: 'domcontentloaded', timeout: 30000 });

  // We expect the visible page to contain the 'Homepage' title or similar text
  await expect(page.locator('text=Homepage')).toBeVisible({ timeout: 15000 });
});
