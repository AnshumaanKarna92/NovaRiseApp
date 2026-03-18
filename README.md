# SchoolApp

SchoolApp is a Firebase-centered school management MVP for parents, teachers, admins, and cash collectors.

## Workspace layout

- `apps/mobile`: Flutter mobile app scaffold
- `apps/admin-web`: deferred admin dashboard placeholder
- `backend/functions`: Firebase Cloud Functions backend
- `firebase`: Firebase rules, indexes, and project config
- `docs`: implementation contracts and rollout notes

## Quick start

### Mobile

1. Install Flutter stable.
2. Open `apps/mobile`.
3. Run `flutter pub get`.
4. Add your `firebase_options.dart` and platform folders.
5. Run `flutter run`.

### Backend

1. Install Node.js 20+ and Firebase CLI.
2. Open `backend/functions`.
3. Run `npm install`.
4. Run `npm run build`.

## Status

This repository is a structured MVP scaffold implementing:

- Firebase data model and security baseline
- Callable Cloud Functions for fees, attendance, notices, messaging, imports, and dashboard summaries
- Flutter role-based app shell and feature skeletons
- Project docs, CI workflow, and deployment placeholders
