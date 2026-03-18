const admin = require('firebase-admin');
const fs = require('fs');
if (admin.apps.length === 0) admin.initializeApp();

async function check() {
  const uid = 'C3oG89LOKLSvlvb6wLzLQteAwwk2';
  try {
    const doc = await admin.firestore().collection('users').doc(uid).get();
    const data = doc.exists ? doc.data() : 'MISSING';
    fs.writeFileSync('C:/Users/Anshumaan Karna/nova_rise_app/functions/profile_check.json', JSON.stringify(data, null, 2));
  } catch (e) {
    fs.writeFileSync('C:/Users/Anshumaan Karna/nova_rise_app/functions/profile_check_error.txt', e.message);
  }
}
check();
