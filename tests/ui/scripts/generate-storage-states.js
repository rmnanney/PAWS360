const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');

async function generateStorageStates() {
  const browser = await chromium.launch({ headless: false });
  
  // Generate student storage state
  console.log('Generating student storage state...');
  const studentContext = await browser.newContext();
  const studentPage = await studentContext.newPage();
  
  await studentPage.goto('http://localhost:3000/login');
  await studentPage.fill('input[name="email"]', 'demo.student@uwm.edu');
  await studentPage.fill('input[name="password"]', 'password');
  await studentPage.click('button[type="submit"]');
  
  // Wait for redirect to homepage
  await studentPage.waitForURL(/\/homepage/, { timeout: 10000 });
  
  // Save storage state
  await studentContext.storageState({ path: path.join(__dirname, '../storageStates/student.json') });
  await studentContext.close();
  
  // Generate admin storage state  
  console.log('Generating admin storage state...');
  const adminContext = await browser.newContext();
  const adminPage = await adminContext.newPage();
  
  await adminPage.goto('http://localhost:3000/login');
  await adminPage.fill('input[name="email"]', 'demo.admin@uwm.edu');
  await adminPage.fill('input[name="password"]', 'password');
  await adminPage.click('button[type="submit"]');
  
  // Wait for redirect to homepage
  await adminPage.waitForURL(/\/homepage/, { timeout: 10000 });
  
  // Save storage state
  await adminContext.storageState({ path: path.join(__dirname, '../storageStates/admin.json') });
  await adminContext.close();
  
  await browser.close();
  console.log('Storage states generated successfully!');
}

generateStorageStates().catch(console.error);