import { Timestamp } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/https";
import { z } from "zod";

import { db } from "../../config/firebase.js";
import { getRequestContext, requireRole } from "../../shared/context.js";
import { badRequest } from "../../shared/errors.js";
import { logAuditEvent } from "../audit/logAuditEvent.js";
import { queueNotificationJob } from "../notifications/notificationService.js";

const receiptSchema = z.object({
  invoiceId: z.string().min(1),
  studentId: z.string().min(1),
  paymentMethod: z.enum(["upi", "cash"]),
  clientReference: z.string().optional(),
  screenshotUrl: z.string().min(1),
});

const verifySchema = z.object({
  paymentId: z.string().min(1),
  decision: z.enum(["verified", "rejected"]),
  notes: z.string().default(""),
});

const cashSchema = z.object({
  studentId: z.string().min(1),
  invoiceIds: z.array(z.string()).min(1),
  amount: z.number().positive(),
  paymentDate: z.string().min(1),
  collectorId: z.string().min(1),
  attachmentUrl: z.string().optional(),
});

export const createOrUpdateFeeReceipt = onCall(async (request) => {
  const context = await getRequestContext(request);
  requireRole(context, ["parent"]);

  const payload = receiptSchema.parse(request.data);
  const invoiceRef = db.collection("fee_invoices").doc(payload.invoiceId);
  const invoiceSnapshot = await invoiceRef.get();
  if (!invoiceSnapshot.exists) {
    badRequest("Invoice not found");
  }

  const paymentRef = db.collection("fee_payments").doc();
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
    uploadedAt: Timestamp.now(),
    verifiedByUid: null,
    verifiedAt: null,
    rejectionReason: "",
    notes: "",
    futureGatewayRef: null,
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  };

  await paymentRef.set(payment);
  await invoiceRef.update({
    paymentStatus: "pending_verification",
    updatedAt: Timestamp.now(),
  });

  await logAuditEvent({
    actor: context,
    action: "fee_receipt_submitted",
    entityType: "fee_payments",
    entityId: paymentRef.id,
    after: payment,
  });

  await queueNotificationJob({
    schoolId: context.schoolId,
    type: "fee_receipt_submitted",
    targetMode: "all",
    targetIds: [],
    payload: { paymentId: paymentRef.id, invoiceId: payload.invoiceId },
  });

  return payment;
});

export const verifyFeePayment = onCall(async (request) => {
  const context = await getRequestContext(request);
  requireRole(context, ["admin"]);

  const payload = verifySchema.parse(request.data);
  const paymentRef = db.collection("fee_payments").doc(payload.paymentId);
  const paymentSnapshot = await paymentRef.get();
  if (!paymentSnapshot.exists) {
    badRequest("Payment not found");
  }

  const before = paymentSnapshot.data();
  await paymentRef.update({
    status: payload.decision,
    notes: payload.notes,
    rejectionReason: payload.decision == "rejected" ? payload.notes : "",
    verifiedByUid: context.uid,
    verifiedAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  });

  const invoiceId = before?.invoiceId as string | undefined;
  if (invoiceId != null) {
    await db.collection("fee_invoices").doc(invoiceId).update({
      status: payload.decision === "verified" ? "paid" : "unpaid",
      paymentStatus: payload.decision,
      updatedAt: Timestamp.now(),
    });
  }

  await logAuditEvent({
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

export const recordCashPayment = onCall(async (request) => {
  const context = await getRequestContext(request);
  requireRole(context, ["admin", "cash_collector"]);

  const payload = cashSchema.parse(request.data);
  const paymentRef = db.collection("fee_payments").doc();
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
    uploadedAt: Timestamp.now(),
    verifiedByUid: context.uid,
    verifiedAt: Timestamp.now(),
    rejectionReason: "",
    notes: "Cash payment recorded",
    futureGatewayRef: null,
    recordedByUid: context.uid,
    paymentDate: payload.paymentDate,
    createdAt: Timestamp.now(),
    updatedAt: Timestamp.now(),
  };

  await paymentRef.set(payment);
  await Promise.all(
    payload.invoiceIds.map((invoiceId) =>
      db.collection("fee_invoices").doc(invoiceId).update({
        status: "paid",
        paymentStatus: "verified",
        updatedAt: Timestamp.now(),
      }),
    ),
  );

  await logAuditEvent({
    actor: context,
    action: "cash_payment_recorded",
    entityType: "fee_payments",
    entityId: paymentRef.id,
    after: payment,
  });

  return payment;
});
