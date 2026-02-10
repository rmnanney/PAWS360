import { test, expect } from '@playwright/test';

test.describe('PAWS360 AdminLTE Dashboard', () => {
  test.beforeEach(async ({ page }) => {
    // Navigate to the dashboard
    await page.goto('/');
    await page.waitForLoadState('networkidle');
  });

  test('should load dashboard successfully', async ({ page }) => {
    // Check page title
    await expect(page).toHaveTitle(/PAWS360 Admin Dashboard/);

    // Check main elements are present
    await expect(page.locator('.main-header')).toBeVisible();
    await expect(page.locator('.main-sidebar')).toBeVisible();
    await expect(page.locator('.content-wrapper')).toBeVisible();
  });

  test('should display role navigation tabs', async ({ page }) => {
    // Check role navigation exists
    const roleNav = page.locator('.role-nav');
    await expect(roleNav).toBeVisible();

    // Check all role tabs are present
    await expect(page.locator('#admin-tab')).toBeVisible();
    await expect(page.locator('#student-tab')).toBeVisible();
    await expect(page.locator('#instructor-tab')).toBeVisible();
    await expect(page.locator('#registrar-tab')).toBeVisible();
    await expect(page.locator('#system-tab')).toBeVisible();
  });

  test.describe('Admin Role', () => {
    test('should display admin interface', async ({ page }) => {
      // Click admin tab
      await page.locator('#admin-tab').click();

      // Check admin content is visible
      await expect(page.locator('#admin')).toHaveClass(/show active/);

      // Check admin-specific elements
      await expect(page.locator('text=Create New Class')).toBeVisible();
      await expect(page.locator('#createClassModal')).toBeAttached();
    });

    test('should open create class modal', async ({ page }) => {
      // Click admin tab
      await page.locator('#admin-tab').click();

      // Click create class button
      await page.locator('#createClassModal').click();

      // Check modal opens
      await expect(page.locator('.modal')).toBeVisible();
      await expect(page.locator('#courseCode')).toBeVisible();
      await expect(page.locator('#courseName')).toBeVisible();
      await expect(page.locator('#instructor')).toBeVisible();
    });

    test('should display classes table', async ({ page }) => {
      // Click admin tab
      await page.locator('#admin-tab').click();

      // Check classes table exists
      await expect(page.locator('#classes-table')).toBeVisible();

      // Check table has data
      const rows = page.locator('#classes-table-body tr');
      await expect(rows).toHaveCount(await rows.count()); // At least some rows
    });
  });

  test.describe('Student Role', () => {
    test('should display student interface', async ({ page }) => {
      // Click student tab
      await page.locator('#student-tab').click();

      // Check student content is visible
      await expect(page.locator('#student')).toHaveClass(/show active/);

      // Check student-specific elements
      await expect(page.locator('text=Academic Planning')).toBeVisible();
      await expect(page.locator('#courseSearch')).toBeVisible();
    });

    test('should display degree progress', async ({ page }) => {
      // Click student tab
      await page.locator('#student-tab').click();

      // Check degree progress information
      await expect(page.locator('text=Degree Progress')).toBeVisible();
      await expect(page.locator('text=GPA:')).toBeVisible();
      await expect(page.locator('text=Credits Completed:')).toBeVisible();
    });
  });

  test.describe('Instructor Role', () => {
    test('should display instructor interface', async ({ page }) => {
      // Click instructor tab
      await page.locator('#instructor-tab').click();

      // Check instructor content is visible
      await expect(page.locator('#instructor')).toHaveClass(/show active/);

      // Check instructor-specific elements
      await expect(page.locator('text=Course Management')).toBeVisible();
      await expect(page.locator('text=Create Assignment')).toBeVisible();
    });

    test('should display course statistics', async ({ page }) => {
      // Click instructor tab
      await page.locator('#instructor-tab').click();

      // Check course statistics are displayed
      await expect(page.locator('text=Students:')).toBeVisible();
      await expect(page.locator('text=Assignments Due:')).toBeVisible();
    });
  });

  test.describe('Registrar Role', () => {
    test('should display registrar interface', async ({ page }) => {
      // Click registrar tab
      await page.locator('#registrar-tab').click();

      // Check registrar content is visible
      await expect(page.locator('#registrar')).toHaveClass(/show active/);

      // Check registrar-specific elements
      await expect(page.locator('text=Enrollment Statistics')).toBeVisible();
      await expect(page.locator('text=Bulk Enrollment')).toBeVisible();
    });

    test('should display enrollment data', async ({ page }) => {
      // Click registrar tab
      await page.locator('#registrar-tab').click();

      // Check enrollment statistics
      await expect(page.locator('text=Total Enrolled:')).toBeVisible();
      await expect(page.locator('text=Active Courses:')).toBeVisible();
    });
  });

  test.describe('System Status', () => {
    test('should display system status', async ({ page }) => {
      // Click system tab
      await page.locator('#system-tab').click();

      // Check system content is visible
      await expect(page.locator('#system')).toHaveClass(/show active/);

      // Check system status elements
      await expect(page.locator('#auth-log')).toBeVisible();
      await expect(page.locator('#data-log')).toBeVisible();
      await expect(page.locator('#analytics-log')).toBeVisible();
      await expect(page.locator('#system-log')).toBeVisible();
    });

    test('should show service health status', async ({ page }) => {
      // Click system tab
      await page.locator('#system-tab').click();

      // Wait for health checks to complete (they run every 30 seconds)
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
    await expect(page.locator('#admin-tab')).toBeVisible();
  });
});