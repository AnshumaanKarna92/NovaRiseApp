const axios = require('axios');

const PROJECT_ID = 'novariseapp';
const API_KEY = 'AIzaSyCfgJ6lMceYwWlZsKEWfGakslqXOMrcqiM';
const EMAIL = 'master@novarise.com';
const PASSWORD = 'password123';

async function auditTeacher() {
  try {
    console.log('--- Authenticating ---');
    const loginUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`;
    const loginRes = await axios.post(loginUrl, { email: EMAIL, password: PASSWORD, returnSecureToken: true });
    const idToken = loginRes.data.idToken;
    console.log('   Authenticated.');

    const targetEmail = 'teacher@novarise.com';
    console.log(`--- Auditing ${targetEmail} ---`);
    const queryUrl = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:runQuery`;
    
    // 1. Find User UID
    const userQuery = {
      structuredQuery: {
        from: [{ collectionId: 'users' }],
        where: {
          fieldFilter: {
            field: { fieldPath: 'email' },
            op: 'EQUAL',
            value: { stringValue: targetEmail }
          }
        }
      }
    };
    const userRes = await axios.post(queryUrl, userQuery, { headers: { Authorization: `Bearer ${idToken}` } });
    if (!userRes.data || !userRes.data[0]?.document) {
      console.log('   User not found.');
      return;
    }
    const userUid = userRes.data[0].document.name.split('/').pop();
    const userSchoolId = userRes.data[0].document.fields.schoolId.stringValue;
    console.log(`   UID: ${userUid}`);
    console.log(`   SchoolID: ${userSchoolId}`);

    // 2. Find Classes in that school
    console.log('--- Auditing School Classes ---');
    const classQuery = {
      structuredQuery: {
        from: [{ collectionId: 'classes' }],
        where: {
          fieldFilter: {
            field: { fieldPath: 'schoolId' },
            op: 'EQUAL',
            value: { stringValue: userSchoolId }
          }
        }
      }
    };
    const classRes = await axios.post(queryUrl, classQuery, { headers: { Authorization: `Bearer ${idToken}` } });
    
    for (const res of (classRes.data || [])) {
      if (!res.document) continue;
      const doc = res.document;
      const data = doc.fields;
      const classId = doc.name.split('/').pop();
      const className = data.name?.stringValue || classId;
      const classTeacher = data.classTeacherId?.stringValue || '';
      
      console.log(`Class: ${classId} (${className})`);
      console.log(`  Class Teacher: ${classTeacher}`);
      if (classTeacher === userUid) console.log('  -> MATCH: Is Class Teacher');
      
      const subjects = data.subjects?.mapValue?.fields || {};
      for (const [sub, val] of Object.entries(subjects)) {
        if (val.stringValue === userUid) {
          console.log(`  -> MATCH: Is Subject Teacher for ${sub}`);
        }
      }
    }

  } catch (error) {
    console.error('❌ AUDIT FAILED!');
    if (error.response) {
      console.error(JSON.stringify(error.response.data, null, 2));
    } else {
      console.error(error.message);
    }
  }
}

auditTeacher();
