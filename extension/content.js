// Auto Login JobBoss2
const username = "shop5"; // Replace with your username
const password = "floor123"; // Replace with your password
const timeout = 1000; // Polling interval

window.addEventListener("load", function() {
  console.log("Window loaded");

  // Check if the current URL includes "DataCollection"
  if (window.location.href.includes("DataCollection")) {
    removeBars();
  }

  const usernameField = document.getElementById("username");
  const passwordField = document.getElementById("password");
  const loginButton = document.getElementById("login");
  const dataCollectionIcon = document.getElementById("product-datacollection");

  const observeDataCollection = () => {
    if (dataCollectionIcon) {

      const dataCollectionBtn = dataCollectionIcon.querySelector("a");
      if (dataCollectionBtn) {
        console.log("Data collection button found");
        dataCollectionBtn.click();
        setTimeout(observeSessionYesNo, timeout); // Check for session confirmation
      }
    } else {
      setTimeout(observeDataCollection, timeout); // Retry if not found
    }
  };

  const observeSessionYesNo = () => {
    const options = document.getElementsByClassName("st-modal-optiontext");
    if (options.length > 0) {
      console.log("Options found");
      for (let option of options) {
        if (option.textContent === "Yes") {
          console.log("Session 'Yes' button found");
          option.click(); // Click the "Yes" option
          return; // Exit after clicking
        }
      }
    }
    setTimeout(observeSessionYesNo, timeout); // Retry if not found
  };

  const login = () => {
    console.log("Logging in");
    if (usernameField && passwordField) {
      usernameField.value = username;
      passwordField.value = password;
      loginButton.click();
      setTimeout(observeDataCollection, timeout); // Start observing data collection
    }
  };

  // Start the login process after a short delay
  setTimeout(login, timeout);
});

// Function to remove bars
function removeBars() {
  console.log("Removing top and bottom bars...");
  const topBar = document.getElementById("navbar");
  const bottomBar = document.getElementsByClassName("footer")[0];
  const mainContainer = document.getElementById("main-container");

  if (topBar) {
    topBar.style.display = "none";
    console.log("Top bar removed.");
  }
  if (bottomBar) {
    bottomBar.style.display = "none";
    console.log("Bottom bar removed.");
  }
  if (mainContainer) {
    mainContainer.style.paddingTop = "0";
    console.log("Main container padding adjusted.");
  }
}
