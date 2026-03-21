const axios = require('axios');

const PROJECT_ID = 'novariseapp';
const API_KEY = 'AIzaSyCfgJ6lMceYwWlZsKEWfGakslqXOMrcqiM';
const EMAIL = 'master@novarise.com';
const PASSWORD = 'password123';

async function fix10A() {
  try {
    console.log('--- Authenticating ---');
    const loginUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`;
    const loginRes = await axios.post(loginUrl, { email: EMAIL, password: PASSWORD, returnSecureToken: true });
    const idToken = loginRes.data.idToken;
    console.log('   Authenticated.');

    const teacherUid = '3m1mY3cdUsfwps0Ncs55KwosvwX2'; // teacher@novarise.com
    const classId = '10A';

    console.log(`--- Fixing Class ${classId} ---`);
    const updateUrl = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/classes/${classId}?updateMask.fieldPaths=classTeacherId`;
    
    await axios.patch(updateUrl, {
      fields: {
        classTeacherId: { stringValue: teacherUid }
      }
    }, {
      headers: { Authorization: `Bearer ${idToken}` }
    });

    console.log(`   Successfully assigned teacher@novarise.com as Class Teacher of ${classId}.`);
  } catch (error) {
    console.error('❌ FIX FAILED!');
    if (error.response) {
      console.error(JSON.stringify(error.response.data, null, 2));
    } else {
      console.error(error.message);
    }
  }
}

fix10A();
