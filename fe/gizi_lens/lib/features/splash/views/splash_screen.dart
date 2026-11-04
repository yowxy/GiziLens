import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/route_names.dart';
import '../controllers/splash_controller.dart';
import 'widgets/cloud_sync_card.dart';
import 'widgets/mascot_viewfinder.dart';
import 'widgets/nutrient_chips_row.dart';
import 'widgets/splash_header.dart';
import 'widgets/splash_watermark_painter.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback? onCompleted;
  final double? staticProgress;
  final bool autoStart;

  const SplashScreen({
    super.key,
    this.onCompleted,
    this.staticProgress,
    this.autoStart = true,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final SplashController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SplashController();
    _controller.addListener(_onControllerUpdate);

    if (widget.staticProgress != null) {
      _controller.setStaticProgress(widget.staticProgress!);
    } else if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.startInitialization(
          onCompleted: () {
            if (!mounted) return;
            if (widget.onCompleted != null) {
              widget.onCompleted!();
            } else {
              context.go(RouteNames.onboarding);
            }
          },
        );
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundSplash,
      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: SplashWatermarkPainter(),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SplashHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.screenHorizontalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        const MascotViewfinder(),
                        const SizedBox(height: 16),
                        Image.asset(
                          AppAssets.logoGiziLens,
                          height: 48,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          AppStrings.tagline,
                          textAlign: TextAlign.center,
                          style: AppTypography.h3.copyWith(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryDark,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            AppStrings.splashSubtitle,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const NutrientChipsRow(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CloudSyncCard(
                        progress: _controller.progress,
                        isConnected: _controller.isConnected,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        AppStrings.institutionBgn,
                        textAlign: TextAlign.center,
                        style: AppTypography.captionBold.copyWith(
                          fontSize: 10.5,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AppStrings.institutionSpk,
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          fontSize: 10,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
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
