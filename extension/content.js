// Auto Login JobBoss2
const username = "shop5"; // Replace with your username
const password = "floor123"; // Replace with your password
const timeout = 1000; // Polling interval

window.addEventListener("load", function() {
  console.log("Window loaded");

  const usernameField = document.getElementById("username");
  const passwordField = document.getElementById("password");
  const loginButton = document.getElementById("login");
  const dataCollectionIcon = document.getElementById("product-datacollection");

  const observeDataCollection = () => {
    if (dataCollectionIcon) {
      const terminalNumber = document.getElementById("terminal");
      if (terminalNumber) {
        terminalNumber.value = "70"; // Set terminal number
      }

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
