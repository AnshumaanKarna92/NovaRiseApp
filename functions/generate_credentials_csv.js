const fs = require('fs');

async function generateCsv() {
    try {
        const students = JSON.parse(fs.readFileSync('students_ready.json', 'utf8'));
        console.log(`Processing ${students.length} students...`);

        let csv = 'Name,Student ID (Reg ID),Branch,Login Identifier,Password\n';
        
        for (const s of students) {
            if (!s.studentId || /reg\.id|studentId|StudentName/i.test(s.studentId)) continue;
            const loginId = s.studentId;
            const password = 'password123';
            csv += `"${s.name}","${s.studentId}","${s.branchId}","${loginId}","${password}"\n`;
        }

        fs.writeFileSync('student_credentials.csv', csv);
        console.log('✅ Generated student_credentials.csv');
    } catch (e) {
        console.error('Failed:', e.message);
    }
}

generateCsv();
