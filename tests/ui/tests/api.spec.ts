import { test, expect } from '@playwright/test';

test.describe('PAWS360 API Integration', () => {
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
    // Test non-existent endpoint
    const errorResponse = await page.request.get('/api/nonexistent/');
    expect(errorResponse.status()).toBe(404);
  });
});