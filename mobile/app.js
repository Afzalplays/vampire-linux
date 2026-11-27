const installButton = document.querySelector("#install-button");
const installStatus = document.querySelector("#install-status");
let installPrompt = null;

function setInstallStatus(message) {
  if (installStatus) installStatus.textContent = message;
}

function updateConnectionStatus() {
  const connectionStatus = document.querySelector("#connection-status");
  if (!connectionStatus) return;
  connectionStatus.textContent = navigator.onLine
    ? "Connection: online. The portal can refresh project links and release information."
    : "Connection: offline. Only previously cached portal pages and assets are available; external project links need a connection.";
}

window.addEventListener("online", updateConnectionStatus);
window.addEventListener("offline", updateConnectionStatus);
updateConnectionStatus();

function isStandalone() {
  return window.matchMedia("(display-mode: standalone)").matches ||
    navigator.standalone === true;
}

function isAppleMobileDevice() {
  return /iPhone|iPad|iPod/.test(navigator.userAgent) ||
    (navigator.platform === "MacIntel" && navigator.maxTouchPoints > 1);
}

if (isStandalone()) {
  setInstallStatus("Vampire OS is installed on this device.");
} else if (isAppleMobileDevice()) {
  setInstallStatus("To install on iPhone or iPad: open this page in Safari, tap Share, then Add to Home Screen.");
} else {
  setInstallStatus("If no Install button appears, open your browser menu and choose Install app or Add to Home Screen.");
}

window.addEventListener("beforeinstallprompt", event => {
  event.preventDefault();
  installPrompt = event;
  if (installButton) installButton.hidden = false;
  setInstallStatus("Vampire OS can be installed on this device.");
});

if (installButton) {
  installButton.addEventListener("click", async () => {
    if (!installPrompt) return;
    const promptEvent = installPrompt;
    installPrompt = null;
    installButton.disabled = true;
    try {
      await promptEvent.prompt();
      const choice = await promptEvent.userChoice;
      setInstallStatus(choice.outcome === "accepted"
        ? "Installation accepted. Vampire OS will appear on your Home Screen."
        : "Installation was cancelled. You can install later from the browser menu.");
    } catch {
      setInstallStatus("The browser could not complete installation. Use its menu to add this page to your Home Screen.");
    } finally {
      installButton.hidden = true;
      installButton.disabled = false;
    }
  });
}

window.addEventListener("appinstalled", () => {
  setInstallStatus("Vampire OS launcher installed.");
  if (installButton) installButton.hidden = true;
});

if ("serviceWorker" in navigator && location.protocol !== "file:") {
  window.addEventListener("load", () => {
    navigator.serviceWorker.register("./sw.js").catch(() => {
      setInstallStatus("Offline support could not be enabled in this browser. The portal still works online.");
    });
  });
}
