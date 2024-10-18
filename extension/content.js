// Function to wait for an element to be present in the DOM
function waitForElement(selector, timeout = 10000) {
  return new Promise((resolve, reject) => {
    const interval = 100; // Check every 100ms
    let elapsedTime = 0;

    const checkExist = setInterval(() => {
      const element = document.querySelector(selector);
      if (element) {
        clearInterval(checkExist);
        resolve(element);
      }
      elapsedTime += interval;
      if (elapsedTime >= timeout) {
        clearInterval(checkExist);
        reject(new Error(`Element ${selector} not found within ${timeout}ms`));
      }
    }, interval);
  });
}

// Main function to perform login and other actions
async function performLogin() {
  try {
    const { username, password } = await new Promise((resolve) => {
      chrome.storage.sync.get(['username', 'password'], (result) => {
        resolve(result);
      });
    });

    // Wait for the username input to be available
    const usernameInput = await waitForElement('#username');
    const passwordInput = await waitForElement('#password');
    const loginButton = await waitForElement('#login');

    // Fill in the username and password
    usernameInput.value = username;
    passwordInput.value = password;

    // Click the login button
    loginButton.click();

    // Wait for the data collection button to be clickable
    const dataCollectionButton = await waitForElement('#product-datacollection .widget-main', 10000);
    dataCollectionButton.click();

    // Wait for the active session confirmation button and click it
    const activeSessionYes = await waitForElement('#baseModal > div > div > div.modal-footer > span > button:nth-child(2)', 10000);
    activeSessionYes.click();

  } catch (error) {
    console.error('Error during login process:', error);
  }
}

// Function to hide elements
async function hideElements() {
  try {
    // Wait for the navbar to be clickable and hide it
    const navbar = await waitForElement('#navbar');
    navbar.style.display = 'none';
  } catch (error) {
    console.log("The navbar did not become clickable within 10 seconds.");
  }

  try {
    // Wait for the header to be clickable and hide it
    const header = await waitForElement('#st-header');
    header.style.display = 'none';
  } catch (error) {
    console.log("The header did not become clickable within 10 seconds.");
  }

  try {
    // Wait for the header spacer to be clickable and hide it
    const headerSpacer = await waitForElement('#st-header-spacer');
    headerSpacer.style.display = 'none';
  } catch (error) {
    console.log("The header spacer did not become clickable within 10 seconds.");
  }

  try {
    // Wait for the footer to be clickable and hide it
    const footer = await waitForElement('.footer');
    footer.style.display = 'none';
  } catch (error) {
    console.log("The footer did not become clickable within 10 seconds.");
  }
}

// Run the performLogin function when the page loads
window.addEventListener('load', performLogin);
