const { chromium } = require('playwright');

async function debugHomepage() {
  const browser = await chromium.launch({ headless: false });
  
  // Use existing student storage state
  const context = await browser.newContext({ 
    storageState: require.resolve('../storageStates/student.json'),
    baseURL: 'http://localhost:3000'
  });
  const page = await context.newPage();
  
  await page.goto('/homepage');
  
  // Wait a bit for the page to load
  await page.waitForTimeout(3000);
  
  // Get all h1 elements
  const h1Elements = await page.locator('h1').all();
  console.log(`Found ${h1Elements.length} h1 elements:`);
  
  for (let i = 0; i < h1Elements.length; i++) {
    const text = await h1Elements[i].textContent();
    const classes = await h1Elements[i].getAttribute('class');
    console.log(`H1 ${i + 1}: Text="${text}", Classes="${classes}"`);
  }
  
  // Get all elements containing "Welcome"
  const welcomeElements = await page.locator('text=/Welcome/').all();
  console.log(`\nFound ${welcomeElements.length} elements containing "Welcome":`);
  
  for (let i = 0; i < welcomeElements.length; i++) {
    const tagName = await welcomeElements[i].evaluate(el => el.tagName);
    const text = await welcomeElements[i].textContent();
    const classes = await welcomeElements[i].getAttribute('class');
    console.log(`Welcome ${i + 1}: Tag="${tagName}", Text="${text}", Classes="${classes}"`);
  }
  
  await browser.close();
}

debugHomepage().catch(console.error);