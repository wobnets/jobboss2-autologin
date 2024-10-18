chrome.runtime.onInstalled.addListener(() => {
  const defaultUsername = 'USERNAME_PLACEHOLDER';
  const defaultPassword = 'PASSWORD_PLACEHOLDER';

  chrome.storage.sync.set({ username: defaultUsername, password: defaultPassword }, () => {
    console.log("Default credentials set:", { username: defaultUsername, password: defaultPassword });
  });
});
