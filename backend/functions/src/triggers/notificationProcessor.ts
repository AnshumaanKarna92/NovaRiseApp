import { onDocumentCreated } from "firebase-functions/firestore";

export const notificationJobCreated = onDocumentCreated(
  "notification_jobs/{jobId}",
  async () => {
    return;
  },
);
