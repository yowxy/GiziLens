/// Filter categories for inspection history tabs.
enum HistoryTab {
  semua,
  sesuai,
  tidakSesuai,
}

/// Date range filters for history list.
enum HistoryDateFilter {
  hariIni,
  tujuhHari,
  tigaPuluhHari,
}

/// Immutable filter state for history screen.
class HistoryFilterModel {
  final HistoryTab activeTab;
  final HistoryDateFilter dateFilter;
  final String searchQuery;

  const HistoryFilterModel({
    this.activeTab = HistoryTab.semua,
    this.dateFilter = HistoryDateFilter.hariIni,
    this.searchQuery = '',
  });

  HistoryFilterModel copyWith({
    HistoryTab? activeTab,
    HistoryDateFilter? dateFilter,
    String? searchQuery,
  }) {
    return HistoryFilterModel(
      activeTab: activeTab ?? this.activeTab,
      dateFilter: dateFilter ?? this.dateFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}
