const admin = require('firebase-admin');
const fs = require('fs');
if (admin.apps.length === 0) admin.initializeApp();

async function check() {
  const email = 'admin@novarise.com';
  let out = '';
  try {
    const user = await admin.auth().getUserByEmail(email);
    out += `User: ${email}\n`;
    out += `UID: ${user.uid}\n`;
    out += `Claims: ${JSON.stringify(user.customClaims)}\n`;
    
    const profile = await admin.firestore().collection('users').doc(user.uid).get();
    if (profile.exists) {
      out += `Firestore Profile: ${JSON.stringify(profile.data())}\n`;
    } else {
      out += `Firestore Profile MISSING\n`;
    }
  } catch (e) {
    out += `Error: ${e.message}\n`;
  }
  fs.writeFileSync('check_output.txt', out);
  console.log('Output written to check_output.txt');
}
check();
