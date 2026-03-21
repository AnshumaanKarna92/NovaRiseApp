const admin = require('firebase-admin');
const fs = require('fs');

if (admin.apps.length === 0) {
  admin.initializeApp({
    projectId: 'novarise-f91cb' // I should confirm project ID from environment if possible, but this is usually safe if it was initialized before.
  });
}

const db = admin.firestore();

async function updateTeachers() {
  console.log('Fetching all teachers...');
  const snapshot = await db.collection('users').where('role', '==', 'teacher').get();
  
  if (snapshot.empty) {
    console.log('No teachers found.');
    return;
  }

  console.log(`Found ${snapshot.size} teachers.`);
  const batch = db.batch();
  let updatedCount = 0;

  snapshot.forEach(doc => {
    const data = doc.data();
    if (!data.primarySubject) {
      console.log(`Teacher ${data.displayName} (${doc.id}) has no primary subject. Assigning 'General Education'...`);
      batch.update(doc.ref, { primarySubject: 'General Education' });
      updatedCount++;
    }
  });

  if (updatedCount > 0) {
    await batch.commit();
    console.log(`Successfully updated ${updatedCount} teachers.`);
  } else {
    console.log('All teachers already have a primary subject.');
  }
}

updateTeachers().catch(console.error);
