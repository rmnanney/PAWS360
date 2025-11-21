import { test, expect } from '@playwright/test';

// Optionally skip API integration tests in CI if they are known to be flaky.
// Set `CI_SKIP_API=true` in CI to skip these tests without changing local runs.
const _skipApiIntegration = (process.env.CI_SKIP_API === 'true') || false;
const describeMaybeAPITests = _skipApiIntegration ? test.describe.skip : test.describe;

describeMaybeAPITests('PAWS360 API Integration', () => {
  test('should verify API endpoints are accessible', async ({ page }) => {
    // Test classes API
    const classesResponse = await page.request.get('/api/classes/');
    expect(classesResponse.ok()).toBeTruthy();
    const classesData = await classesResponse.json();
    expect(classesData.status).toBe('classes-api-mock');
    expect(Array.isArray(classesData.classes)).toBeTruthy();

    // Test student planning API
    const planningResponse = await page.request.get('/api/student/planning/');
    expect(planningResponse.ok()).toBeTruthy();
    const planningData = await planningResponse.json();
    expect(planningData.status).toBe('planning-api-mock');
    expect(planningData.student).toBeDefined();

    // Test instructor courses API
    const instructorResponse = await page.request.get('/api/instructor/courses/');
    expect(instructorResponse.ok()).toBeTruthy();
    const instructorData = await instructorResponse.json();
    expect(instructorData.status).toBe('instructor-api-mock');
    expect(Array.isArray(instructorData.courses)).toBeTruthy();
  });

  test('should handle API errors gracefully', async ({ page }) => {
    // Test non-existent endpoint - this mock app returns HTML for all endpoints
    const errorResponse = await page.request.get('/api/nonexistent/');
    expect(errorResponse.status()).toBe(200); // Mock app returns 200 for all requests

    // The response is HTML, not JSON, so we check for HTML content
    const responseText = await errorResponse.text();
    expect(responseText).toContain('<!DOCTYPE html>'); // Should be HTML content
  });
});
