import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/services/ai_mode.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/services/inspection_session_service.dart';
import '../../../../core/services/user_session_service.dart';
import '../../../../core/widgets/modal_card_dialog.dart';
import '../models/nutrition_analysis_model.dart';

class AuditConfirmationScreen extends StatefulWidget {
  const AuditConfirmationScreen({super.key});

  @override
  State<AuditConfirmationScreen> createState() =>
      _AuditConfirmationScreenState();
}

class _AuditConfirmationScreenState extends State<AuditConfirmationScreen> {
  bool _isSaving = false;

  void _handleSaveLock() async {
    setState(() => _isSaving = true);

    final session = InspectionSessionService.instance;
    final officer = UserSessionService.instance.account;

    try {
      final components = session.components;
      final metrics = NutrientMetricModel.fromComponents(
        components,
        session.targetAkg,
      );
      await FirestoreService.instance.saveInspection({
        'batchCode': session.batchCode,
        'schoolName': session.schoolDestination,
        'targetGroup': session.targetAkg.groupName,
        'session': AppStrings.targetGroupSession,
        'totalNetWeight': '${session.totalNetWeight} gram',
        'scannedAt': session.scannedAt?.toIso8601String(),
        'complianceStatus': metrics.every((metric) => metric.percentageOfTarget >= 85)
            ? 'SESUAI'
            : 'TIDAK SESUAI',
        'isLocked': true,
        'verifierRole': AppStrings.verifierRolePill,
        'detectionProvider': aiProviderName,
        'detectionModel': aiModelName,
        'targetAkg2019': {
          'groupName': session.targetAkg.groupName,
          'calories': session.targetAkg.lunchCalories,
          'protein': session.targetAkg.lunchProtein,
          'fat': session.targetAkg.lunchFat,
          'carbohydrate': session.targetAkg.lunchCarbohydrate,
          'fiber': session.targetAkg.lunchFiber,
        },
        'components': components
            .map(
              (item) => {
                'id': item.id,
                'name': item.name,
                'gram': item.estimatedGram,
                'compartmentNumber': item.compartmentNumber,
                'category': item.category,
                'confidencePercentage': item.confidencePercentage,
                'isVerified': item.isVerified,
                'nutrition': {
                  'calories': item.calories,
                  'protein': item.protein,
                  'fat': item.fat,
                  'carbohydrate': item.carbohydrate,
                  'fiber': item.fiber,
                },
              },
            )
            .toList(),
        'nutrition': {
          for (final metric in metrics)
            metric.name: {
              'currentValue': metric.currentValue,
              'targetValue': metric.targetValue,
              'unit': metric.unit,
              'percentageOfTarget': metric.percentageOfTarget,
              'statusLabel': metric.statusLabel,
            },
        },
        'notes': session.notes,
      });
    } catch (e) {
      debugPrint('Firestore save error: $e');
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    ModalCardDialog.show(
      context: context,
      builder: (dialogCtx) => ModalCardDialog(
        topBadge: Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
            color: Color(0xFFDCFCE7),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Icon(
              Icons.check_rounded,
              size: 38,
              color: Color(0xFF15803D),
            ),
          ),
        ),
        title: 'Hasil Audit Berhasil Dikunci!',
        subtitle:
            'Data pemeriksaan ompreng ${session.batchCode} untuk ${session.schoolDestination} telah tersinkronisasi aman dengan SPPG Cloud dan tersertifikasi BGN.',
        primaryButtonText: 'Kembali ke Dasbor',
        primaryButtonColor: AppColors.primaryDeep,
        primaryButtonIcon: Icons.home_rounded,
        onPrimaryPressed: () {
          Navigator.of(dialogCtx).pop();
          context.go(RouteNames.dashboard);
        },
      ),
    );
  }

  String _formatAuditDate(DateTime? date) {
    if (date == null) return '-';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    return '${isToday ? 'Hari ini, ' : ''}${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatAuditClock(DateTime? date) {
    if (date == null) return '-';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.hour)}:${two(date.minute)} WIB';
  }

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RouteNames.nutritionAnalysis);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundSplash,
        appBar: AppBar(
          backgroundColor: AppColors.backgroundSplash,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: _handleBack,
          ),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.confirmationTitle,
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                AppStrings.confirmationSubtitle,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4EC),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFDCE6DA), width: 1.0),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, size: 7, color: Color(0xFF1E6C45)),
                  SizedBox(width: 5),
                  Text(
                    AppStrings.sppgBadgeCode,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDeep,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFinalStageCard(),
                    const SizedBox(height: 16),
                    _buildSamplingProtocolCard(),
                    const SizedBox(height: 16),
                    _buildVerifiedPortionsCard(),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE4E9E0), width: 1.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x08000000),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _handleSaveLock,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDeep,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isSaving) ...[
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          ] else ...[
                            const Icon(
                              Icons.save_outlined,
                              size: 18,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  AppStrings.btnSaveInspectionLock,
                                  maxLines: 1,
                                  style: AppTypography.titleMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _handleBack,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.textPrimary,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        side: const BorderSide(
                          color: Color(0xFFCBD5E1),
                          width: 1.2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.format_list_bulleted_rounded,
                            size: 18,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                AppStrings.btnBackToInspection,
                                maxLines: 1,
                                style: AppTypography.titleMedium.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinalStageCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD6E4D4), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: Color(0xFF163E32),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.check_rounded, size: 16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              AppStrings.finalStageTitle,
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: AppColors.textPrimary,
              ),
            ),
          ),

        ],
      ),
    );
  }

  Widget _buildSamplingProtocolCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2ECE0), width: 1.2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.qr_code_2_rounded, size: 18, color: Color(0xFF64748B)),
              SizedBox(width: 6),
              Text(
                AppStrings.samplingProtocolTitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            InspectionSessionService.instance.batchCode,
            style: AppTypography.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            InspectionSessionService.instance.schoolDestination,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAF7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE8ECE5),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kelompok Sasaran',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        InspectionSessionService.instance.targetAkg.groupName,
                        style: AppTypography.captionBold.copyWith(
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppStrings.targetGroupSession,
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAF7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE8ECE5),
                      width: 1.0,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Waktu Audit',
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _formatAuditDate(InspectionSessionService.instance.scannedAt),
                        style: AppTypography.captionBold.copyWith(
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatAuditClock(InspectionSessionService.instance.scannedAt),
                        style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAF7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8ECE5), width: 1.0),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDAECE0),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      UserSessionService.instance.account.initials,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E6C45),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.verifierLabel,
                        style: AppTypography.caption.copyWith(
                          fontSize: 10.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        UserSessionService.instance.account.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.captionBold.copyWith(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    AppStrings.verifierRolePill,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedPortionsCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2ECE0), width: 1.2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.layers_outlined,
                size: 20,
                color: AppColors.primaryDeep,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  AppStrings.verifiedPortionsTitle,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppStrings.totalNetWeightLabel,
                    style: AppTypography.caption.copyWith(
                      fontSize: 10,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    '${InspectionSessionService.instance.totalNetWeight} gram',
                    style: AppTypography.captionBold.copyWith(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                  ),

                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (int i = 0; i < InspectionSessionService.instance.components.length; i++) ...[
            _buildVerifiedPortionItem(
              name: InspectionSessionService.instance.components[i].name,
              desc: '${InspectionSessionService.instance.components[i].category} • ${InspectionSessionService.instance.components[i].estimatedGram}g',
              icon: InspectionSessionService.instance.components[i].iconData,
              badgeLabel: InspectionSessionService.instance.components[i].complianceStatus,
            ),
            if (i < InspectionSessionService.instance.components.length - 1)
              const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildVerifiedPortionItem({
    required String name,
    required String desc,
    required IconData icon,
    required String badgeLabel,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAF7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8ECE5), width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2ECE0), width: 1.0),
            ),
            child: Icon(icon, size: 20, color: AppColors.primaryDeep),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.captionBold.copyWith(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  desc,
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 11,
                  color: Color(0xFF15803D),
                ),
                const SizedBox(width: 4),
                Text(
                  badgeLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
