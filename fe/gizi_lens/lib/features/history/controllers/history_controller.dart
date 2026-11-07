import 'package:flutter/material.dart';
import '../models/history_filter_model.dart';

// Controller managing history tabs, search queries, and date filters
class HistoryController extends ChangeNotifier {
  final TextEditingController searchController = TextEditingController();

  HistoryFilterModel _filter = const HistoryFilterModel();
  bool _hasNotification = true;

  HistoryFilterModel get filter => _filter;
  bool get hasNotification => _hasNotification;
  HistoryTab get activeTab => _filter.activeTab;
  HistoryDateFilter get activeDateFilter => _filter.dateFilter;

  HistoryController() {
    searchController.addListener(_onSearchChanged);
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

  void dismissNotification() {
    _hasNotification = false;
    notifyListeners();
  }

  @override
  void dispose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }
}
