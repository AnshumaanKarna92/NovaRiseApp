const admin = require('firebase-admin');
if (admin.apps.length === 0) admin.initializeApp();

async function reset() {
  const accounts = [
    { email: 'admin@novarise.com', password: 'admin123' },
    { email: 'test_admin@novarise.com', password: 'password123' },
    { email: 'parent@novarise.com', password: 'parent123' },
    { email: 'teacher@novarise.com', password: 'teacher123' }
  ];

  for (const acc of accounts) {
    try {
      const user = await admin.auth().getUserByEmail(acc.email);
      await admin.auth().updateUser(user.uid, { password: acc.password });
      console.log(`Password reset for ${acc.email} to ${acc.password}`);
      
      // Also ensure role and Firestore profile
      let role = 'parent';
      if (acc.email.includes('admin')) role = 'admin';
      if (acc.email.includes('teacher')) role = 'teacher';
      
      await admin.auth().setCustomUserClaims(user.uid, { role });
      await admin.firestore().collection('users').doc(user.uid).set({
        uid: user.uid,
        email: acc.email,
        role: role,
        displayName: acc.email.split('@')[0],
        schoolId: 'school_001',
        status: 'active',
        updatedAt: admin.firestore.FieldValue.serverTimestamp()
      }, { merge: true });
      
    } catch (e) {
      if (e.code === 'auth/user-not-found') {
        const user = await admin.auth().createUser({
          email: acc.email,
          password: acc.password,
          displayName: acc.email.split('@')[0]
        });
        console.log(`Created user ${acc.email} with password ${acc.password}`);
        let role = 'parent';
        if (acc.email.includes('admin')) role = 'admin';
        if (acc.email.includes('teacher')) role = 'teacher';
        await admin.auth().setCustomUserClaims(user.uid, { role });
        await admin.firestore().collection('users').doc(user.uid).set({
          uid: user.uid,
          email: acc.email,
          role: role,
          displayName: acc.email.split('@')[0],
          schoolId: 'school_001',
          status: 'active',
          updatedAt: admin.firestore.FieldValue.serverTimestamp()
        });
      } else {
        console.error(`Error for ${acc.email}: ${e.message}`);
      }
    }
  }
}
reset();
