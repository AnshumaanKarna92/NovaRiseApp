const axios = require('axios');

const PROJECT_ID = 'novariseapp';
const API_KEY = 'AIzaSyCfgJ6lMceYwWlZsKEWfGakslqXOMrcqiM';

async function setupUser(email, password, role, displayName) {
  console.log(`\n--- Setting up ${displayName} (${role}) ---`);

  try {
    // 1. Signup / Signin
    let idToken;
    let uid;
    try {
      const authUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`;
      const authRes = await axios.post(authUrl, { email, password, returnSecureToken: true });
      idToken = authRes.data.idToken;
      uid = authRes.data.localId;
      console.log('   Auth: Account created.');
    } catch (e) {
      if (e.response && e.response.data.error.message === 'EMAIL_EXISTS') {
        const loginUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`;
        const loginRes = await axios.post(loginUrl, { email, password, returnSecureToken: true });
        idToken = loginRes.data.idToken;
        uid = loginRes.data.localId;
        console.log('   Auth: User signed in.');
      } else {
        throw e;
      }
    }

    // 2. Create/Update Firestore Profile
    const firestoreUrl = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}`;
    
    const profile = {
      fields: {
        uid: { stringValue: uid },
        email: { stringValue: email },
        role: { stringValue: role },
        displayName: { stringValue: displayName },
        schoolId: { stringValue: 'school_001' },
        status: { stringValue: 'active' }
      }
    };

    try {
      await axios.patch(firestoreUrl, profile, {
        headers: { Authorization: `Bearer ${idToken}` }
      });
      console.log('   Firestore: Profile created/updated.');
    } catch (e) {
      throw e;
    }

  } catch (error) {
    console.log('❌ FAILED!');
    if (error.response) {
      console.log(JSON.stringify(error.response.data, null, 2));
    } else {
      console.log(error.message);
    }
  }
}

async function run() {
  await setupUser('master@novarise.com', 'password123', 'admin', 'School Administrator');
  await setupUser('teacher@novarise.com', 'password123', 'teacher', 'Teacher User');
  await setupUser('parent@novarise.com', 'password123', 'parent', 'Parent User');
  console.log('\n--- SYSTEM SEEDED SUCCESSFULLY ---');
}

run();
