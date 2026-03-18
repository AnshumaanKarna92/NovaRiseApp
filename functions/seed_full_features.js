const axios = require('axios');

const PROJECT_ID = 'novariseapp';
const API_KEY = 'AIzaSyCfgJ6lMceYwWlZsKEWfGakslqXOMrcqiM';

// UIDs found from auth export
const ADMIN_UID = 'BG6kzeexEbQuuyw0kxZcofI5fqo1';
const TEACHER_UID = '3m1mY3cdUsfwps0Ncs55KwosvwX2';
const PARENT_UID = '7OBVgsLWzycONZEgszeNNNz2zPW2';

async function postToFirestore(collection, docId, data, idToken) {
  const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collection}/${docId}`;
  try {
    await axios.patch(url, { fields: data }, {
      headers: { Authorization: `Bearer ${idToken}` }
    });
    console.log(`✅ Seeded ${collection}/${docId}`);
  } catch (e) {
    console.error(`❌ Failed ${collection}/${docId}:`, e.response ? e.response.data : e.message);
  }
}

async function run() {
  console.log('--- STARTING CLEAN ISOLATED SEED (v4.0) ---');

  const loginUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`;
  const loginRes = await axios.post(loginUrl, { email: 'master@novarise.com', password: 'password123', returnSecureToken: true });
  const idToken = loginRes.data.idToken;

  // 1. Classes
  await postToFirestore('classes', '10A', {
    classId: { stringValue: '10A' },
    schoolId: { stringValue: 'school_001' },
    name: { stringValue: 'Grade 10-A' }
  }, idToken);

  // 2. Student (Strict 1:1)
  await postToFirestore('students', 'STU_1001', {
    studentId: { stringValue: 'STU_1001' },
    schoolId: { stringValue: 'school_001' },
    name: { stringValue: 'Aryan Sharma' },
    classId: { stringValue: '10A' },
    parentUserIds: { arrayValue: { values: [{ stringValue: PARENT_UID }] } },
    status: { stringValue: 'active' }
  }, idToken);

  // 3. User Profiles (Strict 1:1)
  await postToFirestore('users', TEACHER_UID, {
    uid: { stringValue: TEACHER_UID },
    email: { stringValue: 'teacher@novarise.com' },
    role: { stringValue: 'teacher' },
    displayName: { stringValue: 'Deepak Verma' },
    schoolId: { stringValue: 'school_001' },
    assignedClassIds: { arrayValue: { values: [{ stringValue: '10A' }] } },
    status: { stringValue: 'active' }
  }, idToken);

  await postToFirestore('users', PARENT_UID, {
    uid: { stringValue: PARENT_UID },
    email: { stringValue: 'parent@novarise.com' },
    role: { stringValue: 'parent' },
    displayName: { stringValue: 'Suresh Sharma' },
    schoolId: { stringValue: 'school_001' },
    linkedStudentIds: { arrayValue: { values: [{ stringValue: 'STU_1001' }] } },
    status: { stringValue: 'active' }
  }, idToken);

  // 4. Attendance History (Last 5 days)
  for (let i = 0; i < 5; i++) {
    const date = new Date(Date.now() - i * 86400000).toISOString().split('T')[0];
    const aid = `ATT_10A_${date.replaceAll('-', '')}`;
    await postToFirestore('attendance', aid, {
      attendanceId: { stringValue: aid },
      schoolId: { stringValue: 'school_001' },
      classId: { stringValue: '10A' },
      date: { stringValue: date },
      records: { arrayValue: { values: [
        { mapValue: { fields: { studentId: { stringValue: 'STU_1001' }, status: { stringValue: 'present' }, remarks: { stringValue: '' } } } }
      ] } },
      isEdited: { booleanValue: true }
    }, idToken);
  }

  // 5. Finance
  await postToFirestore('fee_invoices', 'INV_MAR_1001', {
    invoiceId: { stringValue: 'INV_MAR_1001' },
    studentId: { stringValue: 'STU_1001' },
    schoolId: { stringValue: 'school_001' },
    title: { stringValue: 'March Tuition Fee' },
    amount: { doubleValue: 4500.0 },
    dueDate: { stringValue: '2026-03-31' },
    paymentStatus: { stringValue: 'unpaid' },
    status: { stringValue: 'active' },
    createdAt: { timestampValue: new Date().toISOString() }
  }, idToken);

  // 6. Transport
  await postToFirestore('transport_routes', 'R_10A', {
    routeId: { stringValue: 'R_10A' },
    schoolId: { stringValue: 'school_001' },
    routeName: { stringValue: 'Route 10A - Aryan' },
    vehicleNumber: { stringValue: 'DL 1P A 0001' },
    driverName: { stringValue: 'Madan Lal' },
    driverPhone: { stringValue: '9988776655' },
    status: { stringValue: 'morning_pickup' },
    currentStop: { stringValue: 'Society Main Gate' },
    lastUpdateAt: { timestampValue: new Date().toISOString() }
  }, idToken);

  console.log('--- CLEAN ISOLATED SEEDING COMPLETED ---');
}

run().catch(console.error);
