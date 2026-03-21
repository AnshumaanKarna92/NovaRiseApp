const admin = require('firebase-admin');

// Hardcoded project ID to avoid environmental detection issues
admin.initializeApp({
  projectId: 'novariseapp'
});

const db = admin.firestore();
const auth = admin.auth();

async function setupAccount(email, password, role, displayName) {
  let uid;
  try {
    const user = await auth.getUserByEmail(email);
    uid = user.uid;
    await auth.updateUser(uid, { password });
    console.log(`✅ Updated password for: ${email}`);
  } catch (e) {
    if (e.code === 'auth/user-not-found') {
      const user = await auth.createUser({
        email,
        password,
        displayName,
      });
      uid = user.uid;
      console.log(`✨ Created new account: ${email}`);
    } else {
      throw e;
    }
  }

  // Set Custom Claims
  await auth.setCustomUserClaims(uid, { role });

  // Sync Firestore Profile
  await db.collection('users').doc(uid).set({
    uid,
    email,
    role,
    displayName,
    schoolId: 'school_001',
    status: 'active',
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  }, { merge: true });

  console.log(`🚀 Profile Synced: ${email} as ${role.toUpperCase()}`);
}

async function start() {
  console.log('--- RESETTING ACCOUNTS ---');
  try {
    await setupAccount('admin@novarise.com', 'admin123', 'admin', 'Administrator');
    await setupAccount('teacher@novarise.com', 'teacher123', 'teacher', 'Teacher User');
    await setupAccount('parent@novarise.com', 'parent123', 'parent', 'Parent User');
    console.log('--- ALL ACCOUNTS READY ---');
    process.exit(0);
  } catch (err) {
    console.error('❌ Failed:', err);
    process.exit(1);
  }
}

start();
