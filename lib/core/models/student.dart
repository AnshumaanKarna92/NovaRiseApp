class Student {
  const Student({
    required this.studentId,
    required this.schoolId,
    required this.name,
    required this.classId,
    required this.parentName,
    required this.parentPhone,
    required this.status,
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
    );
  }

  final String studentId;
  final String schoolId;
  final String name;
  final String classId;
  final String parentName;
  final String parentPhone;
  final String status;
}
