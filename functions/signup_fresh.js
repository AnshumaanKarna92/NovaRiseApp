const axios = require('axios');

async function signup(email, password) {
  const apiKey = 'AIzaSyCfgJ6lMceYwWlZsKEWfGakslqXOMrcqiM';
  const url = `https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=${apiKey}`;
  
  const payload = {
    email,
    password,
    returnSecureToken: true
  };

  try {
    const response = await axios.post(url, payload);
    console.log(`✅ SUCCESS: Created ${email}`);
    return response.data.localId;
  } catch (error) {
    if (error.response && error.response.data.error.message === 'EMAIL_EXISTS') {
      console.log(`ℹ️ EXISTS: ${email}`);
      // If it exists, we can't get the UID easily here without Admin SDK, 
      // but we know it's there. We'll hope the password is what we want 
      // or use a unique email.
      return null;
    }
    console.log(`❌ FAILED: ${email}`, error.response ? error.response.data.error.message : error.message);
    return null;
  }
}

async function run() {
  // Using unique emails to ensure we set the password
  console.log('--- CREATING FRESH ACCOUNTS ---');
  await signup('admin_final@novarise.com', 'password123');
  await signup('teacher_final@novarise.com', 'password123');
  await signup('parent_final@novarise.com', 'password123');
  console.log('--- DONE ---');
}

run();
