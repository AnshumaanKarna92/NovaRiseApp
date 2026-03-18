const admin = require('firebase-admin');

// Initialize with project ID
admin.initializeApp({
  projectId: 'novariseapp'
});

const db = admin.firestore();
const auth = admin.auth();

async function createAuthUser(email, password, displayName) {
  try {
    const user = await auth.createUser({
      email,
      password,
      displayName,
    });
    console.log(`Created Auth user: ${email} (${user.uid})`);
    return user.uid;
  } catch (e) {
    if (e.code === 'auth/email-already-exists') {
      const user = await auth.getUserByEmail(email);
      console.log(`Auth user already exists: ${email} (${user.uid})`);
      return user.uid;
    }
    throw e;
  }
}

async function seed() {
  console.log('--- Starting Seeding ---');

  // 1. Admin
  const adminUid = await createAuthUser('admin@novarise.com', 'admin123', 'Administrator');
  await db.collection('users').doc(adminUid).set({
    uid: adminUid,
    schoolId: 'school_001',
    role: 'admin',
    displayName: 'Administrator',
    phone: '9999999999',
    linkedStudentIds: [],
    assignedClassIds: [],
    status: 'active',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // 2. Teacher
  const teacherUid = await createAuthUser('teacher@novarise.com', 'teacher123', 'Meera Nair');
  await db.collection('users').doc(teacherUid).set({
    uid: teacherUid,
    schoolId: 'school_001',
    role: 'teacher',
    displayName: 'Meera Nair',
    phone: '9876543210',
    linkedStudentIds: [],
    assignedClassIds: ['10A', '9B'],
    status: 'active',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // 3. Parent
  const parentUid = await createAuthUser('parent@novarise.com', 'parent123', 'Suresh Sharma');
  await db.collection('users').doc(parentUid).set({
    uid: parentUid,
    schoolId: 'school_001',
    role: 'parent',
    displayName: 'Suresh Sharma',
    phone: '9650991168',
    linkedStudentIds: ['STU_1001'],
    assignedClassIds: [],
    status: 'active',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // 4. Student
  await db.collection('students').doc('STU_1001').set({
    studentId: 'STU_1001',
    schoolId: 'school_001',
    name: 'Aryan Sharma',
    classId: '10A',
    parentName: 'Suresh Sharma',
    parentPhone: '9650991168',
    status: 'active',
  });

  // 5. Fee Invoice
  const invoiceId = 'INV_MAR24_STU1001';
  await db.collection('fee_invoices').doc(invoiceId).set({
    invoiceId: invoiceId,
    studentId: 'STU_1001',
    schoolId: 'school_001',
    title: 'March 2024 Tuition Fee',
    amount: 3500.0,
    dueDate: '2026-03-31',
    status: 'unpaid',
    paymentStatus: 'pending',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // 6. Notice
  await db.collection('notices').doc('notice_001').set({
    noticeId: 'notice_001',
    schoolId: 'school_001',
    title: 'Annual Sports Meet 2024',
    body: 'The annual sports meet will be held on March 25th at the main stadium.',
    targetType: 'all',
    targetClassIds: [],
    startAt: '2026-03-13T08:00:00',
    expiresAt: '2026-03-30T18:00:00',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  // 7. Transport
  await db.collection('transport_routes').doc('route_001').set({
    routeId: 'route_001',
    schoolId: 'school_001',
    routeName: 'Route A - Civil Lines',
    vehicleNumber: 'DL 1C AB 1234',
    driverName: 'Ramesh Kumar',
    driverPhone: '9812345678',
    status: 'morning_pickup',
    currentStop: 'Main Gate',
    lastUpdateAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  console.log('--- Seeding Completed Successfully ---');
  process.exit(0);
}

seed().catch(err => {
  console.error('Seeding failed:', err);
  process.exit(1);
});
