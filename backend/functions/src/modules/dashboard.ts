import { onCall } from "firebase-functions/https";

import { db } from "../config/firebase.js";
import { getRequestContext, requireRole } from "../shared/context.js";

export const getDashboardSummaries = onCall(async (request) => {
  const context = await getRequestContext(request);
  requireRole(context, ["admin"]);

  const [pendingPayments, notices, messages] = await Promise.all([
    db
      .collection("fee_payments")
      .where("schoolId", "==", context.schoolId)
      .where("status", "==", "pending_verification")
      .count()
      .get(),
    db.collection("notices").where("schoolId", "==", context.schoolId).count().get(),
    db.collection("messages").where("schoolId", "==", context.schoolId).count().get(),
  ]);

  return {
    pendingFees: pendingPayments.data().count,
    notices: notices.data().count,
    messages: messages.data().count,
  };
});
