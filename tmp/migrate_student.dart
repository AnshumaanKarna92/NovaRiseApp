import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nova_rise_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final regId = "NRA 27 2026";
  final targetClass = "6"; // Move to Class 6
  
  print("MIGRATING STUDENT: $regId to CLASS: $targetClass");
  
  final db = FirebaseFirestore.instance;
  
  // 1. Search for student by ID (exact or hyphenated)
  var students = await db.collection('students').where('studentId', isEqualTo: regId).get();
  if (students.docs.isEmpty) {
     students = await db.collection('students').where('studentId', isEqualTo: regId.replaceAll(" ", "-")).get();
  }
  
  if (students.docs.isEmpty) {
    print("FATAL ERROR: Student not found in database.");
    return;
  }
  
  final studentDoc = students.docs.first;
  final oldClass = studentDoc['classId'];
  
  print("STAGING UPDATE: Student ${studentDoc.id} (${studentDoc['name']})");
  print("CURRENT CLASS: $oldClass -> NEW CLASS: $targetClass");
  
  await db.collection('students').doc(studentDoc.id).update({
    'classId': targetClass,
  });
  
  print("SUCCESS: Student record updated.");
  
  // 2. Check the AppUser linkage
  final email = "${regId.toLowerCase().replaceAll(" ", ".")}@novarise.com";
  print("CHECKING LINKED USER: $email");
  
  var users = await db.collection('users').where('email', isEqualTo: email).get();
  if (users.docs.isNotEmpty) {
     final userDoc = users.docs.first;
     print("FOUND USER: ${userDoc.id} (${userDoc['displayName']})");
     List<String> linkedIds = List<String>.from(userDoc['linkedStudentIds'] ?? []);
     if (!linkedIds.contains(studentDoc.id)) {
        print("FIXING LINKAGE: Adding student ID to linkedStudentIds...");
        linkedIds.add(studentDoc.id);
        await db.collection('users').doc(userDoc.id).update({
           'linkedStudentIds': linkedIds,
        });
        print("LINKAGE FIXED.");
     } else {
        print("LINKAGE VERIFIED.");
     }
  } else {
     print("WARNING: No AppUser record found for this student login. User might be using a different email format.");
  }
  
  print("MIGRATION COMPLETE.");
}
