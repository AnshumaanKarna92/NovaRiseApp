class Student {
  const Student({
    required this.studentId,
    required this.schoolId,
    required this.name,
    required this.classId,
    required this.parentName,
    required this.parentPhone,
    required this.status,
    required this.branchId,
    this.rollNo = "",
    this.monthlyFees = 0,
    this.admissionDate = "",
    this.studentType = "non_resident",
    this.bloodGroup,
    this.marksData,
    this.profileImageUrl = "",
  });

  factory Student.fromMap(String id, Map<String, dynamic> data) {
    return Student(
      studentId: id,
      schoolId: data["schoolId"] as String? ?? "",
      name: data["name"] as String? ?? "Student",
      classId: data["classId"] as String? ?? "",
      parentName: data["parentName"] as String? ?? "",
      parentPhone: data["parentPhone"] as String? ?? "",
      status: data["status"] as String? ?? "active",
      branchId: data["branchId"] as String? ?? "boys",
      rollNo: data["rollNo"]?.toString() ?? "",
      monthlyFees: (data["monthlyFees"] as num?)?.toInt() ?? 0,
      admissionDate: data["admissionDate"] as String? ?? "",
      studentType: data["studentType"] as String? ?? "non_resident",
      bloodGroup: data["bloodGroup"] as String?,
      marksData: data["marksData"] as String?,
      profileImageUrl: data["profileImageUrl"] as String? ?? "",
    );
  }

  int get classWeight {
    final cleanId = classId.toUpperCase();
    if (cleanId.contains("LKG")) return 1;
    if (cleanId.contains("UKG")) return 2;
    if (cleanId.contains("NURS")) return 0;
    
    // Explicit numerical mapping to avoid regex ambiguity for Junior/Senior split
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

    final match = RegExp(r'\d+').firstMatch(cleanId);
    if (match != null) return int.parse(match.group(0)!) + 3;

    if (cleanId.startsWith("I")) {
       if (cleanId.startsWith("IX")) return 12;
       if (cleanId.startsWith("IV")) return 7;
       if (cleanId.startsWith("III")) return 6;
       if (cleanId.startsWith("II")) return 5;
       if (cleanId.startsWith("VIII")) return 11;
       if (cleanId.startsWith("VII")) return 10;
       if (cleanId.startsWith("VI")) return 9;
       if (cleanId.startsWith("V")) return 8;
       return 4;
    }
    if (cleanId.startsWith("X")) return 13;
    return 100;
  }

  bool get isJunior => classWeight <= 7; // Classes LKG to 4 inclusive are Junior (Weights 1,2,4,5,6,7)

  static Student empty() {
    return const Student(
      studentId: "",
      schoolId: "",
      name: "Unknown",
      classId: "",
      parentName: "",
      parentPhone: "",
      status: "inactive",
      branchId: "boys",
    );
  }

  final String studentId;
  final String schoolId;
  final String name;
  final String classId;
  final String parentName;
  final String parentPhone;
  final String status;
  final String branchId;
  final String rollNo;
  final int monthlyFees;
  final String admissionDate;
  final String studentType;
  final String? bloodGroup;
  final String? marksData;
  final String profileImageUrl;
}
