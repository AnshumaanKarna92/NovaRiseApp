const fs = require('fs');
const data = JSON.parse(fs.readFileSync('users_final_list.json', 'utf8'));

const targets = [
  'master@novarise.com',
  'teacher@novarise.com',
  'parent@novarise.com'
];

targets.forEach(email => {
  const user = data.users.find(u => u.email === email);
  if (user) {
    console.log(`${email}: ${user.localId}`);
  } else {
    console.log(`${email}: NOT FOUND`);
  }
});
