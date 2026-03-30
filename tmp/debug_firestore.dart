import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// This is a scratch script to verify teacher assignments in Firestore
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  final firestore = FirebaseFirestore.instance;
  
  // Search for teachers
  final users = await firestore.collection('users')
    .where('role', isEqualTo: 'teacher')
    .limit(5)
    .get();
    
  print('--- TEACHERS ---');
  for (var doc in users.docs) {
    print('UID: ${doc.id}');
    print('Name: ${doc.data()['displayName']}');
    print('SchoolId: ${doc.data()['schoolId']}');
    print('AssignedClasses: ${doc.data()['assignedClassIds']}');
    print('----------------');
  }
  
  // Check classes
  final classes = await firestore.collection('classes').limit(5).get();
  print('--- CLASSES ---');
  for (var doc in classes.docs) {
    print('ClassID: ${doc.id}');
    print('Name: ${doc.data()['name']}');
    print('SchoolId: ${doc.data()['schoolId']}');
    print('Subjects: ${doc.data()['subjects']}');
    print('ClassTeacher: ${doc.data()['classTeacherId']}');
    print('----------------');
  }
}
