"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.publishNotice = void 0;
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/https");
const zod_1 = require("zod");
const firebase_js_1 = require("../../config/firebase.js");
const context_js_1 = require("../../shared/context.js");
const logAuditEvent_js_1 = require("../audit/logAuditEvent.js");
const notificationService_js_1 = require("../notifications/notificationService.js");
const schema = zod_1.z.object({
    title: zod_1.z.string().min(1),
    body: zod_1.z.string().min(1),
    attachmentUrls: zod_1.z.array(zod_1.z.string()).default([]),
    targetType: zod_1.z.enum(["all", "classes"]),
    targetClassIds: zod_1.z.array(zod_1.z.string()).default([]),
    startAt: zod_1.z.string().min(1),
    expiresAt: zod_1.z.string().min(1),
});
exports.publishNotice = (0, https_1.onCall)(async (request) => {
    const context = await (0, context_js_1.getRequestContext)(request);
    (0, context_js_1.requireRole)(context, ["admin"]);
    const payload = schema.parse(request.data);
    const ref = firebase_js_1.db.collection("notices").doc();
    const notice = {
        noticeId: ref.id,
        schoolId: context.schoolId,
        title: payload.title,
        body: payload.body,
        attachmentUrls: payload.attachmentUrls,
        targetType: payload.targetType,
        targetClassIds: payload.targetClassIds,
        postedByUid: context.uid,
        startAt: payload.startAt,
        expiresAt: payload.expiresAt,
        status: "published",
        createdAt: firestore_1.Timestamp.now(),
        updatedAt: firestore_1.Timestamp.now(),
    };
    await ref.set(notice);
    await (0, logAuditEvent_js_1.logAuditEvent)({
        actor: context,
        action: "notice_published",
        entityType: "notices",
        entityId: ref.id,
        after: notice,
    });
    await (0, notificationService_js_1.queueNotificationJob)({
        schoolId: context.schoolId,
        type: "notice_published",
        targetMode: payload.targetType === "all" ? "all" : "class",
        targetIds: payload.targetClassIds,
        payload: { noticeId: ref.id, title: payload.title },
    });
    return notice;
});
