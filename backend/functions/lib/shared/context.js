"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getRequestContext = getRequestContext;
exports.requireRole = requireRole;
const firebase_js_1 = require("../config/firebase.js");
const errors_js_1 = require("./errors.js");
async function getRequestContext(request) {
    if (!request.auth?.uid) {
        (0, errors_js_1.forbidden)("Authentication required");
    }
    const snapshot = await firebase_js_1.db.collection("users").doc(request.auth.uid).get();
    if (!snapshot.exists) {
        (0, errors_js_1.forbidden)("User profile not found");
    }
    const data = snapshot.data();
    return {
        uid: request.auth.uid,
        role: data.role,
        schoolId: data.schoolId,
    };
}
function requireRole(context, allowed) {
    if (!allowed.includes(context.role)) {
        (0, errors_js_1.forbidden)("Insufficient permissions");
    }
}
