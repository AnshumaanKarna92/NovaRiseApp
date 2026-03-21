class SchoolClass {
  const SchoolClass({
    required this.id,
    required this.schoolId,
    required this.name,
    this.classTeacherId,
    this.subjects = const {},
  });

  factory SchoolClass.fromMap(String id, Map<String, dynamic> data) {
    return SchoolClass(
      id: id,
      schoolId: data["schoolId"] as String? ?? "",
      name: data["name"] as String? ?? id,
      classTeacherId: data["classTeacherId"] as String? ?? "",
      subjects: Map<String, String>.from(data["subjects"] ?? {}),
    );
  }

  final String id;
  final String schoolId;
  final String name;
  final String? classTeacherId;
  final Map<String, String> subjects; // Subject Name -> Teacher UID

  String get displayName {
    // Need to handle things like "Grade Grade 8- Section C"
    // Remove variations of "Grade", "Section", and dashes, then trim extra spaces
    String clean = name
        .replaceAll(RegExp(r'Grade|Section|-', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final parts = clean.split(' ');
    if (parts.length >= 2) {
      // Reformat "8 C" to "8-C"
      return "Grade ${parts.join('-')}";
    }
    
    // In case it's just "8" or empty
    if (clean.isEmpty) return "Grade Unknown";
    return "Grade $clean";
  }

  Map<String, dynamic> toMap() {
    return {
      "schoolId": schoolId,
      "name": name,
      "classTeacherId": classTeacherId,
      "subjects": subjects,
    };
  }
}
