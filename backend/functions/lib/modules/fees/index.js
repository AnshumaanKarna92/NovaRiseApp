"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.recordCashPayment = exports.verifyFeePayment = exports.createOrUpdateFeeReceipt = void 0;
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/https");
const zod_1 = require("zod");
const firebase_js_1 = require("../../config/firebase.js");
const context_js_1 = require("../../shared/context.js");
const errors_js_1 = require("../../shared/errors.js");
const logAuditEvent_js_1 = require("../audit/logAuditEvent.js");
const notificationService_js_1 = require("../notifications/notificationService.js");
const receiptSchema = zod_1.z.object({
    invoiceId: zod_1.z.string().min(1),
    studentId: zod_1.z.string().min(1),
    paymentMethod: zod_1.z.enum(["upi", "cash"]),
    clientReference: zod_1.z.string().optional(),
    screenshotUrl: zod_1.z.string().min(1),
});
const verifySchema = zod_1.z.object({
    paymentId: zod_1.z.string().min(1),
    decision: zod_1.z.enum(["verified", "rejected"]),
    notes: zod_1.z.string().default(""),
});
const cashSchema = zod_1.z.object({
    studentId: zod_1.z.string().min(1),
    invoiceIds: zod_1.z.array(zod_1.z.string()).min(1),
    amount: zod_1.z.number().positive(),
    paymentDate: zod_1.z.string().min(1),
    collectorId: zod_1.z.string().min(1),
    attachmentUrl: zod_1.z.string().optional(),
});
exports.createOrUpdateFeeReceipt = (0, https_1.onCall)(async (request) => {
    const context = await (0, context_js_1.getRequestContext)(request);
    (0, context_js_1.requireRole)(context, ["parent"]);
    const payload = receiptSchema.parse(request.data);
    const invoiceRef = firebase_js_1.db.collection("fee_invoices").doc(payload.invoiceId);
    const invoiceSnapshot = await invoiceRef.get();
    if (!invoiceSnapshot.exists) {
        (0, errors_js_1.badRequest)("Invoice not found");
    }
    const paymentRef = firebase_js_1.db.collection("fee_payments").doc();
    const payment = {
        paymentId: paymentRef.id,
        schoolId: context.schoolId,
        invoiceId: payload.invoiceId,
        studentId: payload.studentId,
        amount: invoiceSnapshot.data()?.amount ?? 0,
        paymentMethod: payload.paymentMethod,
        submissionChannel: "mobile_upload",
        status: "pending_verification",
        screenshotUrl: payload.screenshotUrl,
        clientReference: payload.clientReference ?? "",
        uploadedByUid: context.uid,
        uploadedAt: firestore_1.Timestamp.now(),
        verifiedByUid: null,
        verifiedAt: null,
        rejectionReason: "",
        notes: "",
        futureGatewayRef: null,
        createdAt: firestore_1.Timestamp.now(),
        updatedAt: firestore_1.Timestamp.now(),
    };
    await paymentRef.set(payment);
    await invoiceRef.update({
        paymentStatus: "pending_verification",
        updatedAt: firestore_1.Timestamp.now(),
    });
    await (0, logAuditEvent_js_1.logAuditEvent)({
        actor: context,
        action: "fee_receipt_submitted",
        entityType: "fee_payments",
        entityId: paymentRef.id,
        after: payment,
    });
    await (0, notificationService_js_1.queueNotificationJob)({
        schoolId: context.schoolId,
        type: "fee_receipt_submitted",
        targetMode: "all",
        targetIds: [],
        payload: { paymentId: paymentRef.id, invoiceId: payload.invoiceId },
    });
    return payment;
});
exports.verifyFeePayment = (0, https_1.onCall)(async (request) => {
    const context = await (0, context_js_1.getRequestContext)(request);
    (0, context_js_1.requireRole)(context, ["admin"]);
    const payload = verifySchema.parse(request.data);
    const paymentRef = firebase_js_1.db.collection("fee_payments").doc(payload.paymentId);
    const paymentSnapshot = await paymentRef.get();
    if (!paymentSnapshot.exists) {
        (0, errors_js_1.badRequest)("Payment not found");
    }
    const before = paymentSnapshot.data();
    await paymentRef.update({
        status: payload.decision,
        notes: payload.notes,
        rejectionReason: payload.decision == "rejected" ? payload.notes : "",
        verifiedByUid: context.uid,
        verifiedAt: firestore_1.Timestamp.now(),
        updatedAt: firestore_1.Timestamp.now(),
    });
    const invoiceId = before?.invoiceId;
    if (invoiceId != null) {
        await firebase_js_1.db.collection("fee_invoices").doc(invoiceId).update({
            status: payload.decision === "verified" ? "paid" : "unpaid",
            paymentStatus: payload.decision,
            updatedAt: firestore_1.Timestamp.now(),
        });
    }
    await (0, logAuditEvent_js_1.logAuditEvent)({
        actor: context,
        action: `fee_payment_${payload.decision}`,
        entityType: "fee_payments",
        entityId: payload.paymentId,
        before,
        after: { ...before, status: payload.decision },
        reason: payload.notes,
    });
    return { paymentId: payload.paymentId, status: payload.decision };
});
exports.recordCashPayment = (0, https_1.onCall)(async (request) => {
    const context = await (0, context_js_1.getRequestContext)(request);
    (0, context_js_1.requireRole)(context, ["admin", "cash_collector"]);
    const payload = cashSchema.parse(request.data);
    const paymentRef = firebase_js_1.db.collection("fee_payments").doc();
    const payment = {
        paymentId: paymentRef.id,
        schoolId: context.schoolId,
        invoiceIds: payload.invoiceIds,
        studentId: payload.studentId,
        amount: payload.amount,
        paymentMethod: "cash",
        submissionChannel: "staff_entry",
        status: "verified",
        screenshotUrl: payload.attachmentUrl ?? "",
        clientReference: payload.collectorId,
        uploadedByUid: context.uid,
        uploadedAt: firestore_1.Timestamp.now(),
        verifiedByUid: context.uid,
        verifiedAt: firestore_1.Timestamp.now(),
        rejectionReason: "",
        notes: "Cash payment recorded",
        futureGatewayRef: null,
        recordedByUid: context.uid,
        paymentDate: payload.paymentDate,
        createdAt: firestore_1.Timestamp.now(),
        updatedAt: firestore_1.Timestamp.now(),
    };
    await paymentRef.set(payment);
    await Promise.all(payload.invoiceIds.map((invoiceId) => firebase_js_1.db.collection("fee_invoices").doc(invoiceId).update({
        status: "paid",
        paymentStatus: "verified",
        updatedAt: firestore_1.Timestamp.now(),
    })));
    await (0, logAuditEvent_js_1.logAuditEvent)({
        actor: context,
        action: "cash_payment_recorded",
        entityType: "fee_payments",
        entityId: paymentRef.id,
        after: payment,
    });
    return payment;
});
