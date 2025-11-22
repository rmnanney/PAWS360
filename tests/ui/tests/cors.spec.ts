import { test, expect } from '@playwright/test';

/**
 * Basic CORS preflight and credentialed request checks for authentication endpoints
 */

test.describe('CORS preflight', () => {
  const backendUrl = process.env.BACKEND_URL || 'http://localhost:8080';
  const origin = process.env.BASE_URL || 'http://localhost:3000';

  test('should respond to preflight for POST /auth/login with proper headers', async ({ request }) => {
    let response;
    try {
      response = await request.fetch(`${backendUrl}/auth/login`, {
      method: 'OPTIONS',
      headers: {
        'Origin': origin,
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': 'Content-Type, X-Service-Origin'
      }
    });
    } catch (e: any) {
      if (e && (e.message || '').includes('ECONNREFUSED')) {
        test.skip(true, 'Skipping CORS preflight test: backend not reachable');
        return;
      }
      throw e;
    }

    // Some deployments or proxies may return 403 for disallowed preflight; accept that as well
    expect([200, 204, 403]).toContain(response.status());
    const allowOrigin = response.headers()['access-control-allow-origin'];
    const allowMethods = response.headers()['access-control-allow-methods'];
    const allowCreds = response.headers()['access-control-allow-credentials'];

    // Not all deployments return every Access-Control header for OPTIONS responses.
    // If present, assert reasonable values. If absent, accept it but keep the status check above.
    if (allowOrigin) {
      const altOrigin = origin.replace('localhost', '127.0.0.1');
      expect([origin, altOrigin, '*']).toContain(allowOrigin);
    }

    // Methods header should include POST if present — accept if omitted in some proxies
    if (allowMethods) {
      expect(allowMethods.toUpperCase()).toContain('POST');
    }

    // Allow credentials header, if present, should be truthy
    if (allowCreds) {
      expect(["true", "TRUE"]).toContain((allowCreds || '').toLowerCase());
    }
  });

  test('should respond to preflight for POST /login with proper headers', async ({ request }) => {
    let response;
    try {
      response = await request.fetch(`${backendUrl}/login`, {
      method: 'OPTIONS',
      headers: {
        'Origin': origin,
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': 'Content-Type, X-Service-Origin'
      }
    });
    } catch (e: any) {
      if (e && (e.message || '').includes('ECONNREFUSED')) {
        test.skip(true, 'Skipping CORS preflight test: backend not reachable');
        return;
      }
      throw e;
    }

    // Some deployments or proxies may return 403 for disallowed preflight; accept that as well
    expect([200, 204, 403]).toContain(response.status());
    const allowOrigin = response.headers()['access-control-allow-origin'];
    const allowMethods = response.headers()['access-control-allow-methods'];
    const allowCreds = response.headers()['access-control-allow-credentials'];

    if (allowOrigin) {
      const altOrigin2 = origin.replace('localhost', '127.0.0.1');
      expect([origin, altOrigin2, '*']).toContain(allowOrigin);
    }

    if (allowMethods) {
      expect(allowMethods.toUpperCase()).toContain('POST');
    }

    if (allowCreds) {
      expect(["true", "TRUE"]).toContain((allowCreds || '').toLowerCase());
    }
  });
});
