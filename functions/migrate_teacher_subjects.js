const axios = require('axios');

const PROJECT_ID = 'novariseapp';
const API_KEY = 'AIzaSyCfgJ6lMceYwWlZsKEWfGakslqXOMrcqiM';
const EMAIL = 'master@novarise.com';
const PASSWORD = 'password123';

async function migrateTeachers() {
  try {
    console.log('--- Authenticating ---');
    const loginUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`;
    const loginRes = await axios.post(loginUrl, { email: EMAIL, password: PASSWORD, returnSecureToken: true });
    const idToken = loginRes.data.idToken;
    console.log('   Authenticated.');

    console.log('--- Querying Teachers ---');
    const queryUrl = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents:runQuery`;
    const queryBody = {
      structuredQuery: {
        from: [{ collectionId: 'users' }],
        where: {
          fieldFilter: {
            field: { fieldPath: 'role' },
            op: 'EQUAL',
            value: { stringValue: 'teacher' }
          }
        }
      }
    };

    const queryRes = await axios.post(queryUrl, queryBody, {
      headers: { Authorization: `Bearer ${idToken}` }
    });

    const results = queryRes.data;
    console.log(`   Found ${results.length} teacher records.`);

    for (const res of results) {
      if (!res.document) continue;
      const doc = res.document;
      const data = doc.fields;
      const uid = doc.name.split('/').pop();
      const displayName = data.displayName?.stringValue || 'Unknown';

      if (!data.primarySubject) {
        console.log(`   Updating teacher: ${displayName} (${uid})...`);
        const updateUrl = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}?updateMask.fieldPaths=primarySubject`;
        
        await axios.patch(updateUrl, {
          fields: {
            primarySubject: { stringValue: 'General Education' }
          }
        }, {
          headers: { Authorization: `Bearer ${idToken}` }
        });
      } else {
        console.log(`   Teacher ${displayName} already has primary subject: ${data.primarySubject.stringValue}`);
      }
    }

    console.log('--- MIGRATION COMPLETE ---');
  } catch (error) {
    console.error('❌ MIGRATION FAILED!');
    if (error.response) {
      console.error(JSON.stringify(error.response.data, null, 2));
    } else {
      console.error(error.message);
    }
  }
}

migrateTeachers();
