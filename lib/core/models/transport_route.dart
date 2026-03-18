import "package:cloud_firestore/cloud_firestore.dart";

class TransportRoute {
  TransportRoute({
    required this.routeId,
    required this.routeName,
    required this.driverName,
    required this.driverPhone,
    required this.status,
    required this.lastUpdateAt,
    this.currentStop = "",
    this.vehicleNumber = "",
  });

  factory TransportRoute.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransportRoute(
      routeId: data["routeId"] ?? "",
      routeName: data["routeName"] ?? "",
      driverName: data["driverName"] ?? "",
      driverPhone: data["driverPhone"] ?? "",
      status: data["status"] ?? "idle",
      lastUpdateAt: (data["lastUpdateAt"] as Timestamp?)?.toDate() ?? DateTime.now(),
      currentStop: data["currentStop"] ?? "",
      vehicleNumber: data["vehicleNumber"] ?? "",
    );
  }

  final String routeId;
  final String routeName;
  final String driverName;
  final String driverPhone;
  final String status; // idle, morning_pickup, afternoon_drop, completed
  final DateTime lastUpdateAt;
  final String currentStop;
  final String vehicleNumber;

  String get statusLabel {
    switch (status) {
      case "morning_pickup":
        return "Morning Pickup";
      case "afternoon_drop":
        return "Afternoon Drop-off";
      case "completed":
        return "Route Completed";
      default:
        return "At Depot (Idle)";
    }
  }
}
