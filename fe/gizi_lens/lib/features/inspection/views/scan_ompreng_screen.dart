import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/route_names.dart';
import '../controllers/scan_ompreng_controller.dart';
import 'widgets/google_lens_hologram_scanner.dart';
import 'widgets/scan_validation_card.dart';
import 'widgets/step_progress_app_bar.dart';

class ScanOmprengScreen extends StatefulWidget {
  const ScanOmprengScreen({super.key});

  @override
  State<ScanOmprengScreen> createState() => _ScanOmprengScreenState();
}

class _ScanOmprengScreenState extends State<ScanOmprengScreen> {
  late final ScanOmprengController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScanOmprengController();
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleShutterTap() async {
    final success = await _controller.capturePhoto();
    if (success && mounted) {
      try {
        context.push(RouteNames.componentDetection);
      } catch (_) {
        context.go(RouteNames.componentDetection);
      }
    }
  }

  void _showScanHelp() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Panduan Scan Baki Ompreng',
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Posisikan kamera smartphone tepat di atas nampan makan saji (tegak lurus 90 derajat). Pastikan seluruh 5 sekat ompreng masuk ke dalam bingkai panduan emas dan pencahayaan ruangan cukup terang agar AI dapat mendeteksi gramatur porsi secara akurat.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDeep,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text('Mengerti', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
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
        backgroundColor: const Color(0xFF0C1014),
        appBar: StepProgressAppBar(
          title: AppStrings.inspectionTitle,
          subtitle: AppStrings.step2Of4,
          currentStep: 2,
          totalSteps: 4,
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(RouteNames.menuInspection);
            }
          },
          onHelpTap: _showScanHelp,
        ),
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF142B23),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFF225742),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.wb_sunny_outlined,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.lightingTip,
                      textAlign: TextAlign.center,
                      style: AppTypography.caption.copyWith(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: GoogleLensHologramScanner(
                          isScanning: true,
                          showBoundingBoxes: _controller.showAiBoundingBoxes,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.asset(
                                AppAssets.omprengBakiSample,
                                fit: BoxFit.cover,
                              ),
                              Container(
                                color: Colors.black.withValues(alpha: 0.15),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildCircleIconButton(
                      icon: Icons.menu_book_rounded,
                      onTap: _showScanHelp,
                    ),
                    _buildShutterButton(),
                    _buildCircleIconButton(
                      icon: Icons.drive_folder_upload_rounded,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Pilih citra ompreng baki dari galeri...'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ScanValidationCard(
                  isLightingOk: _controller.isLightingOk,
                  isWholeTrayVisible: _controller.isWholeTrayVisible,
                  isCameraFocused: _controller.isCameraFocused,
                  isWithinFrame: _controller.isWithinFrame,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.straighten_rounded,
                      size: 15,
                      color: Color(0xFFC7A250),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        AppStrings.positionCameraPrompt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: const Color(0xFF9EABA2),
                          fontSize: 11.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShutterButton() {
    return GestureDetector(
      onTap: _controller.isAnalyzing ? null : _handleShutterTap,
      child: Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFD6A64B),
            width: 3.5,
          ),
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1B4E41),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: _controller.isAnalyzing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 30,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFF22262B),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }
}
