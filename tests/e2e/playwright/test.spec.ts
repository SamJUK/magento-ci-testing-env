import { test } from '@playwright/test';

test('homepage loads correctly', async ({ page }) => {
    await page.goto('/');
    await page.waitForResponse(response => response.status() === 200);
    await page.getByRole('heading', { name: 'Home Page' }).isVisible();
});