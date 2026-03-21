const admin = require('firebase-admin');
const fs = require('fs');

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: "nova-rise-academy" // Based on context
  });
}

const db = admin.firestore();

async function checkAccountSecurity() {
  const users = [
    "C3oG89LOKLSvlvb6wLzLQteAwwk2", // Admin
    "5qk9fN1qaHQbqEIuuQcogL1ifPa2", // Teacher
    "aFPiSswA3yRjIjMHO1zqEtfHfcY2"  // Parent
  ];

  for (const uid of users) {
    const snap = await db.collection("users").doc(uid).get();
    if (snap.exists) {
      console.log(`User ${uid}:`, snap.data());
    } else {
      console.log(`User ${uid} not found in Firestore`);
    }
  }
}

checkAccountSecurity();
