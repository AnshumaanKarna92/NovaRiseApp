const https = require('https');

const API_KEY = 'AIzaSyAQXB2fBv7pVv0pepoC0AyA17xcTSztWh0';
const PROJECT_ID = 'novariseapp';

function request(url, method, data, headers = {}) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const options = {
      hostname: urlObj.hostname,
      path: urlObj.pathname + urlObj.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
        ...headers
      }
    };

    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(body);
          if (res.statusCode >= 400) reject(json);
          else resolve(json);
        } catch (e) {
          reject(body);
        }
      });
    });

    req.on('error', reject);
    if (data) req.write(JSON.stringify(data));
    req.end();
  });
}

async function signUp(email, password) {
  console.log(`Signing up ${email}...`);
  return request(
    `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${API_KEY}`,
    'POST',
    { email, password, returnSecureToken: true }
  ).catch(err => {
    if (err.error && err.error.message === 'EMAIL_EXISTS') {
      console.log(`${email} already exists, signing in...`);
      return request(
        `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`,
        'POST',
        { email, password, returnSecureToken: true }
      );
    }
    throw err;
  });
}

async function setFirestoreDoc(collection, docId, fields, token) {
  console.log(`Setting document ${collection}/${docId}...`);
  // Transform simplified fields to Firestore REST fields mapping
  const firestoreFields = {};
  for (const [key, value] of Object.entries(fields)) {
    if (typeof value === 'string') firestoreFields[key] = { stringValue: value };
    else if (typeof value === 'number') firestoreFields[key] = { doubleValue: value };
    else if (typeof value === 'boolean') firestoreFields[key] = { booleanValue: value };
    else if (Array.isArray(value)) firestoreFields[key] = { arrayValue: { values: value.map(v => ({ stringValue: v })) } };
  }

  return request(
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collection}/${docId}?updateMask.fieldPaths=${Object.keys(fields).join('&updateMask.fieldPaths=')}`,
    'PATCH',
    { fields: firestoreFields },
    { 'Authorization': `Bearer ${token}` }
  );
}

async function seed() {
  try {
    // 1. Admin
    const admin = await signUp('test_admin@novarise.com', 'password123');
    await setFirestoreDoc('users', admin.localId, {
      uid: admin.localId,
      role: 'admin',
      displayName: 'Test Admin',
      schoolId: 'school_001',
      status: 'active'
    }, admin.idToken);

    // 2. Teacher
    const teacher = await signUp('test_teacher@novarise.com', 'password123');
    await setFirestoreDoc('users', teacher.localId, {
      uid: teacher.localId,
      role: 'teacher',
      displayName: 'Test Teacher',
      schoolId: 'school_001',
      assignedClassIds: ['10A', '9B'],
      status: 'active'
    }, teacher.idToken);

    // 3. Parent
    const parent = await signUp('test_parent@novarise.com', 'password123');
    await setFirestoreDoc('users', parent.localId, {
      uid: parent.localId,
      role: 'parent',
      displayName: 'Test Parent',
      schoolId: 'school_001',
      linkedStudentIds: ['STU_1001'],
      status: 'active'
    }, parent.idToken);

    // 4. Student (STU_1001) - Needs auth to write to students collection too
    // We'll use the admin token for other writes if rules allow, or just the parent token.
    await setFirestoreDoc('students', 'STU_1001', {
      studentId: 'STU_1001',
      name: 'Aryan Sharma',
      classId: '10A',
      schoolId: 'school_001'
    }, admin.idToken);

    console.log('--- ALL IDS CREATED SUCCESSFULLY ---');
    console.log('Admin: admin@novarise.com / admin123');
    console.log('Teacher: teacher@novarise.com / teacher123');
    console.log('Parent: parent@novarise.com / parent123');
  } catch (e) {
    console.error('Seeding failed:', e);
  }
}

seed();
