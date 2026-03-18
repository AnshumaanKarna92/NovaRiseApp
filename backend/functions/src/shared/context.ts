import { CallableRequest } from "firebase-functions/https";

import { db } from "../config/firebase.js";
import { forbidden } from "./errors.js";
import type { RequestContext, UserRole } from "./types.js";

export async function getRequestContext(
  request: CallableRequest<unknown>,
): Promise<RequestContext> {
  if (!request.auth?.uid) {
    forbidden("Authentication required");
  }

  const snapshot = await db.collection("users").doc(request.auth.uid).get();
  if (!snapshot.exists) {
    forbidden("User profile not found");
  }

  const data = snapshot.data() as { role: UserRole; schoolId: string };
  return {
    uid: request.auth.uid,
    role: data.role,
    schoolId: data.schoolId,
  };
}

export function requireRole(context: RequestContext, allowed: UserRole[]): void {
  if (!allowed.includes(context.role)) {
    forbidden("Insufficient permissions");
  }
}
