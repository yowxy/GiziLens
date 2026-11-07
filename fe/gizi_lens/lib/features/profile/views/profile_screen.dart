import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/route_names.dart';
import '../../dashboard/views/widgets/gizi_lens_bottom_nav.dart';
import '../controllers/profile_controller.dart';
import 'dialogs/logout_confirmation_dialog.dart';
import 'dialogs/profile_updated_success_dialog.dart';
import 'dialogs/save_profile_confirmation_dialog.dart';
import 'widgets/officer_info_hero_card.dart';
import 'widgets/profile_header_app_bar.dart';
import 'widgets/profile_menu_item.dart';
import 'widgets/profile_menu_section.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ProfileController();
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

  void _handleNotificationTap() {
    _controller.dismissNotificationBadge();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Semua notifikasi audit operasional SPPG telah diperiksa.',
          style: AppTypography.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primaryDeep,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleEditProfileTap() {
    final textController = TextEditingController(text: _controller.account.fullName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom + 24,
          ),
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
                'Edit Data Petugas SPPG',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Perbarui nama lengkap dan gelar resmi auditor baki MBG.',
                style: AppTypography.bodySmall.copyWith(
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: textController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: AppStrings.fullNameFieldLabel,
                  labelStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAF7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2ECE0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: AppColors.primaryDeep,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(bottomSheetContext).pop();
                    _triggerSaveProfileWorkflow(textController.text.trim());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDeep,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Simpan Profil',
                    style: AppTypography.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _triggerSaveProfileWorkflow([String? updatedName]) {
    SaveProfileConfirmationDialog.show(
      context,
      onConfirmSave: () {
        if (updatedName != null && updatedName.isNotEmpty) {
          _controller.updateProfileName(updatedName);
        }
        Future.delayed(const Duration(milliseconds: 150), () {
          if (!mounted) return;
          ProfileUpdatedSuccessDialog.show(context);
        });
      },
    );
  }

  void _handleLogoutTap() {
    LogoutConfirmationDialog.show(
      context,
      onConfirmLogout: () {
        try {
          context.go(RouteNames.login);
        } catch (_) {}
      },
    );
  }

  void _showAkgReferenceInfo() {
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
              AppStrings.menuAkgTitle,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Standar kepatuhan gizi baki MBG mengacu pada Peraturan Menteri Kesehatan RI No. 28 Tahun 2019 tentang Angka Kecukupan Gizi dan Petunjuk Teknis Program Makan Bergizi Gratis 2024 Badan Gizi Nasional (BGN).',
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
                child: const Text('Tutup', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
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
                  AppStrings.menuNotificationTitle,
                  style: AppTypography.titleLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeTrackColor: AppColors.primaryDeep,
                  title: const Text('Notifikasi Defisit Porsi >15%'),
                  subtitle: const Text('Peringatan instan saat ompreng tidak sesuai AKG'),
                  value: _controller.notificationsEnabled,
                  onChanged: (val) {
                    setModalState(() {});
                    _controller.toggleNotifications(val);
                  },
                ),
                const SizedBox(height: 16),
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
                    child: const Text('Simpan Pengaturan', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showSopSampling() {
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
              AppStrings.menuSopTitle,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'SOP Inspeksi Sampling: Ambil 5-10 baki saji acak per batch distribusi. Posisikan kamera tegak lurus (90 derajat) terhadap nampan ompreng pada jarak 30-40 cm untuk memastikan AI dapat mengukur luas permukaan kompartemen makanan secara akurat.',
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

  void _showHelpdeskInfo() {
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
              AppStrings.menuHelpdeskTitle,
              style: AppTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Pusat Bantuan SPPG BGN Wilayah Jawa Barat II:\nTelepon / WhatsApp: +62 811-2345-6789\nEmail: helpdesk.sppg@bgn.go.id\nJam Operasional: Senin - Sabtu 06:00 - 18:00 WIB',
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
                child: const Text('Tutup', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleBottomNavTap(int index) {
    if (index == 3) return;

    if (index == 0) {
      try {
        context.go(RouteNames.dashboard);
      } catch (_) {}
    } else if (index == 1) {
      try {
        context.go(RouteNames.menuInspection);
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Membuka kamera pemindai porsi ompreng...'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (index == 2) {
      try {
        context.go(RouteNames.history);
      } catch (_) {}
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
        body: Column(
          children: [
            ProfileHeaderAppBar(
              hasNotification: _controller.account.hasNotification,
              onNotificationTap: _handleNotificationTap,
            ),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OfficerInfoHeroCard(
                      account: _controller.account,
                      onEditProfileTap: _handleEditProfileTap,
                    ),
                    const SizedBox(height: 20),
                    ProfileMenuSection(
                      headerIcon: Icons.tune_rounded,
                      headerIconColor: AppColors.dialogAccentRing,
                      title: AppStrings.sectionPreferenceTitle,
                      trailingText: AppStrings.badgeKemenkesBgn,
                      items: [
                        ProfileMenuItem(
                          icon: Icons.menu_book_outlined,
                          title: AppStrings.menuAkgTitle,
                          subtitle: AppStrings.menuAkgSubtitle,
                          onTap: _showAkgReferenceInfo,
                        ),
                        ProfileMenuItem(
                          icon: Icons.notifications_active_outlined,
                          title: AppStrings.menuNotificationTitle,
                          subtitle: AppStrings.menuNotificationSubtitle,
                          onTap: _showNotificationSettings,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ProfileMenuSection(
                      headerIcon: Icons.verified_user_outlined,
                      headerIconColor: AppColors.primaryDeep,
                      title: AppStrings.sectionHelpTitle,
                      items: [
                        ProfileMenuItem(
                          icon: Icons.assignment_outlined,
                          title: AppStrings.menuSopTitle,
                          subtitle: AppStrings.menuSopSubtitle,
                          onTap: _showSopSampling,
                        ),
                        ProfileMenuItem(
                          icon: Icons.support_agent_rounded,
                          title: AppStrings.menuHelpdeskTitle,
                          subtitle: AppStrings.menuHelpdeskSubtitle,
                          onTap: _showHelpdeskInfo,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildLogoutCard(),
                    const SizedBox(height: 18),
                    _buildDialogDemoToolbar(),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: GiziLensBottomNav(
          currentIndex: 3,
          onTap: _handleBottomNavTap,
        ),
      ),
    );
  }

  Widget _buildLogoutCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF1D5D5),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleLogoutTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.dialogLogoutRed.withValues(alpha: 0.08),
          highlightColor: Colors.transparent,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.logout_rounded,
                      size: 22,
                      color: AppColors.dialogLogoutRed,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.btnLogoutAccount,
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dialogLogoutRed,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Keluar dari sesi auditor saat ini dengan aman',
                        style: AppTypography.bodySmall.copyWith(
                          fontSize: 11.5,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: Color(0xFFE2A6A6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDialogDemoToolbar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5EE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE0E7DC),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.widgets_outlined,
                size: 16,
                color: AppColors.primaryDeep,
              ),
              const SizedBox(width: 6),
              Text(
                'Pratinjau Cepat Box Dialog Modal',
                style: AppTypography.captionBold.copyWith(
                  fontSize: 11.5,
                  color: AppColors.primaryDeep,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSmallActionButton(
                  label: '1. Keluar Akun',
                  onTap: _handleLogoutTap,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildSmallActionButton(
                  label: '2. Simpan Profil',
                  onTap: () => SaveProfileConfirmationDialog.show(context),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _buildSmallActionButton(
                  label: '3. Sukses Simpan',
                  onTap: () => ProfileUpdatedSuccessDialog.show(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSmallActionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppColors.primaryDeep,
          side: const BorderSide(color: Color(0xFFCBD6C9)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDeep,
          ),
        ),
      ),
    );
  }
}
