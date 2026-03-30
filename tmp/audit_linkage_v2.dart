import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:nova_rise_app/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final db = FirebaseFirestore.instance;
  
  print("STAGING DATABASE AUDIT: LINKING USERS TO STUDENTS...");
  
  // 1. Get all students and map their Registration IDs (studentId field)
  final studentSnap = await db.collection('students').get();
  Map<String, List<String>> regIdToDocIds = {};
  for (var doc in studentSnap.docs) {
    final regId = doc['studentId'].toString().toLowerCase().replaceAll(" ", "").replaceAll("-", "");
    regIdToDocIds.putIfAbsent(regId, () => []).add(doc.id);
    
    // Also map with dash if it exists
    final regIdDash = doc['studentId'].toString().toLowerCase().replaceAll(" ", "");
    if (regIdDash != regId) {
       regIdToDocIds.putIfAbsent(regIdDash, () => []).add(doc.id);
    }
  }
  
  print("INDEXED ${regIdToDocIds.length} REGISTRATION IDS.");
  
  // 2. Get all Parent Users and link them based on email
  final userSnap = await db.collection('users').where('role', isEqualTo: 'parent').get();
  int fixCount = 0;
  
  for (var userDoc in userSnap.docs) {
    final email = userDoc['email'].toString().toLowerCase();
    // Email is like nra-3-2026.boys@novarise.com
    final prefix = email.split('@').first; // nra-3-2026.boys
    final regPart = prefix.split('.').first; // nra-3-2026
    
    // Search for match in our map
    if (regIdToDocIds.containsKey(regPart)) {
       final studentDocIds = regIdToDocIds[regPart]!;
       
       // If there are multiple students with same ID (not expected but possible if seeder was messy), 
       // try to match branchId from email suffix
       String branch = "boys";
       if (prefix.contains(".girls")) branch = "girls";
       
       String? bestMatchId;
       if (studentDocIds.length == 1) {
          bestMatchId = studentDocIds.first;
       } else {
          // Find student in these doc IDs that matches the branch
          for (var sid in studentDocIds) {
             final sDoc = studentSnap.docs.firstWhere((d) => d.id == sid);
             if (sDoc['branchId'] == branch) {
                bestMatchId = sid;
                break;
             }
          }
       }

       if (bestMatchId != null) {
          List<String> currentLinks = List<String>.from(userDoc['linkedStudentIds'] ?? []);
          if (!currentLinks.contains(bestMatchId)) {
             print("FIXING USER: ${userDoc.id} ($email) -> STUDENT: $bestMatchId");
             currentLinks.add(bestMatchId);
             await db.collection('users').doc(userDoc.id).update({
                'linkedStudentIds': currentLinks,
             });
             fixCount++;
          }
       }
    }
  }
  
  print("AUDIT COMPLETE. FIXED $fixCount USERS.");
}
