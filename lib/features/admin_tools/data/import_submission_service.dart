import "dart:io";

import "package:cloud_functions/cloud_functions.dart";
import "package:file_picker/file_picker.dart";
import "package:firebase_storage/firebase_storage.dart";

class ImportSubmissionService {
  ImportSubmissionService({
    required FirebaseStorage storage,
    required FirebaseFunctions functions,
  }) : _storage = storage,
       _functions = functions;

  final FirebaseStorage _storage;
  final FirebaseFunctions _functions;

  Future<String> uploadCsv({
    required String schoolId,
    required PlatformFile file,
  }) async {
    final ext = file.extension?.toLowerCase();
    if (ext != "csv") {
      throw Exception("Only .csv files are allowed.");
    }

    final objectPath =
        "schoolapp/$schoolId/imports/students_${DateTime.now().millisecondsSinceEpoch}.csv";
    final ref = _storage.ref(objectPath);
    if (file.bytes != null) {
      await ref.putData(file.bytes!);
    } else if (file.path != null) {
      await ref.putFile(File(file.path!));
    } else {
      throw Exception("Unable to read the selected CSV file.");
    }

    return ref.getDownloadURL();
  }

  Future<void> enqueueImport({required String fileUrl}) async {
    await _functions.httpsCallable("enqueueStudentsCsvImport").call({
      "fileUrl": fileUrl,
    });
  }
}
