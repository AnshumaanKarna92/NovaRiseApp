const admin = require('firebase-admin');

// Using the service account is too complex here, 
// so we'll try to use the default credential from the environment.
// On this machine, 'firebase login' has been run, so this might work.
admin.initializeApp({
  projectId: 'novariseapp'
});

async function run() {
  const email = 'finaltest@novarise.com';
  const password = 'password123';
  
  try {
    // Delete if exists to be sure
    try {
      const existing = await admin.auth().getUserByEmail(email);
      await admin.auth().deleteUser(existing.uid);
      console.log('Cleaned up existing user');
    } catch (e) {}

    const user = await admin.auth().createUser({
      email,
      password,
      displayName: 'Final Test User'
    });
    
    console.log('--- SUCCESS ---');
    console.log(`Email: ${email}`);
    console.log(`Password: ${password}`);
    console.log(`UID: ${user.uid}`);
    
    // Set custom claim for admin so we can see stuff
    await admin.auth().setCustomUserClaims(user.uid, { role: 'admin' });
    
    // Create Firestore profile
    await admin.firestore().collection('users').doc(user.uid).set({
      uid: user.uid,
      email: email,
      role: 'admin',
      displayName: 'Final Test User',
      schoolId: 'school_001',
      status: 'active'
    });
    
    console.log('Firestore profile created.');
    process.exit(0);
  } catch (err) {
    console.error('FAILED:', err);
    process.exit(1);
  }
}

run();
