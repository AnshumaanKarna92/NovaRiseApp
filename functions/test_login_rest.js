const axios = require('axios');

async function testLogin() {
  const apiKey = 'AIzaSyCfgJ6lMceYwWlZsKEWfGakslqXOMrcqiM';
  const url = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${apiKey}`;
  
  const payload = {
    email: 'admin@novarise.com',
    password: 'password123',
    returnSecureToken: true
  };

  console.log('Testing login for admin@novarise.com...');
  try {
    const response = await axios.post(url, payload);
    console.log('✅ LOGIN SUCCESS!');
    console.log('Local ID:', response.data.localId);
  } catch (error) {
    console.log('❌ LOGIN FAILED!');
    if (error.response) {
      console.log('Status:', error.response.status);
      console.log('Error Message:', JSON.stringify(error.response.data.error, null, 2));
    } else {
      console.log('Error:', error.message);
    }
  }
}

testLogin();
