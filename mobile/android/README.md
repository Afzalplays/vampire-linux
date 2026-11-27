# Vampire Mobile Android launcher

This is a native Android HOME-app shell around the shared Vampire Mobile touch UI.

## Build

Install Android SDK platform 35 and Build Tools, then run `gradle :app:assembleDebug` from this directory. CI builds and publishes the debug APK as an Actions artifact.

Install the APK on a test Android device, open **Vampire Mobile**, and select it as the default Home app when Android offers the Home-app picker. Android requires the user to explicitly select the default launcher.

## Included

- Native Android Activity hosts the bundled UI through AndroidX WebViewAssetLoader on a trusted local HTTPS origin; it does not load the UI from a remote website.
- External HTTPS/mail/tel links are handed to Android instead of being loaded into the privileged WebView.
- Microphone access is requested only when the user starts the recorder; Android runtime permission is required and only WebView audio capture is granted.
- Android HOME/DEFAULT intent filters make it selectable as the system launcher.
- Immersive mode hides system bars; a swipe can reveal transient bars.
- The power button calls a narrow JavaScript bridge to return to Android Home.
- Back returns Home when the WebView has no page history.

## Not included yet

This APK is **not a bootable Vampire OS image**. It runs on top of Android and does not replace its kernel, boot chain, vendor firmware, radio stack or recovery. Camera/microphone permissions, telephony, native notifications, app installation, secure lock screen and privileged settings are not integrated. Do not use it as a security boundary or kiosk lock. A true phone image still needs a named, unlockable ARM64 device, its kernel/device tree/firmware and end-to-end boot/recovery validation.
