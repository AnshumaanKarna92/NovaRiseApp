import { Timestamp } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/https";
import { z } from "zod";

import { db } from "../../config/firebase.js";
import { getRequestContext, requireRole } from "../../shared/context.js";
import { badRequest } from "../../shared/errors.js";
import { logAuditEvent } from "../audit/logAuditEvent.js";
import { queueNotificationJob } from "../notifications/notificationService.js";

const recordSchema = z.object({
  studentId: z.string().min(1),
  status: z.enum(["present", "absent"]),
  remarks: z.string().optional(),
});

const submitSchema = z.object({
  classId: z.string().min(1),
  date: z.string().min(1),
  records: z.array(recordSchema).min(1),
  submissionMode: z.enum(["initial", "retry"]).default("initial"),
});

const updateSchema = z.object({
  attendanceId: z.string().min(1),
  records: z.array(recordSchema).min(1),
  reason: z.string().min(1),
});

export const submitAttendance = onCall(async (request) => {
  const context = await getRequestContext(request);
  requireRole(context, ["teacher", "admin"]);

  const payload = submitSchema.parse(request.data);
  const attendanceId = `ATT_${payload.classId}_${payload.date.replaceAll("-", "")}`;
  const doc = {
    attendanceId,
    schoolId: context.schoolId,
    classId: payload.classId,
    date: payload.date,
    markedByUid: context.uid,
    markedByTeacherId: context.uid,
    records: payload.records,
    isEdited: false,
    editCount: 0,
    lastEditedAt: null,
    lastEditedByUid: null,
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  };

  await db.collection("attendance").doc(attendanceId).set(doc);

  const absentStudentIds = payload.records
    .filter((item) => item.status === "absent")
    .map((item) => item.studentId);

  if (absentStudentIds.length > 0) {
    await queueNotificationJob({
      schoolId: context.schoolId,
      type: "absence_alert",
      targetMode: "student",
      targetIds: absentStudentIds,
      payload: { classId: payload.classId, date: payload.date },
    });
  }

  await logAuditEvent({
    actor: context,
    action: "attendance_submitted",
    entityType: "attendance",
    entityId: attendanceId,
    after: doc,
  });

  return { attendanceId, absentCount: absentStudentIds.length };
});

export const updateAttendance = onCall(async (request) => {
  const context = await getRequestContext(request);
  requireRole(context, ["teacher", "admin"]);

  const payload = updateSchema.parse(request.data);
  const ref = db.collection("attendance").doc(payload.attendanceId);
  const snapshot = await ref.get();
  if (!snapshot.exists) {
    badRequest("Attendance document not found");
  }

  const before = snapshot.data();
  await ref.update({
    records: payload.records,
    isEdited: true,
    editCount: (before?.editCount ?? 0) + 1,
    lastEditedAt: Timestamp.now(),
    lastEditedByUid: context.uid,
    updatedAt: Timestamp.now(),
  });

  await logAuditEvent({
    actor: context,
    action: "attendance_updated",
    entityType: "attendance",
    entityId: payload.attendanceId,
    before,
    after: payload.records,
    reason: payload.reason,
  });

  return { attendanceId: payload.attendanceId, updated: true };
});
