import { HttpsError } from "firebase-functions/https";

export function forbidden(message = "Forbidden"): never {
  throw new HttpsError("permission-denied", message);
}

export function badRequest(message: string): never {
  throw new HttpsError("invalid-argument", message);
}
