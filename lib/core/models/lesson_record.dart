import "package:cloud_firestore/cloud_firestore.dart" show Timestamp, FieldValue;

class LessonRecord {
  const LessonRecord({
    required this.recordId,
    required this.schoolId,
    required this.classId,
    required this.subject,
    this.period = "1st",
    this.chapter = "",
    required this.teacherId,
    required this.teacherName,
    required this.topic,
    this.topicBn = "",
    required this.homework,
    this.homeworkBn = "",
    required this.date,
    required this.createdAt,
  });

  factory LessonRecord.fromMap(String id, Map<String, dynamic> data) {
    return LessonRecord(
      recordId: id,
      schoolId: data["schoolId"] as String? ?? "",
      classId: data["classId"] as String? ?? "",
      subject: data["subject"] as String? ?? "",
      period: data["period"] as String? ?? "1st",
      chapter: data["chapter"] as String? ?? "",
      teacherId: data["teacherId"] as String? ?? "",
      teacherName: data["teacherName"] as String? ?? "",
      topic: data["topic"] as String? ?? "",
      topicBn: data["topicBn"] as String? ?? "",
      homework: data["homework"] as String? ?? "",
      homeworkBn: data["homeworkBn"] as String? ?? "",
      date: data["date"] as String? ?? "",
      createdAt: (data["createdAt"] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  final String recordId;
  final String schoolId;
  final String classId;
  final String subject;
  final String period;
  final String chapter;
  final String teacherId;
  final String teacherName;
  final String topic;
  final String topicBn;
  final String homework;
  final String homeworkBn;
  final String date;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      "schoolId": schoolId,
      "classId": classId,
      "subject": subject,
      "period": period,
      "chapter": chapter,
      "teacherId": teacherId,
      "teacherName": teacherName,
      "topic": topic,
      "topicBn": topicBn,
      "homework": homework,
      "homeworkBn": homeworkBn,
      "date": date,
      "createdAt": FieldValue.serverTimestamp(),
    };
  }
}
