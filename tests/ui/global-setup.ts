import { request as playwrightRequest, chromium } from '@playwright/test';
import fs from 'fs';
import path from 'path';

/**
 * Robust global setup: perform a direct backend login using Playwright's request API
 * and seed the browser context with the returned SSO cookie. This avoids flaky
 * UI-level proxy timing issues and makes the stored `storageState` deterministic.
 */
async function globalSetup() {
  const backendUrl = process.env.BACKEND_URL || 'http://localhost:8080';
  const baseURL = process.env.BASE_URL || 'http://localhost:3000';

  console.log('[global-setup] Starting authentication setup...');
  
  // Brief delay to ensure account reset has taken effect
  await new Promise(resolve => setTimeout(resolve, 2000));

  const users = [
    { key: 'student', email: 'demo.student@uwm.edu', password: 'password' },
    { key: 'admin', email: 'demo.admin@uwm.edu', password: 'password' },
  ];

  const stateDir = path.resolve(__dirname, './storageStates');
  await fs.promises.mkdir(stateDir, { recursive: true });

  // If SSO retirement is enabled (default), skip SSO storage generation and
  // create lightweight placeholder storageState files so other tests that read
  // these files do not fail. To re-enable legacy SSO storage generation set
  // RETIRE_SSO=false in the environment (not recommended).
  const retireSso = process.env.RETIRE_SSO !== 'false';
  if (retireSso) {
    console.log('[global-setup] SSO retirement enabled — creating placeholder storageState files and skipping SSO login');
    for (const u of users) {
      const statePath = path.join(stateDir, `${u.key}.json`);
      // Create a minimal storageState artifact that has no cookies and no localStorage
      // so tests that reference the files can continue to run without performing actual SSO.
      const placeholder = { cookies: [], origins: [] };
      try {
        await fs.promises.writeFile(statePath, JSON.stringify(placeholder, null, 2));
      } catch (e) {
        console.warn('[global-setup] failed to write placeholder storageState for', u.key, e);
      }
    }
    return;
  }

  

  // Helper: small sleep
  const sleep = (ms: number) => new Promise(res => setTimeout(res, ms));

  // Helper: POST with retries for transient server errors
  async function postWithRetries(reqCtx: any, url: string, opts: any, attempts = 3, backoff = 1000) {
    let lastErr: any = null;
    for (let i = 1; i <= attempts; i++) {
      try {
        const r = await reqCtx.post(url, opts);
        if (r.ok() || r.status() < 500) return r; // return successful or client error immediately
        lastErr = r;
      } catch (e) {
        lastErr = e;
      }
      if (i < attempts) await sleep(backoff * i);
    }
    // If we exhausted attempts, throw or return lastErr
    return lastErr;
  }

  for (const u of users) {
    // Use a request context to POST credentials directly to the backend auth endpoint
    const requestContext = await playwrightRequest.newContext({ baseURL: backendUrl });
    try {
      // Try modern unified auth endpoint first with retries
      let resp = await postWithRetries(requestContext, '/auth/login', {
        headers: { 'Content-Type': 'application/json', 'X-Service-Origin': 'student-portal' },
        data: { email: u.email, password: u.password },
      });

      // Fallback to legacy "/login" if unified endpoint is unavailable (404) or errors
      if (!resp || (!resp.ok() && (resp.status() === 404 || resp.status() >= 500))) {
        try {
          resp = await postWithRetries(requestContext, '/login', {
            headers: { 'Content-Type': 'application/json', 'X-Service-Origin': 'student-portal' },
            data: { email: u.email, password: u.password },
          });
        } catch (ignored) {
          // continue to diagnostic and UI fallback below
        }
      }

      if (!resp || !resp.ok()) {
        console.warn(`[global-setup] Backend login failed for ${u.key}: ${resp.status()}`);
        // Save diagnostic artifact for CI
        try {
          const diagDir = path.join(stateDir, 'diagnostics');
          await fs.promises.mkdir(diagDir, { recursive: true });
          const body = await resp.text().catch(() => '<non-text-response>');
          const diag = { status: resp.status(), headers: resp.headers(), body };
          const diagPath = path.join(diagDir, `${u.key}-backend-fail-${Date.now()}.json`);
          await fs.promises.writeFile(diagPath, JSON.stringify(diag, null, 2));
        } catch (e) {
          console.warn('[global-setup] Failed to write diagnostic file', e);
        }
        // Fall back to UI login if backend auth failed
        await requestContext.dispose();
        await runUiLoginAndPersist(u, baseURL, stateDir);
        continue;
      }

      // Parse Set-Cookie header to extract PAWS360_SESSION value
      const setCookie = resp.headers()['set-cookie'] || resp.headers()['Set-Cookie'] || '';
      const match = /PAWS360_SESSION=([^;]+)/.exec(setCookie);

      // If there is no Set-Cookie header, check if the backend returned a session_token
      // in the JSON payload (some auth endpoints return a token rather than a cookie).
      let bodyJson: any = null;
      try {
        bodyJson = await resp.json();
      } catch (e) {
        // not JSON or no body
      }

      // If there is a session_token in the JSON response, create a storageState that
      // pre-populates the frontend localStorage with the token so the UI is considered
      // authenticated (frontend stores tokens under 'authToken').
      if (!match && bodyJson?.session_token) {
        const cookieValue = bodyJson.session_token;
        const statePath = path.join(stateDir, `${u.key}.json`);
        const state = {
          cookies: [],
          origins: [
            {
              origin: baseURL,
              localStorage: [
                { name: 'authToken', value: cookieValue }
              ]
            }
          ]
        };
        await fs.promises.writeFile(statePath, JSON.stringify(state, null, 2));
        await requestContext.dispose();
        continue;
      }

      if (!match) {
        console.warn(`[global-setup] No PAWS360_SESSION cookie in backend response for ${u.key}. Falling back to UI login.`);
        // Save diagnostic artifact for CI
        try {
          const diagDir = path.join(stateDir, 'diagnostics');
          await fs.promises.mkdir(diagDir, { recursive: true });
          const body = await resp.text().catch(() => '<non-text-response>');
          const diag = { status: resp.status(), headers: resp.headers(), body, endpointTried: ['/auth/login', '/login'] };
          const diagPath = path.join(diagDir, `${u.key}-no-cookie-${Date.now()}.json`);
          await fs.promises.writeFile(diagPath, JSON.stringify(diag, null, 2));
        } catch (e) {
          console.warn('[global-setup] Failed to write diagnostic file', e);
        }
        await requestContext.dispose();
        await runUiLoginAndPersist(u, baseURL, stateDir);
        continue;
      }

      const cookieValue = match[1];

      // Create a storageState that includes cookie + optional session_token as localStorage
      // so that frontends expecting either mechanism will be satisfied.
      const statePath = path.join(stateDir, `${u.key}.json`);
      const state: any = {
        cookies: [
          {
            name: 'PAWS360_SESSION',
            value: cookieValue,
            domain: 'localhost',
            path: '/',
            httpOnly: true,
            sameSite: 'Lax',
            secure: false,
          },
        ],
        origins: [],
      };

      // Add localStorage session_token if present in JSON body
      if (bodyJson?.session_token) {
        state.origins.push({ origin: baseURL, localStorage: [{ name: 'authToken', value: bodyJson.session_token }] });
      }

      // Also add a localStorage origin for 127.0.0.1/loopback variants so tests that
      // use different hostnames still get a pre-auth state
      try {
        const url = new URL(baseURL);
        const hostOrigin = `${url.protocol}//${url.hostname}${url.port ? ':' + url.port : ''}`;
        if (!state.origins.find((o: any) => o.origin === hostOrigin)) {
          state.origins.push({ origin: hostOrigin, localStorage: [] });
        }
      } catch (e) {
        // ignore bad URL parsing
      }

      // Write the storageState file directly for Playwright to reuse later
      await fs.promises.writeFile(statePath, JSON.stringify(state, null, 2));

      // Request context only needs to be disposed — no browser/context were created here
      try { await requestContext.dispose(); } catch (e) { /* ignore */ }
    } catch (e) {
      console.warn(`[global-setup] Exception during backend login for ${u.key}:`, e);
      try { await requestContext.dispose(); } catch {}
      // Attempt UI fallback
      await runUiLoginAndPersist(u, baseURL, stateDir);
    }
  }
}

async function runUiLoginAndPersist(u: { key: string; email: string; password: string }, baseURL: string, stateDir: string) {
  // Launch browser for UI fallback (headless). Attempt multiple times if transient errors occur.
  const maxAttempts = 3;
  let browser: any = null;
  let context: any = null;
  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      browser = await chromium.launch();
      context = await browser.newContext({ baseURL });
      break;
    } catch (err) {
      console.warn(`[global-setup] Chromium launch failed (attempt ${attempt}):`, err);
      if (attempt === maxAttempts) throw err;
      await new Promise(r => setTimeout(r, 1000 * attempt));
    }
  }
  const page = await context.newPage();
  try {
    await page.goto('/login');
    await page.fill('input[name="email"]', u.email);
    await page.fill('input[name="password"]', u.password);
    const loginResponsePromise = page.waitForResponse(r => r.url().includes('/auth/login'));
    await page.click('button[type="submit"]');
    const loginResponse = await loginResponsePromise;
    if (!loginResponse.ok()) console.warn(`[global-setup] UI login fallback failed for ${u.key}: ${loginResponse.status()}`);
    await page.waitForURL(/\/homepage/, { timeout: 30000 }).catch(() => {});
    const statePath = path.join(stateDir, `${u.key}.json`);
    await context.storageState({ path: statePath });
  } catch (e) {
    console.warn(`[global-setup] Exception during UI fallback login for ${u.key}:`, e);
  } finally {
    try { if (context) await context.close(); } catch (e) { /* ignore */ }
    try { if (browser) await browser.close(); } catch (e) { /* ignore */ }
  }
}

export default globalSetup;
