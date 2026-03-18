import { Timestamp } from "firebase-admin/firestore";

import { db } from "../../config/firebase.js";

interface NotificationJobInput {
  schoolId: string;
  type: string;
  targetMode: "student" | "class" | "all";
  targetIds: string[];
  payload: Record<string, unknown>;
  channel?: "push" | "sms";
}

export async function queueNotificationJob(
  input: NotificationJobInput,
): Promise<void> {
  await db.collection("notification_jobs").add({
    schoolId: input.schoolId,
    type: input.type,
    targetMode: input.targetMode,
    targetIds: input.targetIds,
    payload: input.payload,
    channel: input.channel ?? "push",
    status: "queued",
    createdAt: Timestamp.now(),
    processedAt: null,
  });
}
