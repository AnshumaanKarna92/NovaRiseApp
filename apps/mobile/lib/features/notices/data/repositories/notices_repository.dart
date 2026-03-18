import '../../domain/models/notice_item.dart';

class NoticesRepository {
  const NoticesRepository();

  List<NoticeItem> fetchNotices() {
    return const [
      NoticeItem(
        title: 'School Holiday',
        body: 'Tomorrow the school will be closed for maintenance.',
        expiresAt: '2026-03-14',
      ),
      NoticeItem(
        title: 'Fee Reminder',
        body: 'Please clear all pending invoices before 31 March 2026.',
        expiresAt: '2026-03-31',
      ),
    ];
  }
}
