const admin = require('firebase-admin');

// Initialize with project ID
admin.initializeApp({
  projectId: 'novariseapp'
});

const db = admin.firestore();

async function seed() {
  console.log('--- Starting Branch-Aware Seeding ---');

  const schoolId = 'school_001';

  // 1. Classes
  const classes = [
    { id: 'boys_lkg', branchId: 'boys', name: 'LKG-A', schoolId },
    { id: 'boys_2', branchId: 'boys', name: 'Grade 2', schoolId },
    { id: 'boys_6', branchId: 'boys', name: 'Grade 6', schoolId },
    { id: 'boys_10', branchId: 'boys', name: 'Grade 10', schoolId },
    { id: 'girls_ukg', branchId: 'girls', name: 'UKG-B', schoolId },
    { id: 'girls_3', branchId: 'girls', name: 'Grade 3', schoolId },
    { id: 'girls_7', branchId: 'girls', name: 'Grade 7', schoolId },
    { id: 'girls_9', branchId: 'girls', name: 'Grade 9', schoolId },
  ];

  for (const c of classes) {
    await db.collection('classes').doc(c.id).set(c);
    console.log(`Created class: ${c.id}`);
  }

  // 2. Students
  const students = [
    // Boys Junior
    { studentId: 'B_STU_1', name: 'Rahul Kumar', classId: 'boys_lkg', branchId: 'boys', schoolId, parentName: 'Sunil Kumar', parentPhone: '9000000001', status: 'active' },
    { studentId: 'B_STU_2', name: 'Amit Singh', classId: 'boys_2', branchId: 'boys', schoolId, parentName: 'Raj Singh', parentPhone: '9000000002', status: 'active' },
    // Boys Senior
    { studentId: 'B_STU_3', name: 'Vikram Seth', classId: 'boys_6', branchId: 'boys', schoolId, parentName: 'Karan Seth', parentPhone: '9000000003', status: 'active' },
    { studentId: 'B_STU_4', name: 'Arjun Das', classId: 'boys_10', branchId: 'boys', schoolId, parentName: 'Madan Das', parentPhone: '9000000004', status: 'active' },
    // Girls Junior
    { studentId: 'G_STU_1', name: 'Anjali Gupta', classId: 'girls_ukg', branchId: 'girls', schoolId, parentName: 'Pawan Gupta', parentPhone: '9000000005', status: 'active' },
    { studentId: 'G_STU_2', name: 'Sneha Rao', classId: 'girls_3', branchId: 'girls', schoolId, parentName: 'Srinivas Rao', parentPhone: '9000000006', status: 'active' },
    // Girls Senior
    { studentId: 'G_STU_3', name: 'Priya Verma', classId: 'girls_7', branchId: 'girls', schoolId, parentName: 'Alok Verma', parentPhone: '9000000007', status: 'active' },
    { studentId: 'G_STU_4', name: 'Riya Sen', classId: 'girls_9', branchId: 'girls', schoolId, parentName: 'Deb Sen', parentPhone: '9000000008', status: 'active' },
  ];

  for (const s of students) {
    await db.collection('students').doc(s.studentId).set(s);
    console.log(`Created student: ${s.studentId}`);
  }

  // 3. Notices
  const notices = [
    { noticeId: 'N_BOYS', title: 'Boys Football Match', body: 'Match on Saturday', branchId: 'boys', schoolId, targetType: 'all', startAt: '2026-03-20T08:00:00', expiresAt: '2026-03-30T18:00:00' },
    { noticeId: 'N_GIRLS', title: 'Girls Dance rehearsal', body: 'Rehearsal in auditorium', branchId: 'girls', schoolId, targetType: 'all', startAt: '2026-03-21T08:00:00', expiresAt: '2026-03-30T18:00:00' },
  ];

  for (const n of notices) {
    await db.collection('notices').doc(n.noticeId).set(n);
    console.log(`Created notice: ${n.noticeId}`);
  }

  console.log('--- Branch Seeding Completed Successfully ---');
  process.exit(0);
}

seed().catch(err => {
  console.error('Seeding failed:', err);
  process.exit(1);
});
