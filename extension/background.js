chrome.runtime.onInstalled.addListener(() => {
  const defaultUsername = 'USERNAME_PLACEHOLDER';
  const defaultPassword = 'PASSWORD_PLACEHOLDER';

  chrome.storage.local.set({ username: defaultUsername, password: defaultPassword }, () => {
    console.log("Default credentials set");
  });
});
