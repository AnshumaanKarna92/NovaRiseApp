"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.importStudentsCsv = void 0;
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/https");
const firebase_js_1 = require("../../config/firebase.js");
exports.importStudentsCsv = (0, https_1.onRequest)(async (request, response) => {
    if (request.method !== "POST") {
        response.status(405).send("Method not allowed");
        return;
    }
    const schoolId = String(request.body.schoolId ?? "");
    const fileUrl = String(request.body.fileUrl ?? "");
    const createdByUid = String(request.body.createdByUid ?? "");
    if (!schoolId || !fileUrl || !createdByUid) {
        response.status(400).json({ error: "schoolId, fileUrl, and createdByUid are required" });
        return;
    }
    const jobRef = firebase_js_1.db.collection("import_jobs").doc();
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
        createdAt: firestore_1.Timestamp.now(),
        updatedAt: firestore_1.Timestamp.now(),
    });
    response.status(202).json({ jobId: jobRef.id });
});
