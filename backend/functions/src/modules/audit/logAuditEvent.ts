import { Timestamp } from "firebase-admin/firestore";

import { db } from "../../config/firebase.js";
import type { RequestContext } from "../../shared/types.js";

interface AuditEventInput {
  actor: RequestContext;
  action: string;
  entityType: string;
  entityId: string;
  before?: unknown;
  after?: unknown;
  reason?: string;
}

export async function logAuditEvent(input: AuditEventInput): Promise<void> {
  await db.collection("audit_logs").add({
    schoolId: input.actor.schoolId,
    actorUid: input.actor.uid,
    actorRole: input.actor.role,
    action: input.action,
    entityType: input.entityType,
    entityId: input.entityId,
    before: input.before ?? null,
    after: input.after ?? null,
    reason: input.reason ?? "",
    createdAt: Timestamp.now(),
  });
}
