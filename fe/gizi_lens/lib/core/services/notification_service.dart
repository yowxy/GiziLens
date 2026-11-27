import 'package:flutter/foundation.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';

/// Turns inspections marked TIDAK SESUAI into deficit alerts and tracks which ones were seen.
class NotificationService extends ChangeNotifier {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _enabled = true;
  bool _initialUnread = true;
  List<Map<String, dynamic>> _alerts = const [];
  final Set<String> _seenIds = {};

  bool get enabled => _enabled;
  List<Map<String, dynamic>> get alerts => _enabled ? _alerts : const [];
  bool get hasUnread =>
      _enabled &&
      (_initialUnread || alerts.any((item) => !_seenIds.contains(item['id'])));

  Future<void> loadSettings() async {
    try {
      final uid = FirebaseAuthService.instance.currentUser?.uid;
      if (uid == null) return;
      final profile = await FirestoreService.instance.getUserProfile(uid);
      final stored = profile?['notificationsEnabled'];
      if (stored is bool && stored != _enabled) {
        _enabled = stored;
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> setEnabled(bool value) async {
    _enabled = value;
    notifyListeners();
    try {
      await FirestoreService.instance.updateCurrentUserProfile({'notificationsEnabled': value});
    } catch (_) {}
  }

  void updateFromInspections(List<Map<String, dynamic>> inspections) {
    _initialUnread = false;
    _alerts = inspections
        .where((item) => (item['complianceStatus'] as String? ?? '').toUpperCase() == 'TIDAK SESUAI')
        .toList();
    notifyListeners();
  }

  void markAllRead() {
    _initialUnread = false;
    _seenIds.addAll(_alerts.map((item) => item['id'] as String? ?? ''));
    notifyListeners();
  }
}
