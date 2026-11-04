import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routing/route_names.dart';
import '../controllers/onboarding_controller.dart';
import 'widgets/onboarding_app_bar.dart';
import 'widgets/onboarding_footer.dart';
import 'widgets/page_nutrisi_seimbang.dart';
import 'widgets/page_scan_ompreng.dart';

class OnboardingScreen extends StatefulWidget {
  final int initialPage;

  const OnboardingScreen({
    super.key,
    this.initialPage = 0,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final OnboardingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = OnboardingController();
    _controller.addListener(_onUpdate);

    if (widget.initialPage > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _controller.pageController.jumpToPage(widget.initialPage);
      });
    }
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_controller.isLastPage) {
      context.go(RouteNames.login);
    } else {
      _controller.nextPage();
    }
  }

  void _handleSkip() {
    context.go(RouteNames.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            OnboardingAppBar(
              showSkip: !_controller.isLastPage,
              onSkip: _handleSkip,
            ),
            Expanded(
              child: PageView(
                controller: _controller.pageController,
                onPageChanged: _controller.onPageChanged,
                children: const [
                  PageScanOmpreng(),
                  PageNutrisiSeimbang(),
                ],
              ),
            ),
            OnboardingFooter(
              currentIndex: _controller.currentIndex,
              onNext: _handleNext,
            ),
          ],
        ),
      ),
    );
  }
}
