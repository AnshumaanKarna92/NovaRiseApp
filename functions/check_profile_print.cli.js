const admin = require('firebase-admin');
if (admin.apps.length === 0) admin.initializeApp();

async function check() {
  const uid = 'C3oG89LOKLSvlvb6wLzLQteAwwk2';
  try {
    const doc = await admin.firestore().collection('users').doc(uid).get();
    console.log('---START_PROFILE---');
    console.log(JSON.stringify(doc.data(), null, 2));
    console.log('---END_PROFILE---');
  } catch (e) {
    console.log('ERR: ' + e.message);
  }
}
check();
