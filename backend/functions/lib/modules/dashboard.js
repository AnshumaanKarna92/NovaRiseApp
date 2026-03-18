"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getDashboardSummaries = void 0;
const https_1 = require("firebase-functions/https");
const firebase_js_1 = require("../config/firebase.js");
const context_js_1 = require("../shared/context.js");
exports.getDashboardSummaries = (0, https_1.onCall)(async (request) => {
    const context = await (0, context_js_1.getRequestContext)(request);
    (0, context_js_1.requireRole)(context, ["admin"]);
    const [pendingPayments, notices, messages] = await Promise.all([
        firebase_js_1.db
            .collection("fee_payments")
            .where("schoolId", "==", context.schoolId)
            .where("status", "==", "pending_verification")
            .count()
            .get(),
        firebase_js_1.db.collection("notices").where("schoolId", "==", context.schoolId).count().get(),
        firebase_js_1.db.collection("messages").where("schoolId", "==", context.schoolId).count().get(),
    ]);
    return {
        pendingFees: pendingPayments.data().count,
        notices: notices.data().count,
        messages: messages.data().count,
    };
});
