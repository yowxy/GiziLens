import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';

class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({super.key, required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final batchCode = item['batchCode'] as String? ?? '-';
    final schoolName = item['schoolName'] as String? ?? '-';
    final session = item['session'] as String? ?? '-';
    final targetGroup = item['targetGroup'] as String? ?? '-';
    final weight = item['totalNetWeight'] as String? ?? '-';
    final notes = item['notes'] as String? ?? '';
    final isSesuai = (item['complianceStatus'] as String? ?? '').toUpperCase() == 'SESUAI';
    final components = _mapList(item['components']);
    final nutrition = item['nutrition'] is Map ? Map<String, dynamic>.from(item['nutrition'] as Map) : <String, dynamic>{};

    return Scaffold(
      backgroundColor: AppColors.backgroundSplash,
      appBar: AppBar(
        backgroundColor: AppColors.headerDarkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          batchCode,
          style: AppTypography.titleMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSesuai ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isSesuai ? 'SESUAI AKG' : 'TIDAK SESUAI',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: isSesuai ? const Color(0xFF15803D) : const Color(0xFFE11D48),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _infoRow('Sekolah / Tujuan', schoolName),
                _infoRow('Sesi', session),
                _infoRow('Kelompok Sasaran', targetGroup),
                _infoRow('Total Bobot Bersih', weight),
                _infoRow('Waktu Pemeriksaan', _formatDate(item['createdDateIso'] as String?)),
                _infoRow('Petugas', item['userEmail'] as String? ?? '-'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Komponen Terdeteksi (${components.length})'),
          const SizedBox(height: 8),
          if (components.isEmpty)
            _emptyText('Tidak ada komponen yang tercatat.')
          else
            ...components.map(_componentCard),
          const SizedBox(height: 16),
          _sectionTitle('Nutrisi vs Target AKG'),
          const SizedBox(height: 8),
          if (nutrition.isEmpty)
            _emptyText('Data nutrisi tidak tersedia.')
          else
            _card(
              child: Column(
                children: nutrition.entries
                    .map((entry) => _nutritionRow(entry.key, _mapOrEmpty(entry.value)))
                    .toList(),
              ),
            ),
          if (notes.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionTitle('Catatan'),
            const SizedBox(height: 8),
            _card(
              child: Text(
                notes,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2ECE0), width: 1.2),
      ),
      child: child,
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
    );
  }

  Widget _emptyText(String text) {
    return Text(
      text,
      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _componentCard(Map<String, dynamic> component) {
    final nutrition = _mapOrEmpty(component['nutrition']);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    component['name'] as String? ?? '-',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  '${_formatNumber(component['gram'])} g',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Kalori ${_formatNumber(nutrition['calories'])} kkal • '
              'Protein ${_formatNumber(nutrition['protein'])} g • '
              'Lemak ${_formatNumber(nutrition['fat'])} g • '
              'Karbo ${_formatNumber(nutrition['carbohydrate'])} g • '
              'Serat ${_formatNumber(nutrition['fiber'])} g',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutritionRow(String key, Map<String, dynamic> metric) {
    final percentage = metric['percentageOfTarget'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              key,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            '${_formatNumber(metric['currentValue'])} / ${_formatNumber(metric['targetValue'])} ${metric['unit'] ?? ''}',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(width: 10),
          Text(
            percentage == null ? '-' : '$percentage%',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDeep,
            ),
          ),
        ],
      ),
    );
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Map<String, dynamic> _mapOrEmpty(dynamic value) {
    return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  }

  static String _formatNumber(dynamic value) {
    if (value is num) {
      return value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
    }
    return value?.toString() ?? '-';
  }

  static String _formatDate(String? iso) {
    final date = DateTime.tryParse(iso ?? '');
    if (date == null) return '-';
    final local = date.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} ${two(local.hour)}:${two(local.minute)}';
  }
}
