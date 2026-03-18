import "package:cloud_firestore/cloud_firestore.dart";
import "package:cloud_functions/cloud_functions.dart";

class NoticeSubmissionService {
  NoticeSubmissionService(this._functions, this._firestore);

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  Future<void> publishNotice({
    required String schoolId,
    required String title,
    required String body,
    required String targetType,
    required List<String> targetClassIds,
    required String startAt,
    required String expiresAt,
  }) async {
    try {
      await _functions.httpsCallable("publishNotice").call({
        "title": title,
        "body": body,
        "attachmentUrls": const <String>[],
        "targetType": targetType,
        "targetClassIds": targetClassIds,
        "startAt": startAt,
        "expiresAt": expiresAt,
      });
    } catch (e) {
      // Direct Firestore Fallback
      final noticeId = "notice_${DateTime.now().millisecondsSinceEpoch}";
      await _firestore.collection("notices").doc(noticeId).set({
        "schoolId": schoolId,
        "title": title,
        "body": body,
        "attachmentUrls": const <String>[],
        "target": targetType,
        "targetClassIds": targetClassIds,
        "startAt": startAt,
        "expiresAt": expiresAt,
        "postedAt": FieldValue.serverTimestamp(),
      });
    }
  }
}
