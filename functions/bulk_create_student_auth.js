const axios = require('axios');
const fs = require('fs');

const PROJECT_ID = 'novariseapp';
const API_KEY = 'AIzaSyCfgJ6lMceYwWlZsKEWfGakslqXOMrcqiM';
const SCHOOL_ID = 'school_001';
const DEFAULT_PASS = 'password123';

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

async function bulkCreate() {
  try {
    const students = JSON.parse(fs.readFileSync('students_ready.json', 'utf8'));
    console.log(`Starting Auth creation for ${students.length} students...`);
    
    // We'll wait 2000ms between each student to avoid rate limits
    // We need an admin token to write to 'users' collection
    // We'll use the master@novarise.com account to get a token
    const loginUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`;
    const loginRes = await axios.post(loginUrl, { 
      email: 'master@novarise.com', 
      password: 'password123', 
      returnSecureToken: true 
    });
    const idToken = loginRes.data.idToken;

    for (let i = 0; i < students.length; i++) {
      const s = students[i];
      const email = `${s.studentId}.${s.branchId}@novarise.com`.toLowerCase();
      
      try {
        // 1. Create Auth User
        const signupUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`;
        const signupRes = await axios.post(signupUrl, { 
          email, 
          password: DEFAULT_PASS, 
          returnSecureToken: true 
        });
        const uid = signupRes.data.localId;
        
        // 2. Create User Profile
        const firestoreUrl = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/users/${uid}`;
        const profile = {
          fields: {
            uid: { stringValue: uid },
            email: { stringValue: email },
            role: { stringValue: 'parent' },
            displayName: { stringValue: s.name },
            schoolId: { stringValue: SCHOOL_ID },
            linkedStudentIds: { arrayValue: { values: [{ stringValue: s.studentId }] } },
            status: { stringValue: 'active' },
            createdAt: { timestampValue: new Date().toISOString() }
          }
        };
        
        await axios.patch(firestoreUrl, profile, {
          headers: { Authorization: `Bearer ${idToken}` }
        });
        
        if (i % 10 === 0) process.stdout.write('.');
        await sleep(2000); // Wait 2000ms after each creation
      } catch (e) {
        if (e.response && e.response.data && e.response.data.error && e.response.data.error.message === 'EMAIL_EXISTS') {
          // Skip if already exists
          continue;
        }
        console.log(`\nError creating ${email}: ${e.message}`);
        if (e.response && e.response.data) {
          console.log('Error Data:', JSON.stringify(e.response.data, null, 2));
        }
        await sleep(1000); // Longer wait after error
      }
    }
    
    console.log('\n--- BULK AUTH CREATION COMPLETED ---');
    console.log(`All students can now log in with Password: ${DEFAULT_PASS}`);
  } catch (error) {
    console.error('Bulk creation failed:', error.message);
  }
}

bulkCreate();
