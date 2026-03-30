class SchoolClass {
  const SchoolClass({
    required this.id,
    required this.schoolId,
    required this.name,
    this.classTeacherId,
    this.subjects = const {},
    this.branchIdFromData = "",
  });

  factory SchoolClass.fromMap(String id, Map<String, dynamic> data) {
    return SchoolClass(
      id: id,
      schoolId: data["schoolId"] as String? ?? "",
      name: data["name"] as String? ?? id,
      classTeacherId: data["classTeacherId"] as String? ?? "",
      subjects: Map<String, String>.from(data["subjects"] ?? {}),
      branchIdFromData: data["branchId"] as String? ?? "",
    );
  }

  final String id;
  final String schoolId;
  final String name;
  final String? classTeacherId;
  final Map<String, String> subjects; // Subject Name -> Teacher UID
  final String branchIdFromData;

  int get classWeight {
    final cleanId = id.toUpperCase();
    if (cleanId.contains("LKG")) return 1;
    if (cleanId.contains("UKG")) return 2;
    if (cleanId.contains("NURS")) return 0;
    
    // Explicit numerical mapping to avoid regex ambiguity
    final Map<String, int> explicitWeights = {
      "I": 4, "1": 4,
      "II": 5, "2": 5,
      "III": 6, "3": 6,
      "IV": 7, "4": 7,
      "V": 8, "5": 8,
      "VI": 9, "6": 9,
      "VII": 10, "7": 10,
      "VIII": 11, "8": 11,
      "IX": 12, "9": 12,
      "X": 13, "10": 13,
    };

    for (final entry in explicitWeights.entries) {
      if (cleanId.split(RegExp(r'[^A-Z0-9]')).contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Extract digit
    final match = RegExp(r'\d+').firstMatch(cleanId);
    if (match != null) {
      return int.parse(match.group(0)!) + 3; // Fallback
    }
    
    // Roman fallback 
    if (cleanId.startsWith("I")) {
       if (cleanId.startsWith("IX")) return 12;
       if (cleanId.startsWith("IV")) return 7;
       if (cleanId.startsWith("III")) return 6;
       if (cleanId.startsWith("II")) return 5;
       if (cleanId.startsWith("VIII")) return 11;
       if (cleanId.startsWith("VII")) return 10;
       if (cleanId.startsWith("VI")) return 9;
       if (cleanId.startsWith("V")) return 8;
       return 4; // I
    }
    if (cleanId.startsWith("X")) return 13;
    
    return 100;
  }

  bool get isJunior => classWeight <= 7; // Up to Class 4 (7) is Junior

  String get branchId {
    if (branchIdFromData.isNotEmpty) return branchIdFromData;
    // Heuristic: If name/id contains G for Girls or B for Boys
    final lower = name.toLowerCase();
    if (lower.contains("girl") || lower.contains("-g") || lower.endsWith(" g")) return "girls";
    return "boys";
  }

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
