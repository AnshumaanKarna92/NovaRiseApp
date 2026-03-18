const axios = require('axios');

const PROJECT_ID = 'novariseapp';
const API_KEY = 'AIzaSyCfgJ6lMceYwWlZsKEWfGakslqXOMrcqiM';

async function setupAdmin() {
  const email = 'master@novarise.com';
  const password = 'password123';

  console.log(`--- Setting up Master Admin: ${email} ---`);

  try {
    // 1. Signup / Signin to get ID Token
    console.log('1. Authenticating...');
    let idToken;
    let uid;
    try {
      const authUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`;
      const authRes = await axios.post(authUrl, { email, password, returnSecureToken: true });
      idToken = authRes.data.idToken;
      uid = authRes.data.localId;
      console.log('   New account created.');
    } catch (e) {
      if (e.response && e.response.data.error.message === 'EMAIL_EXISTS') {
        console.log('   Account exists, signing in...');
        const loginUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`;
        const loginRes = await axios.post(loginUrl, { email, password, returnSecureToken: true });
        idToken = loginRes.data.idToken;
        uid = loginRes.data.localId;
      } else {
        throw e;
      }
    }

    // 2. Create Firestore Profile
    console.log('2. Creating Firestore Profile...');
    const firestoreUrl = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users?documentId=${uid}`;
    
    const profile = {
      fields: {
        uid: { stringValue: uid },
        email: { stringValue: email },
        role: { stringValue: 'admin' },
        displayName: { stringValue: 'Master Admin' },
        schoolId: { stringValue: 'school_001' },
        status: { stringValue: 'active' },
        createdAt: { timestampValue: new Date().toISOString() }
      }
    };

    try {
      await axios.post(firestoreUrl, profile, {
        headers: { Authorization: `Bearer ${idToken}` }
      });
      console.log('   Profile created successfully.');
    } catch (e) {
      if (e.response && e.response.status === 409) {
        console.log('   Profile already exists, updating...');
        const updateUrl = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}?updateMask.fieldPaths=role&updateMask.fieldPaths=status`;
        await axios.patch(updateUrl, profile, {
          headers: { Authorization: `Bearer ${idToken}` }
        });
      } else {
        throw e;
      }
    }

    console.log('--- ALL DONE ---');
    console.log(`Login Email: ${email}`);
    console.log(`Password: ${password}`);

  } catch (error) {
    console.log('❌ FAILED!');
    if (error.response) {
      console.log(JSON.stringify(error.response.data, null, 2));
    } else {
      console.log(error.message);
    }
  }
}

setupAdmin();
