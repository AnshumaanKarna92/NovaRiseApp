import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
// import "package:url_launcher/url_launcher.dart";

import "package:nova_rise_app/core/models/app_user.dart";
import "package:nova_rise_app/core/models/transport_route.dart";
import "../../../../shared/widgets/async_value_view.dart";
import "../../../../shared/widgets/app_surface.dart";
import "../../../auth/presentation/controllers/session_controller.dart";
import "../../../../core/providers/school_providers.dart";
import "../controllers/transport_controller.dart";

class TransportScreen extends ConsumerWidget {
  const TransportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routes = ref.watch(routesProvider);
    final user = ref.watch(userProfileProvider).valueOrNull;
    final isTab = !Navigator.of(context).canPop();

    final canUpdate = user?.role == UserRole.admin;

    return Scaffold(
      appBar: isTab ? null : AppBar(title: const Text("Bus Tracking")),
      body: AsyncValueView(
        value: routes,
        data: (items) {
          if (items.isEmpty && canUpdate) {
            return _EmptyState(canUpdate: canUpdate);
          }
          if (items.isEmpty) {
            return const Center(child: Text("No transport routes assigned."));
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const ScreenIntroCard(
                title: "Bus & Transport",
                description:
                    "Monitor school bus locations, driver details, and real-time transit status for your assigned route.",
                icon: Icons.directions_bus_outlined,
                accent: Color(0xFF003D5B),
              ),
              const SizedBox(height: 24),
              for (final route in items)
                _RouteCard(route: route, canUpdate: canUpdate),
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.canUpdate});
  final bool canUpdate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bus_alert_outlined, size: 64, color: Colors.black12),
            const SizedBox(height: 16),
            const Text(
              "No Routes Active",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Transport routes haven't been provisioned in the system yet.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            if (canUpdate) ...[
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }
}

class _RouteCard extends ConsumerWidget {
  const _RouteCard({required this.route, required this.canUpdate});
  final TransportRoute route;
  final bool canUpdate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _getStatusColor(route.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.routeName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        route.vehicleNumber.isEmpty ? "Vehicle: TBD" : "Vehicle: ${route.vehicleNumber}",
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                StatusChip(label: route.statusLabel.toUpperCase(), color: statusColor),
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                const Icon(Icons.person_pin_outlined, size: 20, color: Colors.black45),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(route.driverName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text("Driver & In-charge", style: TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () {
                    // launchUrl(Uri.parse("tel:${route.driverPhone}"));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Calling ${route.driverPhone}..."))
                    );
                  },
                  icon: const Icon(Icons.phone),
                  constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                ),
              ],
            ),
            if (route.currentStop.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 16, color: statusColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Last Stop: ${route.currentStop}",
                        style: TextStyle(fontSize: 13, color: statusColor, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (canUpdate) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(context, ref, "morning_pickup"),
                      child: const Text("Start Morning"),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _updateStatus(context, ref, "afternoon_drop"),
                      child: const Text("Start Afternoon"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _updateStatus(context, ref, "completed"),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF00A86B)),
                  child: const Text("Mark Route Completed"),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case "morning_pickup":
      case "afternoon_drop":
        return const Color(0xFFD4AF37);
      case "completed":
        return const Color(0xFF00A86B);
      default:
        return const Color(0xFF003D5B);
    }
  }

  void _updateStatus(BuildContext context, WidgetRef ref, String status) {
    ref.read(transportUpdateControllerProvider.notifier).updateStatus(
          routeId: route.routeId,
          status: status,
          currentStop: status == "completed" ? "At Depot" : "Route Started",
        );
  }
}
