import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nova_rise_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final regId = "NRA 27 2026";
  print("SEARCHING FOR: $regId");
  
  // Try exact match
  var query = await FirebaseFirestore.instance
      .collection('students')
      .where('studentId', isEqualTo: regId)
      .get();

  if (query.docs.isEmpty) {
    // Try spaces replaced by hyphens
    final hyphed = regId.replaceAll(" ", "-");
    print("TRYING HYPHENATED: $hyphed");
    query = await FirebaseFirestore.instance
        .collection('students')
        .where('studentId', isEqualTo: hyphed)
        .get();
  }

  if (query.docs.isEmpty) {
     print("NO STUDENT FOUND");
  } else {
     for (var doc in query.docs) {
       print("STUDENT ID: ${doc.id}");
       print("NAME: ${doc['name']}");
       print("CLASS ID: ${doc['classId']}");
       print("DATA: ${doc.data()}");
     }
  }
}
