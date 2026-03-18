# SchoolApp — Specifications & Feature Document

**Version:** 1.0

**Author:** (Your Name) / Team

**Date:** 2026-03-11

---

## 1. Overview

This document specifies the complete functional and non-functional requirements for the **SchoolApp** — a lightweight school management mobile application (Flutter) with a Firebase backend. The initial target user base is a recently founded village school (~700–800 students) and their parents, teachers, and administrators.

Primary goals:
- Provide a simple, reliable way to **collect fees** (digital + manual/cash recording).
- Deliver a **noticeboard & class communication** channel for teachers and admin.
- Provide a quick **attendance** workflow and notify parents of absences.
- Keep the UI minimal and accessible for low-tech users.

Scope: MVP features (Phase 1) + recommended Phase 2 features and roadmap.

---

## 2. Stakeholders

- School Principal / Admin
- Class Teachers
- Parents (primary users for fee and notices)
- Students (secondary — through parent account)
- Bus Driver / Transport Staff (future)
- Developer / Deployment Team

---

## 3. Assumptions & Constraints

- Not all parents will have smartphones; some pay cash at school. System must support manual/cash records.
- Internet connectivity can be intermittent for some parents; app should handle offline or provide SMS fallback for critical notices.
- Payment verification via screenshot will be manual for MVP; later integrate UPI/payment gateway for automatic verification.
- Target platforms: Android (Play Store) first; iOS later (optional).

---

## 4. Success Metrics

- 80% of fee transactions recorded digitally (screenshot or gateway) within 3 months.
- Teacher adoption: 90% of class teachers use attendance module daily within 1 month.
- Reduction in missed fee payments by 50% after automated reminders.

---

## 5. Roles & Permissions

**Roles:**
- `admin` — full access: manage students, teachers, classes, verify fees, post notices, generate reports.
- `teacher` — manage classes assigned, mark attendance, post homework/messages for their class, upload documents.
- `parent` — view child's profile, pay fees (upload screenshot), view notices, receive notifications, view attendance/homework.
- `cash_collector` (optional) — mobile account or admin sub-role to enter cash payments with collector ID.

**Permissions matrix (high-level):**
- Admin: CRUD on all resources.
- Teacher: CRUD on messages/homework/attendance for own classes; read student basic info for their class.
- Parent: Read-only for notices/homework/attendance/fees for their child; write: upload fee screenshot or confirm cash payment details.

---

## 6. User Journeys / Workflows (detailed)

### 6.1 Fee Payment (MVP)

**Parent flow:**
1. Parent opens `Fees` screen.
2. The app shows outstanding invoices (invoice id, amount, due date, description).
3. Parent clicks `Pay` → app shows a QR code with school's UPI VPA and optionally prefilled amount (UPI deep link).
4. Parent pays using any UPI app.
5. After payment, parent taps `Upload Receipt` and attaches screenshot (photo or gallery).
6. Parent submits the receipt; the fee record moves to `Pending Verification`.
7. App shows pending state and sends push notification to admin.

**Admin flow:**
1. Admin logs into Admin Dashboard (mobile or web).
2. In `Fees Verification`, admin sees pending entries with uploaded screenshot and metadata (time, uploader, parent phone).
3. Admin inspects screenshot and bank transaction details (if visible) and marks `Verified` or `Rejected` with optional notes.
4. If verified, student's fee status is set to `Paid` and receipts saved (storage path). Parent receives push notification and invoice updated.

**Manual cash handling:**
- Cash collector brings daily list to admin.
- Admin or `cash_collector` user selects `Record Cash Payment`, chooses student(s), records amount, payment date, collector name, and optionally attaches a scanned receipt or photo.
- Cash payments are recorded in the same `fees` collection with `payment_method: cash` and `verified: true` by default (or admin can manually verify later).

**Fraud considerations:**
- Screenshots can be forged; human verification is required for MVP.
- Later upgrade: integrate a payment gateway (Razorpay/PayU/Stripe India) for server-side verified payments.


### 6.2 Attendance

**Teacher flow:**
1. Teacher opens `Attendance` → selects class.
2. App preloads class student list (from Firestore) with checkboxes.
3. Teacher taps `Mark All Present` or manually toggles absentees and submits.
4. On submit, absent records are saved to `attendance` collection with `date`, `marked_by`, and timestamps.
5. System triggers push notifications to parents of absent students: "Your child Priya was marked absent today (11-Mar-2026)".

**Edge cases:**
- Allow editing attendance for the same day only by teacher or admin.
- Late edits should be logged (audit trail).


### 6.3 Notice Board (Admin)

**Admin posts notice:**
1. Title, text, optional attachment (PDF/JPG), start date, expiry date, target audience (all or specific classes).
2. Notice is written to `notices` collection and notifications are pushed by target audience.

**Parent view:**
- Notices appear on home screen sorted by date; unread badges shown.
- Notices can be downloaded or marked as read.


### 6.4 Class Messaging & Homework (Teacher → Class)

**Teacher:** create message or upload document (PDF/image) for own class only. Message has optional due date (homework). The message goes to `messages` or `homework` collection with `class_id` and `teacher_id`.

**Parent:** receive push notification and can view message; no direct reply in MVP (one-way). For two-way, allow `acknowledge` button or comment in later versions.


### 6.5 Student Management & Class Assignment

- Admin uploads student list via CSV/Excel import (fields: student_id, name, date_of_birth, class_id, parent_name, parent_phone, address).
- Admin assigns students to classes; a class has fields `class_id`, `name`, `section`, `teacher_id`.
- Teachers can view and request class updates; admin approves.


### 6.6 Bus/Transport Notifications (Phase 2)

- Minimal initial feature: manual buttons for driver/admin: `Bus departed`, `Reached school`, `Leaving school` with timestamp.
- Push notifications sent to parents subscribed to route.
- Future: GPS tracking with geofencing and ETA notifications.


---

## 7. Data Model (Firestore recommended schema)

> Naming convention: collection / documentID

### Collections & sample fields

**students/{studentId}**
```json
{
  "studentId": "S2026_001",
  "name": "Priya Sharma",
  "dob": "2016-02-15",
  "classId": "5A",
  "parentName": "Suresh Sharma",
  "parentPhone": "+91xxxxxxxxxx",
  "address": "Village ABC",
  "enrollmentDate": "2026-03-01"
}
```

**teachers/{teacherId}**
```json
{
  "teacherId": "T101",
  "name": "Mr. Kumar",
  "phone": "+91yyyyyyyyyy",
  "email": "",
  "assignedClasses": ["5A","6B"]
}
```

**classes/{classId}**
```json
{
  "classId": "5A",
  "name": "Class 5 - Section A",
  "teacherId": "T101",
  "room": "Room 2"
}
```

**fees/{feeId}**
```json
{
  "feeId": "F2026_501",
  "studentId": "S2026_001",
  "amount": 1500,
  "dueDate": "2026-03-31",
  "status": "pending", // pending, verified, rejected, paid_cash
  "paymentMethod": "upi", // upi, cash
  "screenshotUrl": "gs://.../fees/S2026_001/F2026_501.png",
  "uploadedBy": "+91xxxxxxxxxx",
  "uploadedAt": "2026-03-11T07:30:00Z",
  "verifiedBy": "admin01",
  "verifiedAt": "2026-03-11T08:00:00Z",
  "notes": ""
}
```

**attendance/{attendanceId}** (or subcollection under students or classes)
```json
{
  "attendanceId": "ATT_5A_20260311",
  "classId": "5A",
  "date": "2026-03-11",
  "markedBy": "T101",
  "records": [
    {"studentId": "S2026_001", "status": "present"},
    {"studentId": "S2026_002", "status": "absent"}
  ]
}
```

**notices/{noticeId}**
```json
{
  "noticeId": "N20260311_1",
  "title": "School Holiday",
  "body": "Tomorrow the school will be closed",
  "attachments": ["gs://.../notices/N2026_1.pdf"],
  "target": "all", // or ["5A","6B"]
  "postedBy": "admin01",
  "postedAt": "2026-03-11T09:00:00Z",
  "expiresAt": "2026-03-14"
}
```

**messages/{messageId}**
```json
{
  "messageId": "MSG_5A_20260311_1",
  "classId": "5A",
  "teacherId": "T101",
  "text": "Bring your science notebook tomorrow",
  "attachments": [],
  "createdAt": "2026-03-11T09:30:00Z"
}
```

**audit_logs/{logId}** — for edits, verification events, admin actions.


---

## 8. Storage & File Naming Conventions (Firebase Storage)

- `gs://schoolapp/<schoolId>/fees/<studentId>/<feeId>.<ext>`
- `gs://schoolapp/<schoolId>/notices/<noticeId>/<filename>`
- `gs://schoolapp/<schoolId>/teachers/<teacherId>/profile.jpg`

Keep metadata in Firestore linking to storage URLs.

---

## 9. Authentication & Security

**Authentication**
- Use **Firebase Authentication** (phone number login) as primary for parents and teachers.
- Admin accounts should have multi-factor auth (MFA) or strong passwords.

**Authorization**
- Use Firestore Security Rules to guard collection access by `auth.token.role` or custom claims.
- Example rule: teachers can only write to `messages` / `attendance` for their `assignedClasses`.

**Privacy**
- Store minimum PII. Only phone numbers and names required.
- Add consent language during onboarding.

**Backups & Exports**
- Schedule daily Firestore export to Cloud Storage.
- Admin can export CSV reports (fees, attendance) on demand.

---

## 10. Notifications

**Push Notifications (FCM)**
- Topics: `school_all`, `class_<classId>`, `student_<studentId>`.
- Senders: Admin/Teacher triggers via Cloud Functions.

**SMS (fallback)**
- For parents without smartphones, integrate with SMS provider (MSG91, Twilio, Textlocal) to send critical messages (fee due, absence). This requires storing parent phone and opting into SMS.

**Notification triggers:**
- New notice posted
- Fee verification result
- Absence marked
- Teacher message/homework posted
- Bus events (phase 2)

---

## 11. Offline & Low-Connectivity Strategy

- Use local caching (Flutter: Hive / sqflite / shared_preferences) to store last-known data (notices, class list, last invoices).
- Allow parents to take photo and queue upload; upload proceeds when connectivity returns.
- Use Firestore offline persistence so read/write works offline (Firestore SDK offers this).

---

## 12. Admin Dashboard (Web recommended)

**Tech:** React + Firebase Hosting / Firebase Admin SDK.

**Features:**
- Verify fees, view and filter pending screenshots
- Import students/teachers via CSV
- Class management
- Reports: unpaid fees, attendance trends, student directory
- Print receipts and export CSV
- Manage app content (notices, holidays)

---

## 13. Payment Integration Options (MVP → Phase 2)

**MVP (cheap + quick):**
- Use static or dynamic UPI QR and manual screenshot verification.
- Pros: no merchant account, fast to implement. Cons: manual verification, prone to fraud and delays.

**Phase 2 (recommended):**
- Integrate Indian payment gateway (Razorpay, PayU, Cashfree) for UPI/payments.
- Gateway provides server-side confirmation (webhooks) so payments become instantly verified.
- Add reconciliation reports.

---

## 14. Non-functional Requirements

- **Platform:** Android (Flutter), support Android 9+.
- **Scalability:** Support 2,000–5,000 students initially. Firestore scales automatically.
- **Availability:** 99% uptime for read operations.
- **Latency:** Typical reads < 300ms.
- **Security:** TLS for all traffic, secure storage for credentials, Firebase rules enforced.
- **Accessibility:** Large fonts, Hindi/English localization, high-contrast mode.

---

## 15. Play Store & Deployment Steps

1. Create Google Play Developer account (₹ ~ ₹2,000 / $25 one-time fee).
2. Create keystore and sign Flutter app.
3. Build release APK / AAB: `flutter build appbundle`.
4. Prepare assets: icon, screenshots, short & long description, privacy policy link.
5. Upload to Google Play Console and submit for review.
6. Monitor pre-release and internal testing tracks first.

**Admin dashboard:** host on Firebase Hosting and secure with Firebase Auth and Admin SDK.

---

## 16. Testing Plan

**Unit tests:** UI logic for forms, validators, fee status transitions.
**Integration tests:** Firestore flows for attendance and fees (use emulator during dev).
**E2E tests:** Sign-in, upload screenshot, admin verify, notification trigger.
**Manual QA:** Test on low-end Android devices and under poor connectivity.

---

## 17. MVP Acceptance Criteria

- Parents can view and upload fee receipts for outstanding invoices.
- Admin can view pending fee receipts and mark them verified/rejected.
- Teachers can mark attendance and parents of absentees receive notifications.
- Admin can post notices and parents see them.
- Students are importable from CSV and assignable to classes.

---

## 18. Milestones & Suggested Timeline (example)

**Week 0 (setup)**
- Finalize requirements, design wireframes, Firebase project creation.

**Week 1 (core)**
- Auth (phone login), student import, class model, basic parent UI, admin dashboard skeleton.

**Week 2 (fees & attendance)**
- Fees UI, screenshot upload, storage integration, admin verification workflow, attendance UI + notifications.

**Week 3 (polish & testing)**
- Notices, messaging, offline behavior, error handling, role-based access, testing.

**Week 4 (deploy)**
- Build release, internal testing, Play Console submission, documentation and handover.

---

## 19. Future Roadmap (post-MVP)

- Integrate payment gateway for instant verification.
- Two-way messaging and parent-teacher chat.
- Digital report cards and analytics dashboards.
- Bus GPS tracking and ETA.
- Attendance biometrics (if needed) — fingerprint/face verification with privacy review.
- Multi-school SaaS productization (tenant model).

---

## 20. Operational & Support Notes

- Add a simple admin help page and in-app help for parents (how to take screenshot, how to pay UPI QR, FAQs in Hindi/English).
- Keep a visible phone number/email for support inside the app profile and on notices.
- Provide training session for teachers and a printed single-sheet cheat-sheet.

---

## 21. Appendix

### 21.1 Sample Firestore Security Rule (high-level)
```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Only authenticated users
    match /{document=**} {
      allow read, write: if request.auth != null;
    }

    // Students readable by school staff and parent user matching phone
    match /students/{studentId} {
      allow read: if isStaff() || isParentOf(studentId);
      allow write: if isAdmin();
    }

    function isAdmin() {
      return request.auth.token.role == 'admin';
    }
    function isStaff() {
      return request.auth.token.role in ['admin','teacher'];
    }
    function isParentOf(studentId) {
      return request.auth.token.phone_number == resource.data.parentPhone;
    }
  }
}
```

> Note: Replace with stricter rules in production.


### 21.2 Example CSV import columns (students)
```
studentId, name, dob, classId, parentName, parentPhone, address, enrollmentDate
```

---

# END OF SPEC



*If you want, I can:*
- Export this Markdown as a downloadable `.md` file.
- Generate wireframe mockups (Figma/Tailwind style) for the parent and teacher screens.
- Produce Firebase security rules, Cloud Function code stubs, and Flutter starter templates (I can generate ready-to-run code snippets next).

