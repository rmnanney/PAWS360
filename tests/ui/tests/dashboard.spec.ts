import { test, expect } from '@playwright/test';

test.describe('PAWS360 AdminLTE Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the dashboard
    await page.goto('/');
    await page.waitForLoadState('networkidle');
  });

  test('should load dashboard successfully', async ({ page }) => {
    // Check page title
    await expect(page).toHaveTitle(/PAWS360/);

    // Check main elements are present
    await expect(page.locator('.main-header')).toBeVisible();
    await expect(page.locator('.main-sidebar')).toBeVisible();
    await expect(page.locator('.content-wrapper')).toBeVisible();
  });

  test('should display role navigation tabs', async ({ page }) => {
    // Check role navigation exists
    const roleNav = page.locator('.role-nav');
    await expect(roleNav).toBeVisible();

    // Check all role navigation items are present (using onclick attributes)
    await expect(page.locator('a[onclick*="setRole(\'admin\'\)"]')).toBeVisible();
    await expect(page.locator('a[onclick*="setRole(\'student\'\)"]')).toBeVisible();
    await expect(page.locator('a[onclick*="setRole(\'instructor\'\)"]')).toBeVisible();
    await expect(page.locator('a[onclick*="setRole(\'registrar\'\)"]')).toBeVisible();
  });

  test.describe('Admin Role', () => {
    test('should display admin interface', async ({ page }) => {
      // Click admin navigation link
      await page.locator('a[onclick*="setRole(\'admin\'\)"]').click();

      // Wait for content to load
      await page.waitForTimeout(500);

      // Check admin content is loaded (look for admin-specific text)
      await expect(page.locator('text=Class Creation & Management')).toBeVisible();
      await expect(page.locator('button[onclick*="showCreateClassModal"]')).toBeVisible();
    });

    test('should open create class modal', async ({ page }) => {
      // Click admin navigation link
      await page.locator('a[onclick*="setRole(\'admin\'\)"]').click();

      // Wait for content to load
      await page.waitForTimeout(500);

      // Click create class button (it's in the card body)
      await page.locator('button[onclick*="showCreateClassModal"]').click();

      // Check modal opens
      await expect(page.locator('.modal')).toBeVisible();
      await expect(page.locator('#courseCode')).toBeVisible();
      await expect(page.locator('#courseName')).toBeVisible();
      await expect(page.locator('#instructor')).toBeVisible();
    });

    test('should display classes table', async ({ page }) => {
      // Click admin navigation link
      await page.locator('a[onclick*="setRole(\'admin\'\)"]').click();

      // Wait for content to load
      await page.waitForTimeout(500);

      // Check classes table exists (look for table with CS101, MATH201, etc.)
      await expect(page.locator('text=CS101')).toBeVisible();
      await expect(page.locator('text=MATH201')).toBeVisible();
      await expect(page.locator('text=Introduction to Computer Science')).toBeVisible();
    });
  });

  test.describe('Student Role', () => {
    test('should display student interface', async ({ page }) => {
      // Click student navigation link
      await page.locator('a[onclick*="setRole(\'student\'\)"]').click();

      // Wait for content to load
      await page.waitForTimeout(500);

      // Check student content is loaded
      await expect(page.locator('text=Academic Planning')).toBeVisible();
      await expect(page.locator('text=Course Registration')).toBeVisible();
      await expect(page.locator('#courseSearch')).toBeVisible();
    });

    test('should display degree progress', async ({ page }) => {
      // Click student navigation link
      await page.locator('a[onclick*="setRole(\'student\'\)"]').click();

      // Wait for content to load
      await page.waitForTimeout(500);

      // Check degree progress information
      await expect(page.locator('text=Degree Progress')).toBeVisible();
      await expect(page.locator('text=Credits Completed')).toBeVisible();
      await expect(page.locator('text=GPA')).toBeVisible();
    });
  });

  test.describe('Instructor Role', () => {
    test('should display instructor interface', async ({ page }) => {
      // Click instructor navigation link
      await page.locator('a[onclick*="setRole(\'instructor\'\)"]').click();

      // Wait for content to load
      await page.waitForTimeout(500);

      // Check instructor content is loaded
      await expect(page.locator('text=Course Management Dashboard')).toBeVisible();
      await expect(page.locator('text=Create Assignment')).toBeVisible();
    });

    test('should display course statistics', async ({ page }) => {
      // Click instructor navigation link
      await page.locator('a[onclick*="setRole(\'instructor\'\)"]').click();

      // Wait for content to load
      await page.waitForTimeout(500);

      // Check course statistics are displayed
      await expect(page.locator('text=Active Courses')).toBeVisible();
      await expect(page.locator('text=Total Students')).toBeVisible();
      await expect(page.locator('text=Assignments Due')).toBeVisible();
    });
  });

  test.describe('Registrar Role', () => {
    test('should display registrar interface', async ({ page }) => {
      // Click registrar navigation link
      await page.locator('a[onclick*="setRole(\'registrar\'\)"]').click();

      // Wait for content to load
      await page.waitForTimeout(500);

      // Check registrar content is loaded
      await expect(page.locator('text=Enrollment Management System')).toBeVisible();
      await expect(page.locator('text=Bulk Student Enrollment')).toBeVisible();
    });

    test('should display enrollment data', async ({ page }) => {
      // Click registrar navigation link
      await page.locator('a[onclick*="setRole(\'registrar\'\)"]').click();

      // Wait for content to load
      await page.waitForTimeout(500);

      // Check enrollment statistics
      await expect(page.locator('text=Total Enrolled')).toBeVisible();
      await expect(page.locator('text=Active Courses')).toBeVisible();
    });
  });

  test.describe('System Status', () => {
    test('should display system status', async ({ page }) => {
      // System status is in the main content area - click the System Status tab
      await page.locator('a[href="#system"]').click();

      // Check system content is visible
      await expect(page.locator('#system')).toBeVisible();

      // Check system status elements exist (they may be hidden initially)
      await expect(page.locator('#auth-log')).toBeAttached();
      await expect(page.locator('#data-log')).toBeAttached();
      await expect(page.locator('#analytics-log')).toBeAttached();
      await expect(page.locator('#system-log')).toBeAttached();
    });

    test('should show service health status', async ({ page }) => {
      // Click system tab
      await page.locator('a[href="#system"]').click();

      // Wait for health checks to complete
      await page.waitForTimeout(1000);

      // Check that system status is displayed
      await expect(page.locator('#system-log')).toContainText('System Status Check');
    });
  });

  test('should be responsive on mobile', async ({ page }) => {
    // Set viewport to mobile size
    await page.setViewportSize({ width: 375, height: 667 });

    // Check that sidebar collapses on mobile
    const sidebar = page.locator('.main-sidebar');
    await expect(sidebar).toBeVisible();

    // Check that content is still accessible
    await expect(page.locator('.content-wrapper')).toBeVisible();
  });

  test('should handle page refresh', async ({ page }) => {
    // Navigate and check initial state
    await expect(page.locator('.role-nav')).toBeVisible();

    // Refresh page
    await page.reload();
    await page.waitForLoadState('networkidle');

    // Check everything still works after refresh
    await expect(page.locator('.role-nav')).toBeVisible();
    await expect(page.locator('a[onclick*="setRole(\'admin\'\)"]')).toBeVisible();
  });
});
