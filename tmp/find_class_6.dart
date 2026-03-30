import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nova_rise_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final db = FirebaseFirestore.instance;
  
  print("STAGING INVESTIGATION: FINDING STUDENTS IN CLASS 6 BOYS...");
  
  final class6Boys = await db.collection('students')
      .where('classId', isEqualTo: '6')
      .where('branchId', isEqualTo: 'boys')
      .limit(5)
      .get();
  
  if (class6Boys.docs.isEmpty) {
     print("NO STUDENTS FOUND IN CLASS 6 BOYS. (Trying class ID 6B or similar)");
     final alt = await db.collection('students')
         .where('classId', isEqualTo: '6B')
         .limit(5)
         .get();
     for (var doc in alt.docs) {
        print("ID: ${doc['studentId']} | NAME: ${doc['name']} | CLASS: ${doc['classId']}");
     }
  } else {
     for (var doc in class6Boys.docs) {
        print("ID: ${doc['studentId']} | NAME: ${doc['name']} | ADMISSION ID: ${doc.id}");
     }
  }

  print("\nINVESTIGATING NRA-3-2026...");
  final nra3 = await db.collection('students')
      .where('studentId', isEqualTo: 'NRA-3-2026')
      .get();
  
  if (nra3.docs.isEmpty) {
     print("NOT FOUND BY studentId FIELD.");
     final nra3Doc = await db.collection('students').doc('NRA-3-2026').get();
     if (nra3Doc.exists) {
        print("FOUND BY DOC ID: ${nra3Doc.id}");
        print("DATA: ${nra3Doc.data()}");
     } else {
        print("TOTALLY NOT FOUND.");
     }
  } else {
     for (var doc in nra3.docs) {
        print("FOUND BY studentId FIELD: ${doc.id}");
        print("NAME: ${doc['name']}");
        print("DATA: ${doc.data()}");
     }
  }
}
