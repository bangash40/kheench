# Kheench

**Save anything you can watch.**

Kheench is an all-in-one media saver for Android. Paste or share a link from almost any site, see every quality and format available, and download the one you want. It also saves WhatsApp statuses, stories, reels, Instagram photos and profile pictures, and can split long videos into WhatsApp-status-length parts.

Everything runs on the phone: no server, no accounts on a backend, no analytics, no paid services.

> Personal-use app, distributed as a sideloaded APK. It is not published on Google Play.

## Features

| Feature | Status |
|---|---|
| App shell: theme (light/dark/system), animated splash, bottom navigation | Done |
| Home, Status, Downloads, Tools and Settings screens (layout) | Done |
| Bundled download engine (yt-dlp + FFmpeg) with version shown and in-app update | Done |
| Paste a link → preview → pick from every video/audio quality, with clear error messages | Done |
| Background downloads with notification progress and cancel, saved to `Movies/Kheench` and `Music/Kheench` | Done |
| Downloads screen: live queue, pause, cancel, retry, parallel limit and history | Planned |
| Share links to Kheench from other apps, clipboard link detection | Planned |
| WhatsApp and WhatsApp Business status saver (videos and photos) | Planned |
| Settings: default quality, audio format, parallel downloads | Planned |
| Logged-in downloads (Instagram, Facebook, X, TikTok) using your own account | Planned |
| Stories and highlights, Instagram carousel photos, full-size profile pictures | Planned |
| Status splitter: cut long videos into status-length parts and share them in order | Planned |

## Tech stack

- **Flutter** (Dart 3) for the UI
- **Riverpod** for state, **go_router** for navigation
- **Kotlin** native layer on Android, talking to Flutter over a `MethodChannel` (`kheench/engine`) and an `EventChannel` for progress (`kheench/progress`)
- **WorkManager** foreground workers run downloads in the background; **MediaStore** publishes finished files to shared storage
- **yt-dlp + FFmpeg** via [`youtubedl-android`](https://github.com/JunkFood02/youtubedl-android), bundled in the APK and updatable from Settings
- Planned native pieces: status folder access and video splitting
- Fonts: **Bricolage Grotesque** (display) and **DM Sans** (body), bundled in the app so nothing is fetched at runtime

## Requirements

- Android 7.0 (API 24) or newer
- Flutter 3.47+ / Dart 3.13+ to build

## Getting started

```bash
git clone https://github.com/bangash40/kheench.git
cd kheench
flutter pub get
flutter run            # with an Android phone connected over USB
```

Build a release APK:

```bash
flutter build apk --release --split-per-abi
```

Run checks:

```bash
flutter analyze
flutter test
```

## Project structure

```
lib/
  app/          theme, router, navigation shell, splash, motion helpers
  engine/       native engine bridge, yt-dlp format parsing, error messages
  features/
    link/       home screen, link preview and the quality picker sheet
    downloads/  download queue and history
    status/     WhatsApp status saver
    tools/      splitter, Instagram photos, stories, profile pictures, accounts
    settings/   app settings
  widgets/      shared widgets and the Kheench logo mark
test/           unit and widget tests; fixtures/ holds trimmed yt-dlp JSON samples
assets/fonts/   bundled font files
android/        Android app, launcher icon, launch screen, Kotlin engine bridge and download worker
```

## Privacy

- No analytics and no tracking.
- Network requests go only to the sites you download from, plus GitHub when you tap "Update" on the download engine (new yt-dlp releases are published there).
- Account logins (when added) use the platform's own login page; Kheench never sees or stores your password, and saved sessions stay in the app's private storage.

## Responsible use

Downloads are meant for personal use. Many platforms' terms restrict downloading, and re-sharing other people's content can infringe copyright. Kheench only accesses content your own account can already see and never tries to bypass privacy settings.

## License

Private project. All rights reserved.

Fonts are licensed under the [SIL Open Font License](https://openfontlicense.org).
