import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:nova_rise_app/core/models/transport_route.dart";
import "../../../auth/presentation/controllers/session_controller.dart";
import "../../../../core/providers/school_providers.dart";

final transportServiceProvider = Provider<TransportService>((ref) {
  return TransportService(ref.watch(firebaseFirestoreProvider));
});

class TransportService {
  TransportService(this._firestore);
  final FirebaseFirestore _firestore;

  Stream<List<TransportRoute>> watchRoutes() {
    return _firestore
        .collection("transport_routes")
        .orderBy("routeName")
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => TransportRoute.fromFirestore(doc)).toList());
  }

  Future<void> updateRouteStatus({
    required String routeId,
    required String status,
    String currentStop = "",
  }) async {
    await _firestore.collection("transport_routes").doc(routeId).update({
      "status": status,
      "currentStop": currentStop,
      "lastUpdateAt": FieldValue.serverTimestamp(),
    });
  }
}

final routesProvider = StreamProvider<List<TransportRoute>>((ref) {
  return ref.watch(transportServiceProvider).watchRoutes();
});

class TransportUpdateState {
  const TransportUpdateState({this.isUpdating = false, this.error});
  final bool isUpdating;
  final String? error;
}

final transportUpdateControllerProvider =
    StateNotifierProvider<TransportUpdateController, TransportUpdateState>((ref) {
  return TransportUpdateController(ref.watch(transportServiceProvider));
});

class TransportUpdateController extends StateNotifier<TransportUpdateState> {
  TransportUpdateController(this._service) : super(const TransportUpdateState());
  final TransportService _service;

  Future<void> updateStatus({
    required String routeId,
    required String status,
    String currentStop = "",
  }) async {
    state = const TransportUpdateState(isUpdating: true);
    try {
      await _service.updateRouteStatus(
        routeId: routeId,
        status: status,
        currentStop: currentStop,
      );
      state = const TransportUpdateState();
    } catch (e) {
      state = TransportUpdateState(error: e.toString());
    }
  }
}
