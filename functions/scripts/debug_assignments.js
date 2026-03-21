const admin = require('firebase-admin');

if (admin.apps.length === 0) {
  admin.initializeApp({
    projectId: 'novariseapp'
  });
}

const db = admin.firestore();

async function debugAssignments() {
  const email = 'teacher@novarise.com';
  console.log(`--- Debugging Assignments for ${email} ---`);
  
  const userSnapshot = await db.collection('users').where('email', '==', email).get();
  if (userSnapshot.empty) {
    console.log('User not found.');
    return;
  }
  
  const userDoc = userSnapshot.docs[0];
  const userData = userDoc.data();
  const uid = userDoc.id;
  console.log(`UID: ${uid}`);
  console.log(`SchoolId: ${userData.schoolId}`);
  console.log(`Role: ${userData.role}`);
  console.log(`Primary Subject: ${userData.primarySubject}`);
  console.log(`Assigned Class IDs: ${userData.assignedClassIds}`);

  console.log('--- Checking Classes ---');
  const classSnapshot = await db.collection('classes').where('schoolId', '==', userData.schoolId).get();
  classSnapshot.forEach(doc => {
    const data = doc.data();
    console.log(`Class: ${doc.id} (${data.name})`);
    console.log(`  Class Teacher: ${data.classTeacherId}`);
    console.log(`  Subjects: ${JSON.stringify(data.subjects)}`);
    if (data.classTeacherId === uid) console.log('  -> MATCH: Is Class Teacher');
    if (Object.values(data.subjects || {}).includes(uid)) console.log('  -> MATCH: Is Subject Teacher');
  });
}

debugAssignments().catch(console.error);
