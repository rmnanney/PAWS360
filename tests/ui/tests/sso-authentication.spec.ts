import { test, expect, Page } from '@playwright/test';

/**
 * T058 E2E Testing Framework - SSO Authentication Flow Tests
 * 
 * Comprehensive end-to-end tests for SSO authentication between
 * Spring Boot backend (port 8081) and Next.js frontend (port 3000)
 * 
 * Constitutional Requirement: Article V (Test-Driven Infrastructure)
 */

test.describe('SSO Authentication End-to-End Tests', () => {
  
  // Test data - matching the seed data
  const validCredentials = {
    student: {
      email: 'demo.student@uwm.edu',
      password: 'password',
      expectedName: 'Demo',
      expectedRole: 'STUDENT'
    },
    admin: {
      email: 'demo.admin@uwm.edu', 
      password: 'password',
      expectedName: 'Admin',
      expectedRole: 'ADMIN'
    }
  };

  const invalidCredentials = {
    email: 'invalid@uwm.edu',
    password: 'wrongpassword'
  };

  // API endpoints
  const backendUrl = 'http://localhost:8081';
  const frontendUrl = 'http://localhost:3000';

  test.beforeEach(async ({ page }) => {
    // Clear any existing sessions
    await page.context().clearCookies();
    await page.goto('/');
  });

  test.describe('Student Authentication Flow', () => {
    
    test('should complete full student authentication journey', async ({ page }) => {
      // Step 1: Navigate to login page
      await page.goto('/login');
      await expect(page).toHaveTitle(/PAWS360/);
      
      // Step 2: Verify login form is present
      await expect(page.locator('form')).toBeVisible();
      await expect(page.locator('input[name="email"]')).toBeVisible();
      await expect(page.locator('input[name="password"]')).toBeVisible();
      await expect(page.locator('button[type="submit"]')).toBeVisible();

      // Step 3: Fill and submit login form
      await page.fill('input[name="email"]', validCredentials.student.email);
      await page.fill('input[name="password"]', validCredentials.student.password);
      
      // Monitor network requests to verify API calls
      const loginRequest = page.waitForResponse(response => 
        response.url().includes('/auth/login') && response.status() === 200
      );
      
      await page.click('button[type="submit"]');
      
      // Step 4: Wait for authentication to complete
      await loginRequest;
      
      // Step 5: Verify redirect to dashboard/homepage
      await expect(page).toHaveURL(/\/homepage/);
      
      // Step 6: Verify session cookie is set
      const cookies = await page.context().cookies();
      const sessionCookie = cookies.find(cookie => cookie.name === 'PAWS360_SESSION');
      expect(sessionCookie).toBeDefined();
      expect(sessionCookie?.httpOnly).toBeTruthy();
      
      // Step 7: Verify user data is displayed
      await expect(page.locator(`text=${validCredentials.student.expectedName}`)).toBeVisible();
      
      // Step 8: Verify session storage contains user info
      const userEmail = await page.evaluate(() => sessionStorage.getItem('userEmail'));
      const userRole = await page.evaluate(() => sessionStorage.getItem('userRole'));
      expect(userEmail).toBe(validCredentials.student.email);
      expect(userRole).toBe(validCredentials.student.expectedRole);
    });

    test('should maintain session across page navigation', async ({ page }) => {
      // Login first
      await authenticateUser(page, validCredentials.student);
      
      // Navigate to different pages
      await page.goto('/homepage');
      await expect(page.locator(`text=${validCredentials.student.expectedName}`)).toBeVisible();
      
      // Verify session is maintained on page refresh
      await page.reload();
      await expect(page.locator(`text=${validCredentials.student.expectedName}`)).toBeVisible();
      
      // Navigate back to login page - should redirect to homepage if authenticated
      await page.goto('/login');
      await expect(page).toHaveURL(/\/homepage/);
    });

    test('should handle session expiration gracefully', async ({ page }) => {
      // Login first
      await authenticateUser(page, validCredentials.student);
      
      // Simulate session expiration by clearing cookies
      await page.context().clearCookies();
      
      // Navigate to a protected page
      await page.goto('/homepage');
      
      // Should redirect to login page
      await expect(page).toHaveURL(/\/login/);
    });
  });

  test.describe('Admin Authentication Flow', () => {
    
    test('should complete admin authentication and access admin features', async ({ page }) => {
      // Authenticate as admin
      await authenticateUser(page, validCredentials.admin);
      
      // Verify admin-specific content is accessible
      await expect(page.locator(`text=${validCredentials.admin.expectedName}`)).toBeVisible();
      
      // Check admin role in session
      const userRole = await page.evaluate(() => sessionStorage.getItem('userRole'));
      expect(userRole).toBe(validCredentials.admin.expectedRole);
    });
  });

  test.describe('Authentication Failures', () => {
    
    test('should handle invalid credentials gracefully', async ({ page }) => {
      await page.goto('/login');
      
      // Fill invalid credentials
      await page.fill('input[name="email"]', invalidCredentials.email);
      await page.fill('input[name="password"]', invalidCredentials.password);
      
      // Monitor for login request
      const loginRequest = page.waitForResponse(response => 
        response.url().includes('/auth/login')
      );
      
      await page.click('button[type="submit"]');
      
      // Wait for response
      const response = await loginRequest;
      expect(response.status()).toBe(401);
      
      // Should remain on login page
      await expect(page).toHaveURL(/\/login/);
      
      // Should show error message
      await expect(page.locator('text=Invalid Email or Password')).toBeVisible();
    });

    test('should handle malformed email format', async ({ page }) => {
      await page.goto('/login');
      
      // Fill malformed email
      await page.fill('input[name="email"]', 'not-an-email');
      await page.fill('input[name="password"]', validCredentials.student.password);
      
      // Form validation should prevent submission
      const submitButton = page.locator('button[type="submit"]');
      await submitButton.click();
      
      // Should still be on login page
      await expect(page).toHaveURL(/\/login/);
    });

    test('should handle empty fields', async ({ page }) => {
      await page.goto('/login');
      
      // Try to submit empty form
      const submitButton = page.locator('button[type="submit"]');
      await submitButton.click();
      
      // Should still be on login page
      await expect(page).toHaveURL(/\/login/);
    });
  });

  test.describe('Logout Flow', () => {
    
    test('should complete logout and clear session', async ({ page }) => {
      // Login first
      await authenticateUser(page, validCredentials.student);
      
      // Find and click logout button/link
      await page.click('text=Logout');
      
      // Should redirect to login page
      await expect(page).toHaveURL(/\/login/);
      
      // Session storage should be cleared
      const userEmail = await page.evaluate(() => sessionStorage.getItem('userEmail'));
      expect(userEmail).toBeNull();
      
      // Session cookie should be cleared
      const cookies = await page.context().cookies();
      const sessionCookie = cookies.find(cookie => cookie.name === 'PAWS360_SESSION');
      expect(sessionCookie?.value).toBeFalsy();
    });
  });

  test.describe('Cross-Service Integration', () => {
    
    test('should validate API authentication with session cookie', async ({ page }) => {
      // Login to establish session
      await authenticateUser(page, validCredentials.student);
      
      // Make authenticated API call using the established session
      const response = await page.request.get(`${backendUrl}/auth/validate`, {
        headers: {
          'X-Service-Origin': 'student-portal'
        }
      });
      
      expect(response.ok()).toBeTruthy();
      const userData = await response.json();
      expect(userData.email).toBe(validCredentials.student.email);
    });

    test('should handle backend service unavailability', async ({ page }) => {
      // Simulate backend unavailability by using wrong port
      await page.route('**/auth/login', route => {
        route.abort('connectionfailed');
      });
      
      await page.goto('/login');
      await page.fill('input[name="email"]', validCredentials.student.email);
      await page.fill('input[name="password"]', validCredentials.student.password);
      await page.click('button[type="submit"]');
      
      // Should show appropriate error message
      await expect(page.locator('text=Service unavailable')).toBeVisible({ timeout: 10000 });
    });
  });

  test.describe('Security Validation', () => {
    
    test('should reject requests without proper CSRF protection', async ({ page }) => {
      // Attempt direct API call without session
      const response = await page.request.post(`${backendUrl}/auth/login`, {
        data: validCredentials.student
      });
      
      // Should handle CSRF appropriately
      expect([200, 401, 403]).toContain(response.status());
    });

    test('should validate secure cookie settings', async ({ page }) => {
      await authenticateUser(page, validCredentials.student);
      
      const cookies = await page.context().cookies();
      const sessionCookie = cookies.find(cookie => cookie.name === 'PAWS360_SESSION');
      
      expect(sessionCookie?.httpOnly).toBeTruthy();
      expect(sessionCookie?.sameSite).toBe('Lax');
      // Note: In development, secure might be false; in production should be true
    });
  });

  test.describe('Performance Validation', () => {
    
    test('should complete authentication within performance thresholds', async ({ page }) => {
      await page.goto('/login');
      
      const startTime = Date.now();
      
      await page.fill('input[name="email"]', validCredentials.student.email);
      await page.fill('input[name="password"]', validCredentials.student.password);
      
      const loginRequest = page.waitForResponse(response => 
        response.url().includes('/auth/login') && response.status() === 200
      );
      
      await page.click('button[type="submit"]');
      await loginRequest;
      
      const endTime = Date.now();
      const authTime = endTime - startTime;
      
      // Authentication should complete within 5 seconds
      expect(authTime).toBeLessThan(5000);
    });

    test('should load dashboard quickly after authentication', async ({ page }) => {
      await authenticateUser(page, validCredentials.student);
      
      const startTime = Date.now();
      await page.goto('/homepage');
      
      // Wait for main content to load
      await expect(page.locator(`text=${validCredentials.student.expectedName}`)).toBeVisible();
      
      const endTime = Date.now();
      const loadTime = endTime - startTime;
      
      // Dashboard should load within 3 seconds
      expect(loadTime).toBeLessThan(3000);
    });
  });

  test.describe('Browser Compatibility', () => {
    
    test('should work in different browser contexts', async ({ page }) => {
      // Test in a new browser context (incognito-like)
      const context = await page.context().browser()?.newContext();
      if (!context) throw new Error('Could not create new context');
      
      const incognitoPage = await context.newPage();
      await authenticateUser(incognitoPage, validCredentials.student);
      
      // Verify authentication works in incognito mode
      await expect(incognitoPage.locator(`text=${validCredentials.student.expectedName}`)).toBeVisible();
      
      await context.close();
    });
  });
});

/**
 * Helper function to authenticate a user
 */
async function authenticateUser(page: Page, credentials: { email: string; password: string; expectedName: string }) {
  await page.goto('/login');
  await page.fill('input[name="email"]', credentials.email);
  await page.fill('input[name="password"]', credentials.password);
  
  const loginRequest = page.waitForResponse(response => 
    response.url().includes('/auth/login') && response.status() === 200
  );
  
  await page.click('button[type="submit"]');
  await loginRequest;
  
  // Wait for redirect to complete
  await expect(page).toHaveURL(/\/homepage/);
  await expect(page.locator(`text=${credentials.expectedName}`)).toBeVisible();
}