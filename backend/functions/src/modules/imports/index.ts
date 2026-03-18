import { Timestamp } from "firebase-admin/firestore";
import { onRequest } from "firebase-functions/https";

import { db } from "../../config/firebase.js";

export const importStudentsCsv = onRequest(async (request, response) => {
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
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  });

  response.status(202).json({ jobId: jobRef.id });
});
