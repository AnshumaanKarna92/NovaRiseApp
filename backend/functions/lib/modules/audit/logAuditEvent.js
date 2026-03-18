"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.logAuditEvent = logAuditEvent;
const firestore_1 = require("firebase-admin/firestore");
const firebase_js_1 = require("../../config/firebase.js");
async function logAuditEvent(input) {
    await firebase_js_1.db.collection("audit_logs").add({
        schoolId: input.actor.schoolId,
        actorUid: input.actor.uid,
        actorRole: input.actor.role,
        action: input.action,
        entityType: input.entityType,
        entityId: input.entityId,
        before: input.before ?? null,
        after: input.after ?? null,
        reason: input.reason ?? "",
        createdAt: firestore_1.Timestamp.now(),
    });
}
