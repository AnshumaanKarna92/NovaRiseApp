"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.forbidden = forbidden;
exports.badRequest = badRequest;
const https_1 = require("firebase-functions/https");
function forbidden(message = "Forbidden") {
    throw new https_1.HttpsError("permission-denied", message);
}
function badRequest(message) {
    throw new https_1.HttpsError("invalid-argument", message);
}
