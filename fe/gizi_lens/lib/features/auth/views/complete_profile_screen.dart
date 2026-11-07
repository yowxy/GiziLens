import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/custom_text_field.dart';
import '../controllers/complete_profile_controller.dart';
import 'widgets/officer_id_locked_field.dart';
import 'widgets/officer_profile_card.dart';
import 'widgets/role_selection_card.dart';

/// Pixel-perfect and buttery-smooth implementation of Complete Profile Screen (2auth.png).
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  late final CompleteProfileController _controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = CompleteProfileController();
    _controller.addListener(_onControllerUpdate);
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    FocusScope.of(context).unfocus();
    final success = await _controller.saveProfile();
    if (success && mounted) {
      context.go(RouteNames.home);
    }
  }

  void _handleSkip() {
    FocusScope.of(context).unfocus();
    context.go(RouteNames.home);
  }

  void _showPhotoPickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderMedium,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Unggah Foto Profil',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Foto resmi untuk kartu identitas auditor lapangan SPPG.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: AppColors.primaryDeep,
                  ),
                ),
                title: Text(
                  'Ambil Foto dari Kamera',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Gunakan kamera HP secara langsung',
                  style: AppTypography.caption,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Foto profil berhasil diperbarui'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColors.primaryDeep,
                  ),
                ),
                title: Text(
                  'Pilih dari Galeri',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Format JPG atau PNG (Maks 5MB)',
                  style: AppTypography.caption,
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Foto profil berhasil dipilih dari galeri'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomSafeArea = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.backgroundSplash,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: EdgeInsets.fromLTRB(
                  AppDimensions.screenHorizontalPadding,
                  topPadding + 10,
                  AppDimensions.screenHorizontalPadding,
                  145 + bottomSafeArea + bottomInset,
                ),
                child: Form(
                  key: _controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          onTap: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(RouteNames.login);
                            }
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 6,
                            ),
                            child: const Icon(
                              Icons.arrow_back_rounded,
                              color: AppColors.textPrimary,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Screen Header: Shield Icon + Title
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 24,
                            color: AppColors.textPrimary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppStrings.completeProfileTitle,
                              style: AppTypography.h2.copyWith(
                                fontSize: 21,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Text(
                        AppStrings.completeProfileSubtitle,
                        style: AppTypography.bodyMedium.copyWith(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),

                      OfficerProfileCard(
                        profile: _controller.profile,
                        onUploadPhoto: _showPhotoPickerSheet,
                      ),
                      const SizedBox(height: 20),

                      CustomTextField(
                        label: AppStrings.fullNameLabel,
                        headerTrailing: Text(
                          AppStrings.fullNameHelper,
                          style: AppTypography.caption.copyWith(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                        hintText: AppStrings.fullNameHint,
                        prefixIcon: const Icon(
                          Icons.badge_outlined,
                          size: 20,
                          color: AppColors.iconFieldMuted,
                        ),
                        controller: _controller.fullNameController,
                        keyboardType: TextInputType.name,
                        textInputAction: TextInputAction.next,
                        validator: _controller.validateFullName,
                      ),
                      const SizedBox(height: 18),

                      OfficerIdLockedField(
                        officerId: _controller.profile.officerId,
                      ),
                      const SizedBox(height: 22),

                      Text(
                        AppStrings.operationalRoleTitle,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      ..._controller.availableRoles.map((role) {
                        final isSelected = _controller.selectedRole == role;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: RoleSelectionCard(
                            role: role,
                            isSelected: isSelected,
                            onSelect: () => _controller.selectRole(role),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: const Border(
                    top: BorderSide(
                      color: Color(0xFFE8ECE5),
                      width: 1.0,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(
                  AppDimensions.screenHorizontalPadding,
                  12,
                  AppDimensions.screenHorizontalPadding,
                  14 + bottomSafeArea,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppButton(
                      text: AppStrings.btnSaveProfile,
                      backgroundColor: AppColors.buttonAuth,
                      height: 52,
                      borderRadius: 14,
                      isLoading: _controller.isLoading,
                      trailingIcon: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: _handleSaveProfile,
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _handleSkip,
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          AppStrings.btnSkipProfile,
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
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
    );
  }
}
