"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.queueNotificationJob = queueNotificationJob;
const firestore_1 = require("firebase-admin/firestore");
const firebase_js_1 = require("../../config/firebase.js");
async function queueNotificationJob(input) {
    await firebase_js_1.db.collection("notification_jobs").add({
        schoolId: input.schoolId,
        type: input.type,
        targetMode: input.targetMode,
        targetIds: input.targetIds,
        payload: input.payload,
        channel: input.channel ?? "push",
        status: "queued",
        createdAt: firestore_1.Timestamp.now(),
        processedAt: null,
    });
}
