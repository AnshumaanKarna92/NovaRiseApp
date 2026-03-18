const admin = require('firebase-admin');

// Initialize the app if not already initialized
if (admin.apps.length === 0) {
  admin.initializeApp();
}

async function createTestUsers() {
  const users = [
    { email: 'admin@novarise.com', role: 'admin', name: 'Admin Master', password: 'admin123' },
    { email: 'teacher@novarise.com', role: 'teacher', name: 'Teacher 1', password: 'teacher123' },
    { email: 'parent@novarise.com', role: 'parent', name: 'Parent 1', password: 'parent123' },
    { email: 'test_admin@novarise.com', role: 'admin', name: 'Test Admin', password: 'password123' },
  ];

  for (const u of users) {
    try {
      console.log(`Processing ${u.email}...`);
      let userAuth;
      try {
        userAuth = await admin.auth().getUserByEmail(u.email);
        console.log(`User ${u.email} already exists.`);
      } catch (e) {
        userAuth = await admin.auth().createUser({
          email: u.email,
          password: u.password,
          displayName: u.name,
        });
        console.log(`Created Auth user: ${u.email}`);
      }

      const uid = userAuth.uid;
      
      // Set Firestore profile
      await admin.firestore().collection('users').doc(uid).set({
        uid,
        schoolId: 'school_001',
        role: u.role,
        displayName: u.name,
        phone: '1234567890',
        linkedStudentIds: u.role === 'parent' ? ['STU_1001'] : [],
        assignedClassIds: u.role === 'teacher' ? ['10A', '9B'] : [],
        status: 'active',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      console.log(`Updated Firestore for ${u.email}`);

      // Set Custom Claims
      await admin.auth().setCustomUserClaims(uid, { role: u.role });
      console.log(`Set Custom Claims (role: ${u.role}) for ${u.email}`);

    } catch (err) {
      console.error(`Error processing ${u.email}:`, err);
    }
  }

  // Create Student
  try {
    await admin.firestore().collection('students').doc('STU_1001').set({
      studentId: 'STU_1001',
      schoolId: 'school_001',
      name: 'Aryan Sharma',
      classId: '10A',
      parentName: 'Parent 1',
      parentPhone: '1234567890',
      status: 'active',
    });
    console.log('Created Student STU_1001');
  } catch (err) {
    console.error('Error creating student:', err);
  }

  console.log('--- SEEDING COMPLETE ---');
}

createTestUsers();
