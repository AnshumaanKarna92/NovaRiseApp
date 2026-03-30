const axios = require('axios');

const PROJECT_ID = 'novariseapp';
const API_KEY = 'AIzaSyCfgJ6lMceYwWlZsKEWfGakslqXOMrcqiM';

const facultyData = [
  { name: 'Rahul Shaikh', subject: 'Psc.', phone: '8906259203' },
  { name: 'Abu Sufian', subject: 'English', phone: '6296918741' },
  { name: 'Abu shoyiab', subject: 'Computer+Maths', phone: '9378422115' },
  { name: 'Avhijit Sarkar', subject: 'Spoken English', phone: '9126539909' },
  { name: 'Mintu sir', subject: 'Math class-5 to 8', phone: '7872789594' },
  { name: 'Md Jahir sk', subject: 'hostel management', phone: '8116992456' },
  { name: 'Md Zunaid', subject: 'Psc.', phone: '7076692202' },
  { name: 'Md Munjur hossain', subject: 'History', phone: '8101795192' },
];

async function seedFaculty() {
  console.log(`--- Seeding ${facultyData.length} Faculty Members ---`);

  for (const faculty of facultyData) {
    const identifier = faculty.phone;
    // We create for all 3 branches to ensure they can log in regardless of selection
    const branches = ['boys', 'girls', 'overall'];
    
    for (const branch of branches) {
      const email = `${identifier}.${branch}@novarise.com`.toLowerCase();
      const password = 'password123';

      console.log(`Processing: ${faculty.name} (${email})...`);

      try {
        // 1. Create/Login Auth Account
        let idToken;
        let uid;
        try {
          const signupUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`;
          const signupRes = await axios.post(signupUrl, { email, password, returnSecureToken: true });
          idToken = signupRes.data.idToken;
          uid = signupRes.data.localId;
          console.log(`   Auth account created: ${uid}`);
        } catch (e) {
          if (e.response && e.response.data.error.message === 'EMAIL_EXISTS') {
            console.log('   Auth account exists, signing in...');
            const loginUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`;
            const loginRes = await axios.post(loginUrl, { email, password, returnSecureToken: true });
            idToken = loginRes.data.idToken;
            uid = loginRes.data.localId;
          } else {
            throw e;
          }
        }

        // 2. Create/Update Firestore Profile
        const firestoreUrl = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users?documentId=${uid}`;
        
        const profile = {
          fields: {
            uid: { stringValue: uid },
            email: { stringValue: email },
            phone: { stringValue: faculty.phone },
            role: { stringValue: 'teacher' },
            displayName: { stringValue: faculty.name },
            schoolId: { stringValue: 'school_001' },
            primarySubject: { stringValue: faculty.subject },
            status: { stringValue: 'active' },
            createdAt: { timestampValue: new Date().toISOString() },
            updatedAt: { timestampValue: new Date().toISOString() },
            assignedClassIds: { arrayValue: { values: [] } },
            linkedStudentIds: { arrayValue: { values: [] } }
          }
        };

        try {
          await axios.post(firestoreUrl, profile, {
            headers: { Authorization: `Bearer ${idToken}` }
          });
          console.log('   Firestore profile created.');
        } catch (e) {
          if (e.response && e.response.status === 409) {
            console.log('   Profile already exists, updating subject...');
            const updateUrl = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}?updateMask.fieldPaths=primarySubject&updateMask.fieldPaths=updatedAt`;
            await axios.patch(updateUrl, profile, {
              headers: { Authorization: `Bearer ${idToken}` }
            });
            console.log('   Firestore profile updated.');
          } else {
            throw e;
          }
        }
      } catch (error) {
        console.error(`❌ FAILED for ${faculty.name} (${branch})`);
      }
    }
  }

  console.log('--- SEEDING COMPLETE ---');
}

seedFaculty();
