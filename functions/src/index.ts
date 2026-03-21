import * as admin from "firebase-admin";
import * as functions from "firebase-functions";
import {setGlobalOptions} from "firebase-functions";
import {onCall as onCallV2} from "firebase-functions/v2/https";
import {onDocumentCreated} from "firebase-functions/v2/firestore";
import {z} from "zod";
import {parse} from "csv-parse/sync";
import axios from "axios";

admin.initializeApp();
setGlobalOptions({maxInstances: 10});

const db = admin.firestore();

type UserRole = "admin" | "teacher" | "parent" | "cash_collector";

/**
 * Basic Firestore-based rate limiter for mission-critical endpoints.
 * In a high-traffic environment, use Redis or a specialized service.
 */
async function checkRateLimit(uid: string, action: string, limit: number, windowSeconds: number) {
  const now = Date.now();
  const windowStart = now - (windowSeconds * 1000);
  
  const rateLimitRef = db.collection("rate_limits").doc(`${uid}_${action}`);
  const snap = await rateLimitRef.get();
  
  const data = snap.data() as { attempts: number[]; lastReset: number } | undefined;
  const attempts = (data?.attempts ?? []).filter(t => t > windowStart);
  
  if (attempts.length >= limit) {
    throw new functions.https.HttpsError(
      "resource-exhausted", 
      "Rate limit exceeded. Please try again later."
    );
  }
  
  attempts.push(now);
  await rateLimitRef.set({ attempts, lastReset: now }, { merge: true });
}

async function getRequestContext(context: any) {
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required");
  }

  const userSnapshot = await db.collection("users").doc(context.auth.uid).get();
  if (!userSnapshot.exists) {
    throw new functions.https.HttpsError("permission-denied", "User profile not found");
  }

  const data = userSnapshot.data() as {role?: UserRole; schoolId?: string; displayName?: string};
  return {
    uid: context.auth.uid,
    role: (data.role ?? "parent") as UserRole,
    schoolId: data.schoolId ?? "",
    displayName: data.displayName ?? "Staff",
  };
}

function requireRole(role: UserRole, allowed: UserRole[]) {
  if (!allowed.includes(role)) {
    throw new functions.https.HttpsError("permission-denied", "Insufficient permissions");
  }
}

async function logAuditEvent(input: {
  schoolId: string;
  actorUid: string;
  actorRole: UserRole;
  action: string;
  entityType: string;
  entityId: string;
  before?: unknown;
  after?: unknown;
  reason?: string;
}) {
  await db.collection("audit_logs").add({
    schoolId: input.schoolId,
    actorUid: input.actorUid,
    actorRole: input.actorRole,
    action: input.action,
    entityType: input.entityType,
    entityId: input.entityId,
    before: input.before ?? null,
    after: input.after ?? null,
    reason: input.reason ?? "",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

async function queueNotificationJob(input: {
  schoolId: string;
  type: string;
  targetMode: "student" | "class" | "all";
  targetIds: string[];
  payload: Record<string, unknown>;
}) {
  await db.collection("notification_jobs").add({
    schoolId: input.schoolId,
    type: input.type,
    targetMode: input.targetMode,
    targetIds: input.targetIds,
    payload: input.payload,
    channel: "push",
    status: "queued",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    processedAt: null,
  });
}

const receiptSchema = z.object({
  invoiceId: z.string().min(1),
  studentId: z.string().min(1),
  paymentMethod: z.enum(["upi", "cash"]),
  clientReference: z.string().optional(),
  screenshotUrl: z.string().min(1),
});

const verifyFeeSchema = z.object({
  paymentId: z.string().min(1),
  decision: z.enum(["verified", "rejected"]),
  notes: z.string().default(""),
});

const cashPaymentSchema = z.object({
  studentId: z.string().min(1),
  invoiceIds: z.array(z.string()).min(1),
  amount: z.number().positive(),
  paymentDate: z.string().min(1),
  collectorId: z.string().min(1),
  attachmentUrl: z.string().optional(),
});

const attendanceRecordSchema = z.object({
  studentId: z.string().min(1),
  status: z.enum(["present", "absent"]),
  remarks: z.string().optional(),
});

const submitAttendanceSchema = z.object({
  classId: z.string().min(1),
  date: z.string().min(1),
  records: z.array(attendanceRecordSchema).min(1),
  submissionMode: z.enum(["initial", "retry"]).default("initial"),
});

const updateAttendanceSchema = z.object({
  attendanceId: z.string().min(1),
  records: z.array(attendanceRecordSchema).min(1),
  reason: z.string().min(1),
});

const publishNoticeSchema = z.object({
  title: z.string().min(1),
  body: z.string().min(1),
  attachmentUrls: z.array(z.string()).default([]),
  targetType: z.enum(["all", "classes", "teachers"]),
  targetClassIds: z.array(z.string()).default([]),
  startAt: z.string().min(1),
  expiresAt: z.string().min(1),
});

const deleteNoticeSchema = z.object({
  noticeId: z.string().min(1),
});

const classMessageSchema = z.object({
  classId: z.string().min(1),
  type: z.enum(["message", "homework"]),
  text: z.string().min(1),
  attachmentUrls: z.array(z.string()).default([]),
  dueDate: z.string().optional(),
});

const ensureUserProfileSchema = z.object({
  displayName: z.string().optional(),
  phone: z.string().optional(),
  fcmToken: z.string().optional(),
});

const enqueueImportSchema = z.object({
  fileUrl: z.string().min(1),
});

// SECURE: Removed public setUserRole function to prevent unauthorized role escalation.
// Administrative role management should be done via Firebase Console or a secured admin-only endpoint.

export const ensureUserProfile = onCallV2({invoker: "public"}, async (request) => {
  const data = request.data as any;
  const context = {auth: request.auth} as any;
  if (!context.auth?.uid) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required");
  }

  const uid = context.auth.uid as string;
  await checkRateLimit(uid, "ensure_profile", 5, 60); // 5 attempts per minute
  
  const payload = ensureUserProfileSchema.parse(data ?? {});
  const phoneFromToken = context.auth.token?.phone_number as string | undefined;
  const profileRef = db.collection("users").doc(uid);
  const existing = await profileRef.get();
  const phone = payload.phone ?? phoneFromToken ?? "";
  
  if (!existing.exists) {
    // Search for students matching this phone to auto-link
    let linkedStudentIds: string[] = [];
    if (phone) {
      const studentsQuery = await db.collection("students")
        .where("parentPhone", "==", phone)
        .get();
      
      linkedStudentIds = studentsQuery.docs.map(doc => doc.id);
      
      // Also update student records to include the new parent UID
      const batch = db.batch();
      for (const studentDoc of studentsQuery.docs) {
        batch.update(studentDoc.ref, {
          parentUserIds: admin.firestore.FieldValue.arrayUnion(uid),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
      if (studentsQuery.size > 0) {
        await batch.commit();
      }
    }

    await profileRef.set({
      uid,
      schoolId: "school_001",
      role: "parent",
      displayName: payload.displayName ?? "Parent",
      phone: phone,
      linkedStudentIds: linkedStudentIds,
      assignedClassIds: [],
      fcmTokens: payload.fcmToken ? [payload.fcmToken] : [],
      status: "active",
      preferredLanguage: "en",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  } else {
    const existingData = existing.data();
    const currentPhone = existingData?.phone ?? phone;
    
    const updateData: any = {
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      phone: currentPhone,
      displayName: existingData?.displayName ?? payload.displayName ?? "Parent",
    };

    if (payload.fcmToken) {
      updateData.fcmTokens = admin.firestore.FieldValue.arrayUnion(payload.fcmToken);
    }

    await profileRef.update(updateData);
  }

  // Ensure custom claims are set for role-based security rules
  const authUser = await admin.auth().getUser(uid);
  const currentClaims = (authUser.customClaims ?? {}) as Record<string, unknown>;
  const profileData = (await profileRef.get()).data();
  const assignedRole = profileData?.role ?? "parent";

  if (currentClaims.role !== assignedRole) {
    await admin.auth().setCustomUserClaims(uid, {
      ...currentClaims,
      role: assignedRole,
    });
  }

  return {uid, ensured: true, role: assignedRole};
});

export const createOrUpdateFeeReceipt = onCallV2({invoker: "public"}, async (requestCall) => {
  const data = requestCall.data as any;
  const context = {auth: requestCall.auth} as any;
  const request = await getRequestContext(context);
  requireRole(request.role, ["parent"]);
  
  await checkRateLimit(request.uid, "submit_fee", 10, 300); // 10 receipts per 5 minutes

  const payload = receiptSchema.parse(data);
  const invoiceRef = db.collection("fee_invoices").doc(payload.invoiceId);
  const invoiceSnapshot = await invoiceRef.get();

  if (!invoiceSnapshot.exists) {
    throw new functions.https.HttpsError("not-found", "Invoice not found");
  }

  const paymentRef = db.collection("fee_payments").doc();
  const payment = {
    paymentId: paymentRef.id,
    schoolId: request.schoolId,
    invoiceId: payload.invoiceId,
    studentId: payload.studentId,
    amount: invoiceSnapshot.data()?.amount ?? 0,
    paymentMethod: payload.paymentMethod,
    submissionChannel: "mobile_upload",
    status: "pending_verification",
    screenshotUrl: payload.screenshotUrl,
    clientReference: payload.clientReference ?? "",
    uploadedByUid: request.uid,
    uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
    verifiedByUid: null,
    verifiedAt: null,
    rejectionReason: "",
    notes: "",
    futureGatewayRef: null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await paymentRef.set(payment);
  await invoiceRef.update({
    paymentStatus: "pending_verification",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await logAuditEvent({
    schoolId: request.schoolId,
    actorUid: request.uid,
    actorRole: request.role,
    action: "fee_receipt_submitted",
    entityType: "fee_payments",
    entityId: paymentRef.id,
    after: payment,
  });

  await queueNotificationJob({
    schoolId: request.schoolId,
    type: "fee_receipt_submitted",
    targetMode: "all",
    targetIds: [],
    payload: {paymentId: paymentRef.id, invoiceId: payload.invoiceId},
  });

  return {paymentId: paymentRef.id, status: "pending_verification"};
});

export const verifyFeePayment = onCallV2({invoker: "public"}, async (requestCall) => {
  const data = requestCall.data as any;
  const context = {auth: requestCall.auth} as any;
  const request = await getRequestContext(context);
  requireRole(request.role, ["admin"]);

  const payload = verifyFeeSchema.parse(data);
  const paymentRef = db.collection("fee_payments").doc(payload.paymentId);
  const paymentSnapshot = await paymentRef.get();

  if (!paymentSnapshot.exists) {
    throw new functions.https.HttpsError("not-found", "Payment not found");
  }

  const before = paymentSnapshot.data();
  await paymentRef.update({
    status: payload.decision,
    notes: payload.notes,
    rejectionReason: payload.decision === "rejected" ? payload.notes : "",
    verifiedByUid: request.uid,
    verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const invoiceId = before?.invoiceId as string | undefined;
  if (invoiceId) {
    await db.collection("fee_invoices").doc(invoiceId).update({
      status: payload.decision === "verified" ? "paid" : "unpaid",
      paymentStatus: payload.decision,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  await logAuditEvent({
    schoolId: request.schoolId,
    actorUid: request.uid,
    actorRole: request.role,
    action: `fee_payment_${payload.decision}`,
    entityType: "fee_payments",
    entityId: payload.paymentId,
    before,
    after: {status: payload.decision, notes: payload.notes},
    reason: payload.notes,
  });

  return {paymentId: payload.paymentId, status: payload.decision};
});

export const recordCashPayment = onCallV2({invoker: "public"}, async (requestCall) => {
  const data = requestCall.data as any;
  const context = {auth: requestCall.auth} as any;
  const request = await getRequestContext(context);
  requireRole(request.role, ["admin", "cash_collector"]);

  const payload = cashPaymentSchema.parse(data);
  const paymentRef = db.collection("fee_payments").doc();

  await paymentRef.set({
    paymentId: paymentRef.id,
    schoolId: request.schoolId,
    invoiceIds: payload.invoiceIds,
    studentId: payload.studentId,
    amount: payload.amount,
    paymentMethod: "cash",
    submissionChannel: "staff_entry",
    status: "verified",
    screenshotUrl: payload.attachmentUrl ?? "",
    clientReference: payload.collectorId,
    uploadedByUid: request.uid,
    uploadedAt: admin.firestore.FieldValue.serverTimestamp(),
    verifiedByUid: request.uid,
    verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    rejectionReason: "",
    notes: "Cash payment recorded",
    futureGatewayRef: null,
    recordedByUid: request.uid,
    paymentDate: payload.paymentDate,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await Promise.all(payload.invoiceIds.map((invoiceId) => {
    return db.collection("fee_invoices").doc(invoiceId).update({
      status: "paid",
      paymentStatus: "verified",
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }));

  return {paymentId: paymentRef.id, status: "verified"};
});

export const submitAttendance = onCallV2({invoker: "public"}, async (requestCall) => {
  const data = requestCall.data as any;
  const context = {auth: requestCall.auth} as any;
  const request = await getRequestContext(context);
  requireRole(request.role, ["teacher", "admin"]);

  const payload = submitAttendanceSchema.parse(data);
  const attendanceId = `ATT_${payload.classId}_${payload.date.replace(/-/g, "")}`;

  await db.collection("attendance").doc(attendanceId).set({
    attendanceId,
    schoolId: request.schoolId,
    classId: payload.classId,
    date: payload.date,
    markedByUid: request.uid,
    markedByTeacherId: request.uid,
    markedByName: request.displayName,
    records: payload.records,
    isEdited: false,
    editCount: 0,
    lastEditedAt: null,
    lastEditedByUid: null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  const absentStudentIds = payload.records
    .filter((record) => record.status === "absent")
    .map((record) => record.studentId);

  if (absentStudentIds.length > 0) {
    await queueNotificationJob({
      schoolId: request.schoolId,
      type: "absence_alert",
      targetMode: "student",
      targetIds: absentStudentIds,
      payload: {classId: payload.classId, date: payload.date},
    });
  }

  return {attendanceId, absentCount: absentStudentIds.length};
});

export const updateAttendance = onCallV2({invoker: "public"}, async (requestCall) => {
  const data = requestCall.data as any;
  const context = {auth: requestCall.auth} as any;
  const request = await getRequestContext(context);
  requireRole(request.role, ["teacher", "admin"]);

  const payload = updateAttendanceSchema.parse(data);
  const ref = db.collection("attendance").doc(payload.attendanceId);
  const snapshot = await ref.get();

  if (!snapshot.exists) {
    throw new functions.https.HttpsError("not-found", "Attendance not found");
  }

  const before = snapshot.data();
  await ref.update({
    records: payload.records,
    isEdited: true,
    editCount: (before?.editCount ?? 0) + 1,
    lastMarkedByName: request.displayName,
    lastEditedAt: admin.firestore.FieldValue.serverTimestamp(),
    lastEditedByUid: request.uid,
    markedByName: request.displayName, // Update this so current UI shows correct name
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await logAuditEvent({
    schoolId: request.schoolId,
    actorUid: request.uid,
    actorRole: request.role,
    action: "attendance_updated",
    entityType: "attendance",
    entityId: payload.attendanceId,
    before,
    after: payload.records,
    reason: payload.reason,
  });

  return {attendanceId: payload.attendanceId, updated: true};
});

export const publishNotice = onCallV2({invoker: "public"}, async (requestCall) => {
  const data = requestCall.data as any;
  const context = {auth: requestCall.auth} as any;
  const request = await getRequestContext(context);
  requireRole(request.role, ["admin"]);
  
  await checkRateLimit(request.uid, "publish_notice", 5, 300); // 5 notices per 5 minutes

  const payload = publishNoticeSchema.parse(data);
  const ref = db.collection("notices").doc();

  await ref.set({
    noticeId: ref.id,
    schoolId: request.schoolId,
    title: payload.title,
    body: payload.body,
    attachmentUrls: payload.attachmentUrls,
    targetType: payload.targetType,
    targetClassIds: payload.targetClassIds,
    postedByUid: request.uid,
    startAt: payload.startAt,
    expiresAt: payload.expiresAt,
    status: "published",
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await queueNotificationJob({
    schoolId: request.schoolId,
    type: "notice_published",
    targetMode: payload.targetType === "all" ? "all" : "class",
    targetIds: payload.targetClassIds,
    payload: {noticeId: ref.id, title: payload.title},
  });

  return {noticeId: ref.id, status: "published"};
});

export const updateNotice = onCallV2({invoker: "public"}, async (requestCall) => {
  const data = requestCall.data as any;
  const context = {auth: requestCall.auth} as any;
  const request = await getRequestContext(context);
  requireRole(request.role, ["admin"]);

  const payload = publishNoticeSchema.partial().extend({noticeId: z.string()}).parse(data);
  const {noticeId, ...updates} = payload;
  
  await db.collection("notices").doc(noticeId).update({
    ...updates,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return {noticeId, status: "updated"};
});

export const deleteNotice = onCallV2({invoker: "public"}, async (requestCall) => {
  const data = requestCall.data as any;
  const context = {auth: requestCall.auth} as any;
  const request = await getRequestContext(context);
  requireRole(request.role, ["admin"]);

  const payload = deleteNoticeSchema.parse(data);
  await db.collection("notices").doc(payload.noticeId).delete();

  return {noticeId: payload.noticeId, status: "deleted"};
});

export const createClassMessage = onCallV2({invoker: "public"}, async (requestCall) => {
  const data = requestCall.data as any;
  const context = {auth: requestCall.auth} as any;
  const request = await getRequestContext(context);
  requireRole(request.role, ["teacher", "admin"]);
  
  await checkRateLimit(request.uid, "class_message", 20, 60); // 20 messages per minute

  const payload = classMessageSchema.parse(data);
  const ref = db.collection("messages").doc();

  await ref.set({
    messageId: ref.id,
    schoolId: request.schoolId,
    classId: payload.classId,
    teacherUid: request.uid,
    teacherId: request.uid,
    type: payload.type,
    text: payload.text,
    attachmentUrls: payload.attachmentUrls,
    dueDate: payload.dueDate ?? null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await queueNotificationJob({
    schoolId: request.schoolId,
    type: payload.type === "homework" ? "homework_posted" : "class_message_posted",
    targetMode: "class",
    targetIds: [payload.classId],
    payload: {messageId: ref.id, classId: payload.classId},
  });

  return {messageId: ref.id, status: "created"};
});

export const getDashboardSummaries = onCallV2({invoker: "public"}, async (requestCall) => {
  const context = {auth: requestCall.auth} as any;
  const request = await getRequestContext(context);
  requireRole(request.role, ["admin"]);

  const [pendingFees, notices, messages] = await Promise.all([
    db.collection("fee_payments")
      .where("schoolId", "==", request.schoolId)
      .where("status", "==", "pending_verification")
      .count()
      .get(),
    db.collection("notices")
      .where("schoolId", "==", request.schoolId)
      .count()
      .get(),
    db.collection("messages")
      .where("schoolId", "==", request.schoolId)
      .count()
      .get(),
  ]);

  return {
    pendingFees: pendingFees.data().count,
    notices: notices.data().count,
    messages: messages.data().count,
  };
});

export const importStudentsCsv = functions.https.onRequest(async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).send("Method not allowed");
    return;
  }

  // SECURE: Enforce API Key for legacy HTTP endpoints
  const apiKey = req.headers["x-api-key"];
  const internalSecret = process.env.INTERNAL_IMPORT_SECRET || "internal_dev_only_change_this";
  
  if (apiKey !== internalSecret) {
    res.status(401).json({error: "Unauthorized: Invalid API Key"});
    return;
  }

  const schoolId = String(req.body.schoolId ?? "");
  const fileUrl = String(req.body.fileUrl ?? "");
  const createdByUid = String(req.body.createdByUid ?? "");

  if (!schoolId || !fileUrl || !createdByUid) {
    res.status(400).json({error: "schoolId, fileUrl, and createdByUid are required"});
    return;
  }

  const jobRef = db.collection("import_jobs").doc();
  await jobRef.set({
    jobId: jobRef.id,
    schoolId,
    type: "students_csv",
    fileUrl,
    status: "queued",
    summary: {
      totalRows: 0,
      successCount: 0,
      failureCount: 0,
    },
    errorReportUrl: null,
    createdByUid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  res.status(202).json({jobId: jobRef.id});
});

export const enqueueStudentsCsvImport = onCallV2({invoker: "public"}, async (requestCall) => {
  const data = requestCall.data as any;
  const context = {auth: requestCall.auth} as any;
  const request = await getRequestContext(context);
  requireRole(request.role, ["admin"]);

  const payload = enqueueImportSchema.parse(data);
  const jobRef = db.collection("import_jobs").doc();
  await jobRef.set({
    jobId: jobRef.id,
    schoolId: request.schoolId,
    type: "students_csv",
    fileUrl: payload.fileUrl,
    status: "queued",
    summary: {
      totalRows: 0,
      successCount: 0,
      failureCount: 0,
    },
    errorReportUrl: null,
    createdByUid: request.uid,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await logAuditEvent({
    schoolId: request.schoolId,
    actorUid: request.uid,
    actorRole: request.role,
    action: "students_csv_import_enqueued",
    entityType: "import_jobs",
    entityId: jobRef.id,
    after: {fileUrl: payload.fileUrl},
  });

  return {jobId: jobRef.id, status: "queued"};
});

export const processImportJob = onDocumentCreated("import_jobs/{jobId}", async (event) => {
  const snap = event.data;
  if (!snap) return;

  const job = snap.data();
  if (job.status !== "queued" || job.type !== "students_csv") return;

  const jobId = event.params.jobId;
  const jobRef = db.collection("import_jobs").doc(jobId);

  try {
    await jobRef.update({status: "processing", updatedAt: admin.firestore.FieldValue.serverTimestamp()});

    // 1. Download CSV
    const response = await axios.get(job.fileUrl);
    const csvData = response.data;

    // 2. Parse CSV
    // studentId, name, dob, classId, parentName, parentPhone, address, enrollmentDate
    const records = parse(csvData, {
      columns: true,
      skip_empty_lines: true,
      trim: true,
    }) as any[];

    let successCount = 0;
    let failureCount = 0;
    const errors: string[] = [];

    // 3. Process each record
    for (const record of records) {
      try {
        const studentId = record.studentId || `S_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
        const studentRef = db.collection("students").doc(studentId);
        const parentPhone = record.parentPhone || "";
        
        // Find parent user by phone number to link accounts
        let parentUserIds: string[] = [];
        if (parentPhone) {
          const userQuery = await db.collection("users")
            .where("phone", "==", parentPhone)
            .where("role", "==", "parent")
            .limit(1)
            .get();
            
          if (!userQuery.empty) {
            const parentDoc = userQuery.docs[0];
            const parentUid = parentDoc.id;
            parentUserIds = [parentUid];
            
            // Link student to parent's record
            const linkedStudentIds = (parentDoc.data().linkedStudentIds || []) as string[];
            if (!linkedStudentIds.includes(studentId)) {
              await parentDoc.ref.update({
                linkedStudentIds: admin.firestore.FieldValue.arrayUnion(studentId),
                updatedAt: admin.firestore.FieldValue.serverTimestamp(),
              });
            }
          }
        }

        const studentData = {
          studentId,
          schoolId: job.schoolId,
          name: record.name,
          dob: record.dob || "",
          classId: record.classId || "Unassigned",
          parentName: record.parentName || "",
          parentPhone: parentPhone,
          parentUserIds: parentUserIds, // LINKED: Ensuring parent can see child
          address: record.address || "",
          enrollmentDate: record.enrollmentDate || new Date().toISOString().split("T")[0],
          status: "active",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        await studentRef.set(studentData);
        successCount++;
      } catch (err: any) {
        failureCount++;
        errors.push(`Row processing failed: ${err.message}`);
      }
    }

    // 4. Update job status
    await jobRef.update({
      status: "completed",
      "summary.totalRows": records.length,
      "summary.successCount": successCount,
      "summary.failureCount": failureCount,
      errorReportUrl: errors.length > 0 ? "errors_in_logs" : null,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    await logAuditEvent({
      schoolId: job.schoolId,
      actorUid: job.createdByUid,
      actorRole: "admin",
      action: "students_csv_import_completed",
      entityType: "import_jobs",
      entityId: jobId,
      after: {successCount, failureCount},
    });

  } catch (error: any) {
    console.error("Import job failed", error);
    await jobRef.update({
      status: "failed",
      notes: error.message,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
});
