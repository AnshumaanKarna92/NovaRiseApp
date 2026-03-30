import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:nova_rise_app/core/providers/filter_providers.dart";

class GlobalFilterBar extends ConsumerWidget {
  const GlobalFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(globalSchoolFilterProvider);

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _FilterChip(
              label: "All Gender",
              isSelected: filter.gender == GenderFilter.all,
              onSelected: () => ref.read(globalSchoolFilterProvider.notifier).state = filter.copyWith(gender: GenderFilter.all),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: "Boys",
              isSelected: filter.gender == GenderFilter.boys,
              icon: Icons.male,
              onSelected: () => ref.read(globalSchoolFilterProvider.notifier).state = filter.copyWith(gender: GenderFilter.boys),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: "Girls",
              isSelected: filter.gender == GenderFilter.girls,
              icon: Icons.female,
              onSelected: () => ref.read(globalSchoolFilterProvider.notifier).state = filter.copyWith(gender: GenderFilter.girls),
            ),
            const SizedBox(width: 16),
            Container(width: 1, height: 24, color: Colors.grey[200]),
            const SizedBox(width: 16),
            _FilterChip(
              label: "All Levels",
              isSelected: filter.level == LevelFilter.all,
              onSelected: () => ref.read(globalSchoolFilterProvider.notifier).state = filter.copyWith(level: LevelFilter.all),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: "Junior",
              isSelected: filter.level == LevelFilter.junior,
              onSelected: () => ref.read(globalSchoolFilterProvider.notifier).state = filter.copyWith(level: LevelFilter.junior),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: "Senior",
              isSelected: filter.level == LevelFilter.senior,
              onSelected: () => ref.read(globalSchoolFilterProvider.notifier).state = filter.copyWith(level: LevelFilter.senior),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : Colors.black87,
        ),
      ),
      avatar: icon != null ? Icon(icon, size: 14, color: isSelected ? Colors.white : Colors.black45) : null,
      selected: isSelected,
      onSelected: (_) => onSelected(),
      checkmarkColor: Colors.white,
      selectedColor: const Color(0xFF003D5B),
      backgroundColor: Colors.grey[100],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
