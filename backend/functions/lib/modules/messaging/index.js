"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.createClassMessage = void 0;
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/https");
const zod_1 = require("zod");
const firebase_js_1 = require("../../config/firebase.js");
const context_js_1 = require("../../shared/context.js");
const logAuditEvent_js_1 = require("../audit/logAuditEvent.js");
const notificationService_js_1 = require("../notifications/notificationService.js");
const schema = zod_1.z.object({
    classId: zod_1.z.string().min(1),
    type: zod_1.z.enum(["message", "homework"]),
    text: zod_1.z.string().min(1),
    attachmentUrls: zod_1.z.array(zod_1.z.string()).default([]),
    dueDate: zod_1.z.string().optional(),
});
exports.createClassMessage = (0, https_1.onCall)(async (request) => {
    const context = await (0, context_js_1.getRequestContext)(request);
    (0, context_js_1.requireRole)(context, ["teacher", "admin"]);
    const payload = schema.parse(request.data);
    const ref = firebase_js_1.db.collection("messages").doc();
    const message = {
        messageId: ref.id,
        schoolId: context.schoolId,
        classId: payload.classId,
        teacherUid: context.uid,
        teacherId: context.uid,
        type: payload.type,
        text: payload.text,
        attachmentUrls: payload.attachmentUrls,
        dueDate: payload.dueDate ?? null,
        createdAt: firestore_1.Timestamp.now(),
        updatedAt: firestore_1.Timestamp.now(),
    };
    await ref.set(message);
    await (0, logAuditEvent_js_1.logAuditEvent)({
        actor: context,
        action: `${payload.type}_created`,
        entityType: "messages",
        entityId: ref.id,
        after: message,
    });
    await (0, notificationService_js_1.queueNotificationJob)({
        schoolId: context.schoolId,
        type: payload.type === "homework" ? "homework_posted" : "class_message_posted",
        targetMode: "class",
        targetIds: [payload.classId],
        payload: { messageId: ref.id },
    });
    return message;
});
