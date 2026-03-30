import "package:flutter_riverpod/flutter_riverpod.dart";

enum GenderFilter { all, boys, girls }
enum LevelFilter { all, junior, senior }

class GlobalSchoolFilter {
  const GlobalSchoolFilter({
    this.gender = GenderFilter.all,
    this.level = LevelFilter.all,
  });

  final GenderFilter gender;
  final LevelFilter level;

  GlobalSchoolFilter copyWith({
    GenderFilter? gender,
    LevelFilter? level,
  }) {
    return GlobalSchoolFilter(
      gender: gender ?? this.gender,
      level: level ?? this.level,
    );
  }
}

final globalSchoolFilterProvider = StateProvider<GlobalSchoolFilter>((ref) {
  return const GlobalSchoolFilter();
});
