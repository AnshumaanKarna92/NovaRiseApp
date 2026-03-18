import "package:cloud_firestore/cloud_firestore.dart";
import "package:cloud_functions/cloud_functions.dart";

class MessageSubmissionService {
  MessageSubmissionService(this._functions, this._firestore);

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  Future<void> createMessage({
    required String schoolId,
    required String teacherId,
    required String classId,
    required String type,
    required String text,
    String? dueDate,
  }) async {
    try {
      await _functions.httpsCallable("createClassMessage").call({
        "classId": classId,
        "type": type,
        "text": text,
        "attachmentUrls": const <String>[],
        "dueDate": dueDate,
      });
    } catch (e) {
      // Direct Firestore Fallback
      final messageId = "msg_${DateTime.now().millisecondsSinceEpoch}";
      await _firestore.collection("messages").doc(messageId).set({
        "schoolId": schoolId,
        "teacherId": teacherId,
        "classId": classId,
        "type": type,
        "text": text,
        "attachmentUrls": const <String>[],
        "dueDate": dueDate,
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
  }
}
