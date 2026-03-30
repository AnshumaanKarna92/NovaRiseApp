const axios = require('axios');
const fs = require('fs');
const path = require('path');

const PROJECT_ID = 'novariseapp';
const API_KEY = 'AIzaSyCfgJ6lMceYwWlZsKEWfGakslqXOMrcqiM';
const SCHOOL_ID = 'school_001';

async function getAuthToken() {
    const loginUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${API_KEY}`;
    const res = await axios.post(loginUrl, { email: 'master@novarise.com', password: 'password123', returnSecureToken: true });
    return res.data.idToken;
}

async function wipeCollection(collection, token) {
    console.log(`Wiping collection: ${collection}...`);
    const listUrl = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/${collection}`;
    try {
        const res = await axios.get(listUrl, { headers: { Authorization: `Bearer ${token}` } });
        if (!res.data.documents) return;
        
        for (const doc of res.data.documents) {
            const docPath = doc.name;
            await axios.delete(`https://firestore.googleapis.com/v1/${docPath}`, { headers: { Authorization: `Bearer ${token}` } });
        }
    } catch (e) {
        console.log(`Error wiping ${collection}: ${e.message}`);
    }
}

function toFirestoreValue(val) {
    if (typeof val === 'number') return { doubleValue: val };
    return { stringValue: String(val) };
}

async function importData() {
    try {
        const token = await getAuthToken();
        const students = JSON.parse(fs.readFileSync('students_ready.json', 'utf8'));
        
        console.log(`Starting Import of ${students.length} students...`);
        
        // 1. Wipe old data (optional, but requested)
        await wipeCollection('students', token);
        await wipeCollection('classes', token);
        
        const classesToCreate = new Set();
        
        for (const s of students) {
            const classId = `${s.branchId}_${s.classId.toLowerCase().replace(/ /g, '_')}`;
            classesToCreate.add(JSON.stringify({
                id: classId,
                name: s.classId,
                branchId: s.branchId,
                isJunior: ['LKG', 'UKG', 'I', 'II', 'III', 'IV'].includes(s.classId)
            }));
            
            const docId = s.studentId;
            const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/students/${docId}`;
            
            const fields = {
                studentId: { stringValue: s.studentId },
                name: { stringValue: s.name },
                branchId: { stringValue: s.branchId },
                classId: { stringValue: classId },
                rollNo: { stringValue: String(s.rollNo) },
                session: { stringValue: String(s.session || '2026') },
                monthlyFees: { doubleValue: parseFloat(s.monthlyFees) },
                admissionDate: { stringValue: s.admissionDate || '' },
                studentType: { stringValue: s.studentType || 'non_resident' },
                schoolId: { stringValue: SCHOOL_ID },
                parentName: { stringValue: `Parent of ${s.name}` },
                parentPhone: { stringValue: '9876543210' },
                status: { stringValue: 'active' }
            };
            
            await axios.patch(url, { fields }, { headers: { Authorization: `Bearer ${token}` } });
            process.stdout.write('.');
        }
        
        console.log('\nImporting Classes...');
        for (const cJson of classesToCreate) {
            const c = JSON.parse(cJson);
            const url = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents/classes/${c.id}`;
            const fields = {
                id: { stringValue: c.id },
                name: { stringValue: c.name },
                branchId: { stringValue: c.branchId },
                schoolId: { stringValue: SCHOOL_ID },
                isJunior: { booleanValue: c.isJunior },
                isSenior: { booleanValue: !c.isJunior }
            };
            await axios.patch(url, { fields }, { headers: { Authorization: `Bearer ${token}` } });
        }
        
        console.log('\n--- DATA IMPORT SUCCESSFUL ---');
    } catch (e) {
        console.error('Import Failed:', e.response ? e.response.data : e.message);
    }
}

importData();
