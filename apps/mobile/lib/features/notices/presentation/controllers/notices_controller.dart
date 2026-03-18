import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/notices_repository.dart';
import '../../domain/models/notice_item.dart';

final noticesRepositoryProvider = Provider((ref) => const NoticesRepository());
final noticesProvider = Provider<List<NoticeItem>>((ref) {
  return ref.watch(noticesRepositoryProvider).fetchNotices();
});
