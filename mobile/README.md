# Vampire OS Mobile Portal

A static, responsive Progressive Web App companion for Android and iOS browsers.

## Local preview

From the repository root, run a local static HTTP server:

```sh
python3 -m http.server 8000
```

Open `http://localhost:8000/mobile/`. Service workers require HTTPS or localhost.

## Deployment

Publish the `mobile/` directory on an HTTPS static host. GitHub Pages can publish this folder through a Pages workflow or a configured deployment branch. The portal links to the repository Releases page and does not invent or mirror release artifacts.

## Scope and safety

This is not a native Android build, iOS application, or phone-bootable OS image. The service worker caches only an explicit allowlist of same-origin static GET assets (HTML, CSS, JavaScript, manifest and icon). Requests with query strings, other paths, non-GET methods and external origins are not intercepted. It does not cache credentials or privileged API responses. Review the compatibility and platform limits in [Mobile Support](../docs/MOBILE-SUPPORT.md).
