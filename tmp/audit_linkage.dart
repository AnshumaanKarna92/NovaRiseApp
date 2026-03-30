import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nova_rise_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final db = FirebaseFirestore.instance;
  
  print("STAGING DATABASE AUDIT: LINKING USERS TO STUDENTS...");
  
  // 1. Get all students
  final studentSnap = await db.collection('students').get();
  Map<String, String> regIdToDocId = {};
  for (var doc in studentSnap.docs) {
    final regId = doc['studentId'].toString().toLowerCase().replaceAll(" ", ".");
    regIdToDocId[regId] = doc.id;
  }
  
  print("FOUND ${studentSnap.docs.length} STUDENTS.");
  
  // 2. Get all Parent Users
  final userSnap = await db.collection('users').where('role', isEqualTo: 'parent').get();
  int fixCount = 0;
  
  for (var userDoc in userSnap.docs) {
    final email = userDoc['email'].toString().toLowerCase();
    final regIdFromEmail = email.split('@').first;
    
    if (regIdToDocId.containsKey(regIdFromEmail)) {
       final studentDocId = regIdToDocId[regIdFromEmail]!;
       List<String> currentLinks = List<String>.from(userDoc['linkedStudentIds'] ?? []);
       
       if (!currentLinks.contains(studentDocId)) {
          print("FIXING USER: ${userDoc.id} ($email) -> STUDENT: $studentDocId");
          currentLinks.add(studentDocId);
          await db.collection('users').doc(userDoc.id).update({
             'linkedStudentIds': currentLinks,
          });
          fixCount++;
       }
    }
  }
  
  print("AUDIT COMPLETE. FIXED $fixCount USERS.");
}
