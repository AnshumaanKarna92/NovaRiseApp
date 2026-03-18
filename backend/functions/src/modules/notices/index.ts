import { Timestamp } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/https";
import { z } from "zod";

import { db } from "../../config/firebase.js";
import { getRequestContext, requireRole } from "../../shared/context.js";
import { logAuditEvent } from "../audit/logAuditEvent.js";
import { queueNotificationJob } from "../notifications/notificationService.js";

const schema = z.object({
  title: z.string().min(1),
  body: z.string().min(1),
  attachmentUrls: z.array(z.string()).default([]),
  targetType: z.enum(["all", "classes"]),
  targetClassIds: z.array(z.string()).default([]),
  startAt: z.string().min(1),
  expiresAt: z.string().min(1),
});

export const publishNotice = onCall(async (request) => {
  const context = await getRequestContext(request);
  requireRole(context, ["admin"]);

  const payload = schema.parse(request.data);
  const ref = db.collection("notices").doc();
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
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  };

  await ref.set(notice);
  await logAuditEvent({
    actor: context,
    action: "notice_published",
    entityType: "notices",
    entityId: ref.id,
    after: notice,
  });

  await queueNotificationJob({
    schoolId: context.schoolId,
    type: "notice_published",
    targetMode: payload.targetType === "all" ? "all" : "class",
    targetIds: payload.targetClassIds,
    payload: { noticeId: ref.id, title: payload.title },
  });

  return notice;
});
