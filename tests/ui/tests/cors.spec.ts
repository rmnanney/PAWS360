import { test, expect } from '@playwright/test';

/**
 * Basic CORS preflight and credentialed request checks for authentication endpoints
 */

test.describe('CORS preflight', () => {
  const backendUrl = process.env.BACKEND_URL || 'http://localhost:8080';
  const origin = process.env.BASE_URL || 'http://localhost:3000';

  test('should respond to preflight for POST /auth/login with proper headers', async ({ request }) => {
    const response = await request.fetch(`${backendUrl}/auth/login`, {
      method: 'OPTIONS',
      headers: {
        'Origin': origin,
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': 'Content-Type, X-Service-Origin'
      }
    });

    expect([200, 204]).toContain(response.status());
    const allowOrigin = response.headers()['access-control-allow-origin'];
    const allowMethods = response.headers()['access-control-allow-methods'];
    const allowCreds = response.headers()['access-control-allow-credentials'];

    expect(allowOrigin).toBeDefined();
    // Spring may echo specific origin
    // Accept exact origin, 127.0.0.1 variant, or wildcard
    const altOrigin = origin.replace('localhost', '127.0.0.1');
    expect([origin, altOrigin, '*']).toContain(allowOrigin);
    expect(allowMethods?.toUpperCase()).toContain('POST');
    expect(["true", "TRUE"]).toContain((allowCreds || '').toLowerCase());
  });

  test('should respond to preflight for POST /login with proper headers', async ({ request }) => {
    const response = await request.fetch(`${backendUrl}/login`, {
      method: 'OPTIONS',
      headers: {
        'Origin': origin,
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': 'Content-Type, X-Service-Origin'
      }
    });

    expect([200, 204]).toContain(response.status());
    const allowOrigin = response.headers()['access-control-allow-origin'];
    const allowMethods = response.headers()['access-control-allow-methods'];
    const allowCreds = response.headers()['access-control-allow-credentials'];

    expect(allowOrigin).toBeDefined();
    // Spring may echo specific origin
    const altOrigin2 = origin.replace('localhost', '127.0.0.1');
    expect([origin, altOrigin2, '*']).toContain(allowOrigin);
    expect(allowMethods?.toUpperCase()).toContain('POST');
    expect(["true", "TRUE"]).toContain((allowCreds || '').toLowerCase());
  });
});
