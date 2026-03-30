const axios = require('axios');
const fs = require('fs');

const PROJECT_ID = 'novariseapp';
const API_KEY = 'AIzaSyCfgJ6lMceYwWlZsKEWfGakslqXOMrcqiM';
const SCHOOL_ID = 'school_001';
const DEFAULT_PASS = 'password123';

async function robustSeed() {
  try {
    const students = JSON.parse(fs.readFileSync('students_ready.json', 'utf8'));
    console.log(`Phase: Ensuring Auth/Profile for ${students.length} students...`);
    
    // Admin login for Firestore writes
    const loginUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`;
    const loginRes = await axios.post(loginUrl, { 
      email: 'master@novarise.com', 
      password: 'password123', 
      returnSecureToken: true 
    });
    const idToken = loginRes.data.idToken;

    for (let i = 0; i < students.length; i++) {
        const s = students[i];
        if (!s.studentId || /reg\.id|studentId|StudentName/i.test(s.studentId)) continue; 
        const loginId = s.studentId;

        const email = `${s.studentId}.${s.branchId}@novarise.com`.toLowerCase();
        
        try {
            // 1. SignUp (Silent if exists)
            let uid;
            try {
                const signupUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`;
                const signupRes = await axios.post(signupUrl, { email, password: DEFAULT_PASS, returnSecureToken: true });
                uid = signupRes.data.localId;
            } catch (e) {
                if (e.response && e.response.data.error.message === 'EMAIL_EXISTS') {
                    // Sign in to get UID
                    const loginRes = await axios.post(loginUrl, { email, password: DEFAULT_PASS, returnSecureToken: true });
                    uid = loginRes.data.localId;
                } else { throw e; }
            }

            // 2. Ensure Firestore Profile
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
                    updatedAt: { timestampValue: new Date().toISOString() }
                }
            };
            await axios.patch(firestoreUrl, profile, { headers: { Authorization: `Bearer ${idToken}` } });
            
            if (i % 20 === 0) process.stdout.write('.');
        } catch (e) {
            console.log(`\n❌ Error for ${email}: ${e.response ? JSON.stringify(e.response.data.error) : e.message}`);
        }
    }
    console.log('\n✅ ROBUST SEEDING COMPLETED');
  } catch (error) {
    console.error('Failed:', error.message);
  }
}

robustSeed();
