chrome.runtime.onInstalled.addListener(() => {
  // Set default values for username and password
  chrome.storage.sync.set({ username: 'USERNAME_PLACEHOLDER', password: 'PASSWORD_PLACEHOLDER' }, () => {
    console.log("Default credentials set.");
  });
});
