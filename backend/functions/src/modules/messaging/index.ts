import { Timestamp } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/https";
import { z } from "zod";

import { db } from "../../config/firebase.js";
import { getRequestContext, requireRole } from "../../shared/context.js";
import { logAuditEvent } from "../audit/logAuditEvent.js";
import { queueNotificationJob } from "../notifications/notificationService.js";

const schema = z.object({
  classId: z.string().min(1),
  type: z.enum(["message", "homework"]),
  text: z.string().min(1),
  attachmentUrls: z.array(z.string()).default([]),
  dueDate: z.string().optional(),
});

export const createClassMessage = onCall(async (request) => {
  const context = await getRequestContext(request);
  requireRole(context, ["teacher", "admin"]);

  const payload = schema.parse(request.data);
  const ref = db.collection("messages").doc();
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
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  };

  await ref.set(message);
  await logAuditEvent({
    actor: context,
    action: `${payload.type}_created`,
    entityType: "messages",
    entityId: ref.id,
    after: message,
  });

  await queueNotificationJob({
    schoolId: context.schoolId,
    type: payload.type === "homework" ? "homework_posted" : "class_message_posted",
    targetMode: "class",
    targetIds: [payload.classId],
    payload: { messageId: ref.id },
  });

  return message;
});
