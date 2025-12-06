import { test, expect } from '@playwright/test';

test('Login successful', async ({ page }) => {
  const user = 'standard_user'
  const pwd = 'secret_sauce'
  const user2 = 'locked_out_user'
  await page.goto('https://www.saucedemo.com/');

  await page.locator('[data-test="username"]').fill('standard_user')
  await page.locator('[data-test="password"]').fill('secret_sauce')
  await page.locator('[data-test="login-button"]').click()

  // Expect a title "to contain" a substring.
  await expect(page.url()).toContain('/inventory.html');
});


