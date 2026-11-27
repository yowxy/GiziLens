import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/routing/route_names.dart';
import '../../../core/services/pdf_report_service.dart';
import '../../../core/services/user_session_service.dart';
import 'widgets/annotated_scan_image.dart';
import 'widgets/audit_export_action_footer.dart';
import 'widgets/pdf_export_success_dialog.dart';

class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({
    super.key,
    required this.item,
    this.onExportPdf,
  });

  final Map<String, dynamic> item;
  final Future<PdfExportResult> Function(Map<String, dynamic> item)? onExportPdf;

  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  bool _isExporting = false;

  Future<void> _handleExportPdf() async {
    if (_isExporting) return;

    // PDF export is a Premium-only feature; free accounts get the upsell.
    if (!UserSessionService.instance.account.isPremium) {
      await _showPremiumOnlyDialog();
      return;
    }

    setState(() => _isExporting = true);

    try {
      final exporter =
          widget.onExportPdf ?? PdfReportService.instance.exportAndShareReport;
      await exporter(widget.item);
      if (!mounted) return;

      final batchCode = widget.item['batchCode'] as String? ?? 'MBG-AUDIT';
      await PdfExportSuccessDialog.show(
        context,
        auditId: batchCode,
        onBackToHome: _navigateToDashboard,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat PDF: $e'),
          backgroundColor: AppColors.statTidakSesuaiRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _showPremiumOnlyDialog() async {
    final goToPricing = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.workspace_premium_rounded,
              color: Color(0xFFD6A24A),
              size: 22,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ekspor PDF khusus Premium',
                style: AppTypography.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Akun gratis hanya dapat melihat hasil audit di aplikasi. '
          'Aktifkan GiziLens Premium untuk mengekspor berita acara resmi '
          'PDF (watermark + SHA-256) dan Excel.',
          style: AppTypography.bodySmall.copyWith(
            fontSize: 12.5,
            height: 1.5,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              'Nanti',
              style: AppTypography.titleSmall.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDeep,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Lihat Paket',
              style: AppTypography.titleSmall.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (goToPricing == true && mounted) {
      try {
        context.push(RouteNames.pricing);
      } catch (_) {
        context.go(RouteNames.pricing);
      }
    }
  }

  void _navigateToDashboard() {
    try {
      context.go(RouteNames.dashboard);
    } catch (_) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _handleBackToHistory() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    try {
      context.go(RouteNames.history);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final batchCode = item['batchCode'] as String? ?? '-';
    final schoolName = item['schoolName'] as String? ?? '-';
    final session = item['session'] as String? ?? 'Makan Siang';
    final targetGroup = item['targetGroup'] as String? ?? '-';
    final weight = item['totalNetWeight'] as String? ?? '-';
    final notes = item['notes'] as String? ?? '';
    final officer = (item['officerName'] as String?)?.trim().isNotEmpty == true
        ? item['officerName'] as String
        : (item['userEmail'] as String? ?? '-');
    final imageBytes = item['imageBytes'] is Uint8List
        ? item['imageBytes'] as Uint8List
        : null;
    final imageWidth = (item['imageWidth'] as num?)?.toDouble();
    final imageHeight = (item['imageHeight'] as num?)?.toDouble();
    final aspectRatio =
        (imageWidth != null && imageHeight != null && imageHeight > 0)
            ? imageWidth / imageHeight
            : (item['imageAspectRatio'] as num?)?.toDouble();
    final isSesuai =
        (item['complianceStatus'] as String? ?? '').toUpperCase() == 'SESUAI';
    final components = _mapList(item['components']);
    final nutrition = _mapOrEmpty(item['nutrition']);

    return Scaffold(
      backgroundColor: AppColors.backgroundSplash,
      appBar: AppBar(
        backgroundColor: AppColors.headerDarkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detail Pemeriksaan',
              style: AppTypography.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              batchCode,
              style: AppTypography.bodySmall.copyWith(
                color: const Color(0xFFA5BFB6),
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          AnnotatedScanImage(
            imageUrl: item['imageUrl'] as String?,
            imageBytes: imageBytes,
            components: components,
            aspectRatio: aspectRatio,
            height: 220,
            width: double.infinity,
            showLabels: true,
            borderRadius: BorderRadius.circular(18),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statusPill(isSesuai),
              const Spacer(),
              const Icon(
                Icons.photo_camera_outlined,
                size: 14,
                color: AppColors.textMuted,
              ),
              const SizedBox(width: 4),
              const Text(
                'Hasil scan AI',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Menu Gizi Seimbang',
            style: AppTypography.h1.copyWith(
              fontSize: 21,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$schoolName • $session',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle('Ringkasan 5 Pilar Nutrisi'),
          const SizedBox(height: 8),
          _card(
            child: nutrition.isEmpty
                ? _emptyText('Data nutrisi tidak tersedia.')
                : Column(
                    children: [
                      for (var i = 0; i < _nutritionSpecs.length; i++)
                        _nutritionBar(
                          _nutritionSpecs[i].label,
                          _resolveMetric(nutrition, _nutritionSpecs[i].keys),
                          isLast: i == _nutritionSpecs.length - 1,
                        ),
                    ],
                  ),
          ),
          const SizedBox(height: 18),
          _sectionTitle('Informasi Pemeriksaan'),
          const SizedBox(height: 8),
          _card(
            child: Column(
              children: [
                _infoRow('Sekolah / Tujuan', schoolName),
                _infoRow('Kelompok Sasaran', targetGroup),
                _infoRow('Total Bobot Bersih', weight),
                _infoRow(
                  'Waktu Pemeriksaan',
                  _formatDate(
                    (item['scannedAt'] ?? item['createdDateIso']) as String?,
                  ),
                ),
                _infoRow('Petugas', officer),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _sectionTitle('Komponen Terdeteksi (${components.length})'),
          const SizedBox(height: 8),
          if (components.isEmpty)
            _emptyText('Tidak ada komponen yang tercatat.')
          else
            ...List.generate(
              components.length,
              (index) => _componentCard(components[index], index),
            ),
          if (notes.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            _sectionTitle('Catatan'),
            const SizedBox(height: 8),
            _card(
              child: Text(
                notes,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: AuditExportActionFooter(
        isExporting: _isExporting,
        onExportPdf: _handleExportPdf,
        onBackToHistory: _handleBackToHistory,
      ),
    );
  }

  static const List<({String label, List<String> keys})> _nutritionSpecs = [
    (label: 'Kalori', keys: ['Kalori', 'Energi Total']),
    (label: 'Protein', keys: ['Protein', 'Protein Hewani & Nabati']),
    (label: 'Lemak', keys: ['Lemak', 'Lemak Sehat']),
    (label: 'Karbohidrat', keys: ['Karbohidrat', 'Karbohidrat Kompleks']),
    (label: 'Serat', keys: ['Serat']),
  ];

  static Map<String, dynamic> _resolveMetric(
    Map<String, dynamic> nutrition,
    List<String> keys,
  ) {
    for (final key in keys) {
      if (nutrition[key] is Map) {
        return _mapOrEmpty(nutrition[key]);
      }
    }
    return <String, dynamic>{};
  }

  Widget _nutritionBar(
    String label,
    Map<String, dynamic> metric, {
    required bool isLast,
  }) {
    final current = _toDouble(metric['currentValue']);
    final target = _toDouble(metric['targetValue']);
    final unit = metric['unit']?.toString() ?? '';
    final rawPercentage = _toDouble(metric['percentageOfTarget']);
    final percentage = rawPercentage > 0
        ? rawPercentage
        : (target > 0 ? (current / target * 100) : 0.0);
    final ratio = (percentage / 100).clamp(0.0, 1.0).toDouble();
    final color = _barColor(percentage.toDouble());

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                '${_formatNumber(current)} / ${_formatNumber(target)} $unit',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${percentage.round()}%',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Container(height: 8, color: AppColors.progressTrack),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(height: 8, color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _componentCard(Map<String, dynamic> component, int index) {
    final nutrition = _mapOrEmpty(component['nutrition']);
    final color = bboxColorForIndex(index);
    final hasBbox = component['bbox'] is Map;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    component['name'] as String? ?? '-',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (hasBbox)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F6F1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'BBox',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Text(
                  '${_formatNumber(component['gram'])} g',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
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
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(bool isSesuai) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSesuai ? const Color(0xFFDCFCE7) : const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSesuai ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 13,
            color: isSesuai ? const Color(0xFF15803D) : const Color(0xFFE11D48),
          ),
          const SizedBox(width: 4),
          Text(
            isSesuai ? 'Sesuai AKG' : 'Tidak Sesuai',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isSesuai ? const Color(0xFF15803D) : const Color(0xFFE11D48),
            ),
          ),
        ],
      ),
    );
  }

  Color _barColor(double percentage) {
    if (percentage < 85) return const Color(0xFFE11D48);
    if (percentage > 115) return AppColors.accentAmber;
    return AppColors.statSesuaiGreen;
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
      style: AppTypography.titleMedium.copyWith(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
        fontSize: 15,
      ),
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
            width: 130,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static List<Map<String, dynamic>> _mapList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  static Map<String, dynamic> _mapOrEmpty(dynamic value) {
    return value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
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
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)} ${months[local.month - 1]} ${local.year} '
        '${two(local.hour)}:${two(local.minute)} WIB';
  }
}
