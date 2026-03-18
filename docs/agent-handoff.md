# SchoolApp Agent Handoff

## Purpose
This document captures the current implementation state of the `Nova_Rise_App` / `SchoolApp` project so another agent can continue quickly without re-discovering the current architecture, fixes, and demo assumptions.

## Active App Location
- The currently active Flutter app is the root app under [lib](c:/Users/Anshumaan%20Karna/Nova_Rise_App/lib), not `apps/mobile/`.
- The user is actively running and testing the root Flutter app.
- Firebase Functions code is under [functions/src](c:/Users/Anshumaan%20Karna/Nova_Rise_App/functions/src).

## Current Goal State
- The app is now usable for a professor demo.
- Primary emphasis was shifted from strict backend completeness to demo reliability.
- Demo mode is intentionally supported across roles so the app remains presentable even if Firebase profile bootstrap or backend workflows fail.

## What Is Implemented

### Auth and Session
- Phone OTP sign-in exists.
- Demo session entry exists for:
  - Parent
  - Teacher
  - Admin
- If Firebase auth succeeds but the `users/{uid}` Firestore profile is missing, the app no longer hard-blocks.
- Missing user profiles are handled via provisional/demo-safe behavior.

Relevant files:
- [auth_service.dart](c:/Users/Anshumaan%20Karna/Nova_Rise_App/lib/core/services/auth_service.dart)
- [session_controller.dart](c:/Users/Anshumaan%20Karna/Nova_Rise_App/lib/features/auth/presentation/controllers/session_controller.dart)
- [sign_in_screen.dart](c:/Users/Anshumaan%20Karna/Nova_Rise_App/lib/features/auth/presentation/screens/sign_in_screen.dart)
- [auth_gate_screen.dart](c:/Users/Anshumaan%20Karna/Nova_Rise_App/lib/features/auth/presentation/screens/auth_gate_screen.dart)

### Demo / Provisional Data
- Provisional users receive sample data instead of blank screens.
- Demo data currently covers:
  - Students
  - Fee invoices
  - Notices
  - Messages
  - Attendance summaries
  - Pending fee payments
  - Import jobs

Relevant file:
- [school_data_service.dart](c:/Users/Anshumaan%20Karna/Nova_Rise_App/lib/core/services/school_data_service.dart)

### Role-Based Home and Navigation
- Home/dashboard adapts by role.
- Role-switching buttons are available in provisional/demo mode.
- Role-specific quick navigation cards exist for parent, teacher, and admin.

Relevant file:
- [auth_gate_screen.dart](c:/Users/Anshumaan%20Karna/Nova_Rise_App/lib/features/auth/presentation/screens/auth_gate_screen.dart)

### UI Improvements Applied
- Shared visual components added:
  - `ScreenIntroCard`
  - `MiniStatCard`
  - `StatusChip`
- Global theme improved for a cleaner demo-ready look.
- Feature cards upgraded from plain list tiles to more deliberate cards.
- Main screens visually upgraded:
  - Fees
  - Attendance
  - Messages
  - Notices
  - Students
  - Profile
  - Admin Tools

Relevant files:
- [app_theme.dart](c:/Users/Anshumaan%20Karna/Nova_Rise_App/lib/core/theme/app_theme.dart)
- [app_surface.dart](c:/Users/Anshumaan%20Karna/Nova_Rise_App/lib/shared/widgets/app_surface.dart)
- [feature_card.dart](c:/Users/Anshumaan%20Karna/Nova_Rise_App/lib/shared/widgets/feature_card.dart)
- [fees_screen.dart](c:/Users/Anshumaan%20Karna/Nova_Rise_App/lib/features/fees/presentation/screens/fees_screen.dart)
- [attendance_screen.dart](c:/Users/Anshumaan%20Karna/Nova_Rise_App/lib/features/attendance/presentation/screens/attendance_screen.dart)
- [messages_screen.dart](c:/Users/Anshumaan%20Karna/Nova_Rise_App/lib/features/messages/presentation/screens/messages_screen.dart)
- [notices_screen.dart](c:/Users/Anshumaan%20Karna/Nova_Rise_App/lib/features/notices/presentation/screens/notices_screen.dart)
- [students_screen.dart](c:/Users/Anshumaan%20Karna/Nova_Rise_App/lib/features/students/presentation/screens/students_screen.dart)
- [profile_screen.dart](c:/Users/Anshumaan%20Karna/Nova_Rise_App/lib/features/profile/presentation/screens/profile_screen.dart)
- [admin_tools_screen.dart](c:/Users/Anshumaan%20Karna/Nova_Rise_App/lib/features/admin_tools/presentation/screens/admin_tools_screen.dart)

## Critical Auth / Backend Context

### Main Historical Issue
The major blocker was repeated failure in profile bootstrap after OTP sign-in:
- `firebase_functions/unauthenticated`
- `NOT_FOUND`
- Cloud Run ingress / callable auth inconsistency around `ensureUserProfile`

### Current Strategy
The app should not depend on `ensureUserProfile` for basic usability.

Implemented mitigations:
- Retry + fallback behavior in auth service
- Provisional profile generation in session layer
- Demo-safe data feeds in `SchoolDataService`
- Sign-in no longer traps the user on a dead-end error screen

### Important Caveat
Backend callable/profile bootstrap is still not fully trustworthy as a production path.
For demo purposes, use demo role entry first unless specifically testing live OTP.

## Feature Modules: Current Practical Status

### Fees
- Fee list UI is working.
- Parent upload receipt flow UI exists.
- Pending/demo invoice states are visible.
- Admin fee review UI exists.
- Backend submission/verification services exist, but live success depends on Firebase/backend correctness.

### Attendance
- Teacher/admin attendance screen exists.
- Mark-all-present UX exists.
- Update flow UI exists.
- Demo attendance history is available.
- Live callable path depends on backend.

### Notices
- Notice feed UI exists.
- Admin publish notice sheet exists.
- Demo notices are available.
- Live publish depends on backend.

### Messages
- Message/homework feed UI exists.
- Teacher/admin compose sheet exists.
- Demo messages are available.
- Live publish depends on backend.

### Students / Profile / Admin Tools
- Student roster UI is functional.
- Profile screen is functional.
- Admin Tools screen is functional with demo summaries, pending payments, and import job visibility.
- CSV import UI trigger exists, but real upload behavior depends on backend and storage configuration.

## Firebase / Rules Notes
- Firestore rules were previously adjusted to allow one-time self-create of `users/{uid}` as `parent`.
- Firebase callable deployment was attempted multiple times.
- The current app experience intentionally avoids depending on that path.

Files to inspect if backend continuation is needed:
- [functions/src/index.ts](c:/Users/Anshumaan%20Karna/Nova_Rise_App/functions/src/index.ts)
- [firestore.rules](c:/Users/Anshumaan%20Karna/Nova_Rise_App/firestore.rules)
- [firebase/firestore.rules](c:/Users/Anshumaan%20Karna/Nova_Rise_App/firebase/firestore.rules)

## Verification Status
- `flutter analyze lib test` passed after the latest UI changes.
- `flutter test` passed after the latest UI changes.
- Updated debug APK was installed on `emulator-5554`.
- App was launched successfully after install.

## How To Run

Preferred local commands:

```powershell
tools\flutter\bin\flutter.bat pub get
tools\flutter\bin\flutter.bat analyze lib test
tools\flutter\bin\flutter.bat test
tools\flutter\bin\flutter.bat install --debug -d emulator-5554
```

Stable run helper:
- [run_android_stable.ps1](c:/Users/Anshumaan%20Karna/Nova_Rise_App/tools/run_android_stable.ps1)

## Recommended Demo Flow
For a reliable presentation:
1. Open app.
2. Use `Parent Demo`.
3. Show fees, notices, messages, profile.
4. Sign out or role switch.
5. Use `Teacher Demo`.
6. Show attendance, students, messages.
7. Sign out or role switch.
8. Use `Admin Demo`.
9. Show admin tools, imports, pending fees, notices.

## Immediate Next Steps For Another Agent

### Highest Value
- Continue turning demo-safe screens into richer end-to-end flows.
- Improve polish consistency across all forms and bottom sheets.
- Add a stronger home/dashboard summary for each role if desired.

### Backend Continuation
- Revisit `ensureUserProfile` and callable auth behavior in Firebase Functions.
- Validate function region, auth context, and callable deployment consistency.
- Test all write flows against emulator and live Firebase separately.

### Product Completion
- Finish backend-backed mutation reliability for:
  - Fee receipt submission
  - Fee verification
  - Attendance submit/update
  - Notice publish
  - Message/homework publish
  - CSV import
- Add clearer success/error UX for backend-dependent actions.
- Add better offline/queued mutation behavior if MVP completion is still required.

## Known Project Reality
- The app is not fully production-complete.
- It is substantially more demo-ready than before.
- The current implementation deliberately prioritizes:
  - Presentability
  - Role-based walkthroughs
  - Non-blocking auth experience
  - Stable Android demo behavior

## Suggested Starting Files For The Next Agent
- [auth_gate_screen.dart](c:/Users/Anshumaan%20Karna/Nova_Rise_App/lib/features/auth/presentation/screens/auth_gate_screen.dart)
- [sign_in_screen.dart](c:/Users/Anshumaan%20Karna/Nova_Rise_App/lib/features/auth/presentation/screens/sign_in_screen.dart)
- [school_data_service.dart](c:/Users/Anshumaan%20Karna/Nova_Rise_App/lib/core/services/school_data_service.dart)
- [session_controller.dart](c:/Users/Anshumaan%20Karna/Nova_Rise_App/lib/features/auth/presentation/controllers/session_controller.dart)
- [functions/src/index.ts](c:/Users/Anshumaan%20Karna/Nova_Rise_App/functions/src/index.ts)
