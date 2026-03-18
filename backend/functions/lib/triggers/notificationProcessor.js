"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.notificationJobCreated = void 0;
const firestore_1 = require("firebase-functions/firestore");
exports.notificationJobCreated = (0, firestore_1.onDocumentCreated)("notification_jobs/{jobId}", async () => {
    return;
});
