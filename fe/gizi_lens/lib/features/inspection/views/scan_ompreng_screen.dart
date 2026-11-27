import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routing/route_names.dart';
import '../../../../core/services/frame_quality_analyzer.dart';
import '../controllers/scan_ompreng_controller.dart';
import 'widgets/google_lens_hologram_scanner.dart';
import 'widgets/scan_validation_card.dart';
import 'widgets/step_progress_app_bar.dart';

class ScanOmprengScreen extends StatefulWidget {
  const ScanOmprengScreen({super.key});

  /// Computes an unconstrained preview [Size] matching `CameraPreview`'s exact
  /// aspect ratio so `FittedBox(fit: BoxFit.cover)` never squishes or stretches
  /// the camera texture inside the 1:1 viewfinder.
  static Size computeCameraPreviewBoxSize(
    Size? previewSize,
    DeviceOrientation orientation,
  ) {
    final ratio = (previewSize != null &&
            previewSize.width > 0 &&
            previewSize.height > 0)
        ? previewSize.width / previewSize.height
        : 4 / 3;
    final isLandscape = orientation == DeviceOrientation.landscapeLeft ||
        orientation == DeviceOrientation.landscapeRight;
    final displayAspect = isLandscape ? ratio : (1 / ratio);
    const baseHeight = 1000.0;
    return Size(baseHeight * displayAspect, baseHeight);
  }

  @override
  State<ScanOmprengScreen> createState() => _ScanOmprengScreenState();
}

class _ScanOmprengScreenState extends State<ScanOmprengScreen> {
  late final ScanOmprengController _controller;
  CameraController? _cameraController;
  late Future<void> _initialization;
  bool _isCapturing = false;
  double _currentZoom = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;
  double _zoomAtGestureStart = 1.0;
  static const double _defaultRectilinearZoom = 1.4;
  DateTime _lastFrameAnalysis = DateTime.fromMillisecondsSinceEpoch(0);
  static const _frameAnalysisInterval = Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();
    _controller = ScanOmprengController();
    _controller.addListener(_onControllerUpdate);
    _initialization = _initializeCamera();
    unawaited(_initializeModel());
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      throw StateError('Kamera tidak ditemukan pada perangkat ini.');
    }
    final cameraDescription = _pickBackCamera(cameras);
    final camera = CameraController(
      cameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    // Assign before initialization so dispose() can always clean up.
    _cameraController = camera;
    await camera.initialize();
    if (!mounted) return;
    try {
      await camera.lockCaptureOrientation(DeviceOrientation.portraitUp);
    } catch (_) {}
    var deviceMinZoom = 1.0;
    try {
      deviceMinZoom = await camera.getMinZoomLevel();
    } catch (_) {}
    try {
      _maxZoom = await camera.getMaxZoomLevel();
    } catch (_) {
      _maxZoom = 1.0;
    }
    // Never drop below 1.0x so multi-cam devices stay off the ultra-wide lens.
    _minZoom = math.max(1.0, deviceMinZoom);
    if (_maxZoom < _minZoom) _maxZoom = _minZoom;
    final initialZoom =
        _defaultRectilinearZoom.clamp(_minZoom, _maxZoom).toDouble();
    _currentZoom = initialZoom;
    try {
      await camera.setZoomLevel(initialZoom);
    } catch (_) {
      _currentZoom = _minZoom;
    }
    if (mounted) setState(() {});
    await camera.startImageStream(_onCameraFrame);
  }

  /// Picks the primary back camera. The main `wide` lens is preferred because
  /// ultra-wide lenses introduce the strong barrel distortion ("cembung") that
  /// makes a flat ompreng tray look bowed at close range.
  CameraDescription _pickBackCamera(List<CameraDescription> cameras) {
    final back = cameras
        .where((camera) => camera.lensDirection == CameraLensDirection.back)
        .toList();
    final pool = back.isNotEmpty ? back : cameras;
    const preference = <CameraLensType>[
      CameraLensType.wide,
      CameraLensType.unknown,
      CameraLensType.telephoto,
    ];
    for (final type in preference) {
      for (final camera in pool) {
        if (camera.lensType == type) return camera;
      }
    }
    return pool.first;
  }

  void _handleScaleStart(ScaleStartDetails details) {
    _zoomAtGestureStart = _currentZoom;
  }

  Future<void> _handleScaleUpdate(ScaleUpdateDetails details) async {
    final camera = _cameraController;
    if (camera == null || !camera.value.isInitialized) return;
    final next = (_zoomAtGestureStart * details.scale)
        .clamp(_minZoom, _maxZoom)
        .toDouble();
    if ((next - _currentZoom).abs() < 0.02) return;
    setState(() => _currentZoom = next);
    try {
      await camera.setZoomLevel(next);
    } catch (_) {}
  }

  Future<void> _cycleZoomPreset() async {
    final camera = _cameraController;
    if (camera == null || !camera.value.isInitialized) return;
    final presets = <double>{
      _minZoom,
      _defaultRectilinearZoom.clamp(_minZoom, _maxZoom).toDouble(),
      2.0.clamp(_minZoom, _maxZoom).toDouble(),
    }.toList()..sort();
    if (presets.isEmpty) return;

    var next = presets.first;
    for (final preset in presets) {
      if (preset > _currentZoom + 0.05) {
        next = preset;
        break;
      }
    }
    setState(() => _currentZoom = next);
    try {
      await camera.setZoomLevel(next);
    } catch (_) {}
  }

  void _onCameraFrame(CameraImage image) {
    final now = DateTime.now();
    if (now.difference(_lastFrameAnalysis) < _frameAnalysisInterval) return;
    _lastFrameAnalysis = now;
    final plane = image.planes.first;
    final quality = analyzeLuminanceFrame(
      plane.bytes,
      width: image.width,
      height: image.height,
      bytesPerRow: plane.bytesPerRow,
    );
    _controller.setValidationStates(
      lighting: quality.lighting,
      wholeTray: quality.wholeTray,
      focused: quality.focused,
      withinFrame: quality.withinFrame,
    );
  }

  Future<void> _initializeModel() async {
    try {
      await _initialization;
      await _controller.initializeModel();
    } catch (_) {}
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleShutterTap() async {
    if (_isCapturing || _controller.isAnalyzing) return;
    setState(() => _isCapturing = true);
    CameraController? camera;
    try {
      try {
        await _initialization;
      } catch (_) {
        return;
      }

      camera = _cameraController;
      if (camera == null || !camera.value.isInitialized) return;
      if (camera.value.isStreamingImages) {
        await camera.stopImageStream();
      }
      final photo = await camera.takePicture();
      final success = await _controller.capturePhoto(photo);
      if (success && mounted) {
        try {
          context.push(RouteNames.componentDetection);
        } catch (_) {
          context.go(RouteNames.componentDetection);
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil foto: $error'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFB3261E),
          ),
        );
      }
    } finally {
      // Restart the live stream so the preview stays live when the user comes
      // back (e.g. "retake photo"). Guard against a disposed controller.
      if (mounted &&
          camera != null &&
          camera.value.isInitialized &&
          !camera.value.isStreamingImages) {
        try {
          await camera.startImageStream(_onCameraFrame);
        } catch (_) {}
      }
      if (mounted) {
        setState(() => _isCapturing = false);
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
              'Posisikan kamera smartphone tepat di atas nampan makan saji (tegak lurus 90 derajat). Jaga jarak sekitar 30–40 cm dari baki, lalu cubit layar (pinch) untuk memperbesar gambar hingga baki memenuhi bingkai. Menjaga jarak ini penting agar lensa wide tidak membuat tepi baki terlihat melengkung (cembung). Pastikan seluruh 5 sekat ompreng masuk ke dalam bingkai panduan emas dan pencahayaan ruangan cukup terang agar AI dapat mendeteksi gramatur porsi secara akurat.',
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
                child: const Text(
                  'Mengerti',
                  style: TextStyle(color: Colors.white),
                ),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
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
                          isScanning: _controller.isModelReady && !_isCapturing,
                          showBoundingBoxes: _controller.showAiBoundingBoxes,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onScaleStart: _handleScaleStart,
                                  onScaleUpdate: _handleScaleUpdate,
                                  child: FutureBuilder<void>(
                                    future: _initialization,
                                    builder: (context, snapshot) {
                                      if (snapshot.hasError) {
                                        return _buildCameraStatus(
                                          snapshot.error.toString(),
                                          isError: true,
                                        );
                                      }
                                      final camera = _cameraController;
                                      if (snapshot.connectionState !=
                                              ConnectionState.done ||
                                          camera == null ||
                                          !camera.value.isInitialized) {
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                          ),
                                        );
                                      }
                                      return _buildCameraPreview(camera);
                                    },
                                  ),
                                ),
                              ),
                              if (_maxZoom > _minZoom + 0.05 || _currentZoom > 1.01)
                                Positioned(
                                  top: 12,
                                  right: 12,
                                  child: _buildZoomBadge(),
                                ),
                              if (_isCapturing || _controller.isAnalyzing)
                                Positioned(
                                  left: 12,
                                  right: 12,
                                  bottom: 12,
                                  child: _buildStatusBanner(
                                    _controller.isAnalyzing
                                        ? 'Menganalisis gambar...'
                                        : 'Mengambil foto...',
                                  ),
                                ),
                              if (_controller.errorMessage != null &&
                                  !_isCapturing &&
                                  !_controller.isAnalyzing)
                                Positioned(
                                  left: 12,
                                  right: 12,
                                  bottom: 12,
                                  child: _buildStatusBanner(
                                    _controller.errorMessage!,
                                    isError: true,
                                    onRetry: _handleShutterTap,
                                  ),
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
                            content: Text(
                              'Pilih citra ompreng baki dari galeri...',
                            ),
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
      onTap: _isCapturing || _controller.isAnalyzing ? null : _handleShutterTap,
      child: Container(
        width: 74,
        height: 74,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFD6A64B), width: 3.5),
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1B4E41),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: _isCapturing || _controller.isAnalyzing
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

  /// Renders the live camera feed with uniform cover scaling so the image is
  /// never squished or stretched into 1:1 ("cembung"). `FittedBox` gives
  /// `CameraPreview` unconstrained dimensions matching its native ratio, and
  /// `ClipRect` crops any overflow cleanly.
  Widget _buildCameraPreview(CameraController camera) {
    final boxSize = ScanOmprengScreen.computeCameraPreviewBoxSize(
      camera.value.previewSize,
      camera.value.deviceOrientation,
    );

    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: boxSize.width,
          height: boxSize.height,
          child: CameraPreview(camera),
        ),
      ),
    );
  }

  Widget _buildZoomBadge() {
    return GestureDetector(
      onTap: _cycleZoomPreset,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0xFFD6A64B), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.zoom_in_rounded,
              size: 14,
              color: Color(0xFFD6A64B),
            ),
            const SizedBox(width: 4),
            Text(
              '${_currentZoom.toStringAsFixed(1)}x',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner(
    String message, {
    bool isError = false,
    VoidCallback? onRetry,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isError ? const Color(0xFFE57373) : const Color(0xFFD6A64B),
        ),
      ),
      child: Row(
        children: [
          if (isError)
            const Icon(
              Icons.error_outline,
              color: Color(0xFFE57373),
              size: 18,
            )
          else
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: Color(0xFFD6A64B),
                strokeWidth: 2,
              ),
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Coba lagi',
                style: TextStyle(
                  color: Color(0xFFD6A64B),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCameraStatus(String message, {bool isError = false}) {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.78),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isError ? const Color(0xFFE57373) : const Color(0xFFD6A64B),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isError)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Color(0xFFD6A64B),
                  strokeWidth: 2,
                ),
              )
            else
              const Icon(Icons.error_outline, color: Color(0xFFE57373)),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
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
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}
