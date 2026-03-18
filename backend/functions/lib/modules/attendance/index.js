"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.updateAttendance = exports.submitAttendance = void 0;
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/https");
const zod_1 = require("zod");
const firebase_js_1 = require("../../config/firebase.js");
const context_js_1 = require("../../shared/context.js");
const errors_js_1 = require("../../shared/errors.js");
const logAuditEvent_js_1 = require("../audit/logAuditEvent.js");
const notificationService_js_1 = require("../notifications/notificationService.js");
const recordSchema = zod_1.z.object({
    studentId: zod_1.z.string().min(1),
    status: zod_1.z.enum(["present", "absent"]),
    remarks: zod_1.z.string().optional(),
});
const submitSchema = zod_1.z.object({
    classId: zod_1.z.string().min(1),
    date: zod_1.z.string().min(1),
    records: zod_1.z.array(recordSchema).min(1),
    submissionMode: zod_1.z.enum(["initial", "retry"]).default("initial"),
});
const updateSchema = zod_1.z.object({
    attendanceId: zod_1.z.string().min(1),
    records: zod_1.z.array(recordSchema).min(1),
    reason: zod_1.z.string().min(1),
});
exports.submitAttendance = (0, https_1.onCall)(async (request) => {
    const context = await (0, context_js_1.getRequestContext)(request);
    (0, context_js_1.requireRole)(context, ["teacher", "admin"]);
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
        createdAt: firestore_1.Timestamp.now(),
        updatedAt: firestore_1.Timestamp.now(),
    };
    await firebase_js_1.db.collection("attendance").doc(attendanceId).set(doc);
    const absentStudentIds = payload.records
        .filter((item) => item.status === "absent")
        .map((item) => item.studentId);
    if (absentStudentIds.length > 0) {
        await (0, notificationService_js_1.queueNotificationJob)({
            schoolId: context.schoolId,
            type: "absence_alert",
            targetMode: "student",
            targetIds: absentStudentIds,
            payload: { classId: payload.classId, date: payload.date },
        });
    }
    await (0, logAuditEvent_js_1.logAuditEvent)({
        actor: context,
        action: "attendance_submitted",
        entityType: "attendance",
        entityId: attendanceId,
        after: doc,
    });
    return { attendanceId, absentCount: absentStudentIds.length };
});
exports.updateAttendance = (0, https_1.onCall)(async (request) => {
    const context = await (0, context_js_1.getRequestContext)(request);
    (0, context_js_1.requireRole)(context, ["teacher", "admin"]);
    const payload = updateSchema.parse(request.data);
    const ref = firebase_js_1.db.collection("attendance").doc(payload.attendanceId);
    const snapshot = await ref.get();
    if (!snapshot.exists) {
        (0, errors_js_1.badRequest)("Attendance document not found");
    }
    const before = snapshot.data();
    await ref.update({
        records: payload.records,
        isEdited: true,
        editCount: (before?.editCount ?? 0) + 1,
        lastEditedAt: firestore_1.Timestamp.now(),
        lastEditedByUid: context.uid,
        updatedAt: firestore_1.Timestamp.now(),
    });
    await (0, logAuditEvent_js_1.logAuditEvent)({
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
