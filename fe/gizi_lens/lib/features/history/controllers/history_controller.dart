import 'package:flutter/material.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../core/services/notification_service.dart';
import '../models/history_filter_model.dart';

/// Controller managing history tabs, search queries, date filters, and live Firestore data.
class HistoryController extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();

  HistoryFilterModel _filter = const HistoryFilterModel();

  List<Map<String, dynamic>> _inspections = [];
  bool _isLoading = false;

  HistoryFilterModel get filter => _filter;
  bool get hasNotification => NotificationService.instance.hasUnread;
  HistoryTab get activeTab => _filter.activeTab;
  HistoryDateFilter get activeDateFilter => _filter.dateFilter;
  bool get isLoading => _isLoading;

  List<Map<String, dynamic>> get filteredInspections {
    return _inspections.where((item) {
      // Tab filter
      final status = (item['complianceStatus'] as String? ?? '').toUpperCase();
      if (_filter.activeTab == HistoryTab.sesuai && status != 'SESUAI') {
        return false;
      }
      if (_filter.activeTab == HistoryTab.tidakSesuai &&
          status != 'TIDAK SESUAI') {
        return false;
      }

      final createdDate = DateTime.tryParse(
        item['createdDateIso']?.toString() ?? '',
      );
      if (createdDate != null && !_matchesDateFilter(createdDate)) {
        return false;
      }

      // Search filter
      final q = _filter.searchQuery.toLowerCase();
      if (q.isNotEmpty) {
        final batch = (item['batchCode'] as String? ?? '').toLowerCase();
        final school = (item['schoolName'] as String? ?? '').toLowerCase();
        if (!batch.contains(q) && !school.contains(q)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  bool _matchesDateFilter(DateTime createdDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final start = switch (_filter.dateFilter) {
      HistoryDateFilter.hariIni => today,
      HistoryDateFilter.tujuhHari => today.subtract(const Duration(days: 6)),
      HistoryDateFilter.tigaPuluhHari => today.subtract(
        const Duration(days: 29),
      ),
    };
    return !createdDate.isBefore(start);
  }

  HistoryController() {
    searchController.addListener(_onSearchChanged);
    NotificationService.instance.addListener(_onNotificationsChanged);
    loadInspections();
  }

  Future<void> loadInspections() async {
    _isLoading = true;
    notifyListeners();

    try {
      _inspections = await FirestoreService.instance.getInspections();
      NotificationService.instance.updateFromInspections(_inspections);
    } catch (_) {
      _inspections = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _onNotificationsChanged() {
    notifyListeners();
  }

  void _onSearchChanged() {
    final query = searchController.text.trim();
    if (_filter.searchQuery != query) {
      _filter = _filter.copyWith(searchQuery: query);
      notifyListeners();
    }
  }

  void setTab(HistoryTab tab) {
    if (_filter.activeTab != tab) {
      _filter = _filter.copyWith(activeTab: tab);
      notifyListeners();
    }
  }

  void setDateFilter(HistoryDateFilter dateFilter) {
    if (_filter.dateFilter != dateFilter) {
      _filter = _filter.copyWith(dateFilter: dateFilter);
      notifyListeners();
    }
  }

  void clearSearch() {
    searchController.clear();
    _filter = _filter.copyWith(searchQuery: '');
    notifyListeners();
  }


  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    NotificationService.instance.removeListener(_onNotificationsChanged);
    searchController.dispose();
    super.dispose();
  }
}
