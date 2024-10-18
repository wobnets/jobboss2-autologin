// Function to wait for an element to be present in the DOM
function waitForElement(selector, timeout = 10000) {
  return new Promise((resolve, reject) => {
    const interval = 100; // Check every 100ms
    let elapsedTime = 0;

    const checkExist = setInterval(() => {
      const element = document.querySelector(selector);
      if (element) {
        clearInterval(checkExist);
        console.log(`Element found: ${selector}`);
        resolve(element);
      }
      elapsedTime += interval;
      if (elapsedTime >= timeout) {
        clearInterval(checkExist);
        console.error(`Element ${selector} not found within ${timeout}ms`);
        reject(new Error(`Element ${selector} not found within ${timeout}ms`));
      }
    }, interval);
  });
}

// Main function to perform login and other actions
async function performLogin() {
  try {
    console.log("Waiting for username input...");
    const usernameInput = await waitForElement('#username');

    console.log("Waiting for password input...");
    const passwordInput = await waitForElement('#password');

    console.log("Waiting for login button...");
    const loginButton = await waitForElement('#login');

    // Fill in the username and password
    usernameInput.value = 'USERNAME_PLACEHOLDER'; // Placeholder
    passwordInput.value = 'PASSWORD_PLACEHOLDER'; // Placeholder

    console.log("Clicking the login button...");
    loginButton.click();

    // Wait for the data collection button to be clickable
    console.log("Waiting for data collection button...");
    const dataCollectionButton = await waitForElement('#product-datacollection .widget-main', 10000);
    console.log("Clicking the data collection button...");
    dataCollectionButton.click();

    // Wait for the active session confirmation button and click it
    console.log("Waiting for active session confirmation button...");
    const activeSessionYes = await waitForElement('#baseModal > div > div > div.modal-footer > span > button:nth-child(2)', 10000);
    console.log("Clicking the active session confirmation button...");
    activeSessionYes.click();

  } catch (error) {
    console.error('Error during login process:', error);
  }
}

// Function to hide elements
async function hideElements() {
  try {
    console.log("Waiting for navbar...");
    const navbar = await waitForElement('#navbar');
    navbar.style.display = 'none';
    console.log("Navbar hidden.");
  } catch (error) {
    console.log("The navbar did not become clickable within 10 seconds.");
  }

  try {
    console.log("Waiting for header...");
    const header = await waitForElement('#st-header');
    header.style.display = 'none';
    console.log("Header hidden.");
  } catch (error) {
    console.log("The header did not become clickable within 10 seconds.");
  }

  try {
    console.log("Waiting for header spacer...");
    const headerSpacer = await waitForElement('#st-header-spacer');
    headerSpacer.style.display = 'none';
    console.log("Header spacer hidden.");
  } catch (error) {
    console.log("The header spacer did not become clickable within 10 seconds.");
  }

  try {
    console.log("Waiting for footer...");
    const footer = await waitForElement('.footer');
    footer.style.display = 'none';
    console.log("Footer hidden.");
  } catch (error) {
    console.log("The footer did not become clickable within 10 seconds.");
  }
}

// Run the performLogin function when the page loads
window.addEventListener('load', performLogin);
