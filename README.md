# Refetch — Mobile & Desktop App

> Open-source alternative to YC-controlled HN, featuring curated tech news,
> discussions, and community-driven content.

The official **Flutter** client for [Refetch](https://refetch.io) — a modern,
open-source alternative to Hacker News that combines community-driven curation
with AI-powered content discovery. This app brings the Refetch feed, threads,
voting, and notifications to **Android, iOS, macOS, Windows, and Linux**, on top
of the same [Appwrite](https://appwrite.io) backend that powers the web app.

- 🌐 Web app: <https://refetch.io>
- 🧩 Web project & backend: <https://github.com/refetch-io/refetch>

## Features

- 📰 **Curated feed** — Top, New, Show, and Mines tabs with infinite scroll and pull-to-refresh
- 💬 **Threads & comments** — nested discussions with inline replies
- ⬆️ **Voting** — optimistic up/down voting on posts and comments
- ✍️ **Submit** — share links or "Show" posts
- 🔐 **Accounts** — email/password sign in, sign up, and sign out
- 🔔 **Push notifications** — replies to you, your post going live, and a weekly digest, with per-topic opt-in toggles
- 🌗 **Theming** — Material 3 light/dark, Refetch purple branding
- 🖥️ **Cross-platform** — one codebase for mobile and desktop

## Architecture

This is a **hybrid client** that reuses the existing Refetch backend rather than
re-implementing it:

- **Auth** → the Appwrite Dart SDK directly (email/password sessions + short-lived
  JWTs), mirroring the web client.
- **Reads & mutations** (feed, threads, comments, votes, submissions) → the
  existing `refetch.io` REST API, authenticated with the JWT as a Bearer token.
  This keeps behaviour identical to web and inherits backend changes for free.
- **Push** → FCM on Android and **APNS directly on iOS (no Firebase on iOS)** via
  the [`push`](https://pub.dev/packages/push) plugin; device tokens are registered
  as Appwrite Messaging push targets and topics are subscribed client-side.

### Tech stack

- **Flutter** 3.44+ / **Dart** 3.12+
- **Riverpod** (state management), **go_router** (navigation)
- **http** (REST client) + **appwrite** Dart SDK (auth & messaging)
- **push**, **flutter_local_notifications**, **permission_handler** (notifications)
- Plain immutable models (no code-gen)

## Project structure

```
lib/
  core/            # config, networking, Appwrite client, auth/JWT, push, theme, router
  features/
    auth/          # sign in / up, current-user state
    feed/          # Top/New/Show/Mines feed + post cards
    thread/        # post detail + nested comments
    vote/          # optimistic voting
    submit/        # new link / show posts
    profile/       # account + notification settings
    settings/      # per-topic notification toggles
backend/
  functions/       # Appwrite Functions that send push (notify-reply,
                   # notify-published, weekly-digest) — deploy to the Refetch project
docs/              # design specs + push-notifications setup guide
```

## Getting started

Prerequisites: the [Flutter SDK](https://docs.flutter.dev/get-started/install)
(3.44+), and the platform toolchains you intend to target (Android Studio /
Xcode / desktop).

```bash
flutter pub get
flutter run            # pick a device, or e.g. flutter run -d windows
```

The app talks to the production Refetch backend out of the box (Appwrite project
`63ef1792594ff4f50de2`), so the feed works immediately. Signing in requires the
app's platform (`io.appwrite.refetch`) to be registered in the Appwrite console.

### Android release signing

Release builds are signed from `android/key.properties` (gitignored). Copy
`android/key.properties.example`, create a keystore, and fill in the values —
see the example file for the `keytool` command. Without it, release builds fall
back to debug signing.

### Push notifications

Push is disabled until configured (the app still runs). To enable it, follow
[`docs/push-notifications-setup.md`](docs/push-notifications-setup.md): create the
Firebase (Android FCM) and Apple (iOS APNS) credentials, add the Appwrite
Messaging providers and topics, set the provider/topic ids in
`lib/core/config/app_config.dart`, and deploy the functions in
[`backend/`](backend/README.md). Firebase config files and signing secrets are
gitignored and must be supplied locally.

## Platforms

Android · iOS · macOS · Windows · Linux. (The web target is intentionally
unused — that's the existing Next.js app at refetch.io.)

## Contributing

Issues and pull requests are welcome. This repo follows the conventions of the
main [Refetch](https://github.com/refetch-io/refetch) project; please keep
secrets (keystores, `key.properties`, `google-services.json`,
`GoogleService-Info.plist`, `.env`) out of commits — they are gitignored by
default.

## License

MIT — consistent with the [Refetch](https://github.com/refetch-io/refetch)
project.
