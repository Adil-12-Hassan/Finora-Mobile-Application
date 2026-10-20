# Finora

Finora is a Flutter personal-finance app for tracking expenses, managing budgets,
and viewing spending summaries.

## Requirements

- Flutter SDK compatible with the Dart SDK constraint in `pubspec.yaml`
- An available Flutter target, such as an Android emulator, connected device, or
  Chrome
- Access to the Finora API, or a locally running backend

## Setup

Install the Flutter dependencies:

```sh
flutter pub get
```

Run the app on a connected device:

```sh
flutter run
```

To run in Chrome:

```sh
flutter run -d chrome
```

## API configuration

The API base URL is configured in
[`lib/core/constants/api.constants.dart`](lib/core/constants/api.constants.dart).
The app currently uses the deployed API:

```text
https://finoraserver.vercel.app/api
```

Service paths are appended to this base URL. For example, dashboard data is
requested from `/dashboard/summary`.

To use a different backend, update `ApiConstants.baseUrl`. Do not add credentials,
private keys, or other secrets to the Flutter app; values bundled into a client
application can be extracted.

### Browser CORS and cookies

The web client sends credentialed requests so the browser can send and receive
the authentication cookie. Configure the backend to allow the exact frontend
origin and set `Access-Control-Allow-Credentials: true`. Do not use a wildcard
origin (`*`) with credentials. For local Chrome development, allow the origin
shown by `flutter run -d chrome`, including its port.

The backend source can be maintained and deployed separately from this Flutter
repository. The app only needs the deployed API URL to connect to it.

## Checks

Run the analyzer and widget tests with:

```sh
flutter analyze
flutter test
```

## Project layout

- `lib/core/` - app constants, theme, and utilities
- `lib/models/` - API and application data models
- `lib/providers/` - state management
- `lib/screens/` - app screens and widgets
- `lib/services/` - API service clients
- `test/` - Flutter tests
