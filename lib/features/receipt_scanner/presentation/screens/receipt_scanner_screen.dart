import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../app/app_providers.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/app_haptics.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/presentation/widgets/add_transaction_sheet.dart';
import 'receipt_review_screen.dart';

/// Layar Kamera Pindai Struk (OCR) — MyFinance Minimal (Quiet, Clean, Premium).
///
/// Karakter Desain:
/// - Antarmuka kamera bersih & hening (Clean Camera Interface).
/// - Bingkai pindai minimalis (Apple Document Scanner style) dengan 4 sudut penanda.
/// - Kontrol kamera lengkap: Flash toggle, Gallery picker, Capture shutter, dan Input Manual.
/// - Pemrosesan 100% on-device dan privat tanpa cloud.
class ReceiptScannerScreen extends ConsumerStatefulWidget {
  const ReceiptScannerScreen({super.key});

  @override
  ConsumerState<ReceiptScannerScreen> createState() => _ReceiptScannerScreenState();
}

class _ReceiptScannerScreenState extends ConsumerState<ReceiptScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isFlashOn = false;
  bool _isProcessing = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty && mounted) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);
        }
      }
    } catch (e) {
      debugPrint('Kamera controller tidak dapat diinisialisasi (menggunakan fallback image_picker): $e');
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _toggleFlash() async {
    unawaited(AppHaptics.light());
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final newMode = _isFlashOn ? FlashMode.off : FlashMode.torch;
        await _cameraController!.setFlashMode(newMode);
        setState(() => _isFlashOn = !_isFlashOn);
      } catch (_) {
        setState(() => _isFlashOn = !_isFlashOn);
      }
    } else {
      setState(() => _isFlashOn = !_isFlashOn);
    }
  }

  Future<void> _capture() async {
    unawaited(AppHaptics.medium());
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        final photo = await _cameraController!.takePicture();
        final bytes = await photo.readAsBytes();
        await _processScan(photo.path, bytes);
        return;
      } catch (e) {
        debugPrint('Kendala mengambil foto dari camera controller: $e');
      }
    }

    // Fallback menggunakan ImagePicker kamera bawaan OS
    await _pickImage(ImageSource.camera);
  }

  Future<void> _pickImage(ImageSource source) async {
    unawaited(AppHaptics.light());
    try {
      final photo = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        await _processScan(photo.path, bytes);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tidak dapat membuka kamera/galeri: $e')),
        );
      }
    }
  }

  Future<void> _processScan(String imagePath, [Uint8List? imageBytes]) async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Menjalankan OCR On-Device...';
    });

    try {
      final draft = await ref.read(receiptScannerControllerProvider.notifier).scanImage(
            imagePath: imagePath,
            imageBytes: imageBytes,
          );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (draft != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (ctx) => ReceiptReviewScreen(draft: draft),
          ),
        );
      } else {
        if (!mounted) return;
        final manual = await MinimalDialog.showConfirm(
          context,
          title: 'Gagal Memindai Struk',
          message: 'Teks struk tidak dapat dikenali secara otomatis. Apakah Anda ingin beralih mencatat transaksi secara manual?',
          cancelText: 'Batal',
          confirmText: 'Input Manual',
        );
        if (manual == true && mounted) {
          Navigator.of(context).pop();
          unawaited(AddTransactionSheet.show(context, initialType: TransactionType.expense));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        final manual = await MinimalDialog.showConfirm(
          context,
          title: 'Pindai Struk Bermasalah',
          message: 'Terjadi kendala saat memindai: $e.\n\nApakah Anda ingin mencatat pengeluaran secara manual?',
          cancelText: 'Batal',
          confirmText: 'Input Manual',
        );
        if (manual == true && mounted) {
          Navigator.of(context).pop();
          unawaited(AddTransactionSheet.show(context, initialType: TransactionType.expense));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final frameWidth = (screenSize.width * 0.82).clamp(260.0, 360.0);
    final frameHeight = frameWidth * 1.35; // Proporsi struk belanja

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Live Camera Preview atau Fallback Background
          if (_isCameraInitialized && _cameraController != null)
            Center(
              child: CameraPreview(_cameraController!),
            )
          else
            Container(
              color: const Color(0xFF141414),
              child: Center(
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
            ),

          // 2. Translucent Dim Overlay di luar Scan Frame
          SafeArea(
            child: Column(
              children: [
                // Top Action Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      MinimalIconButton(
                        icon: Icons.close_rounded,
                        color: Colors.white,
                        tooltip: 'Tutup',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Text(
                        'Pindai Struk',
                        style: AppTypography.subhead.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      MinimalIconButton(
                        icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        color: _isFlashOn ? Colors.amber : Colors.white,
                        tooltip: 'Flash',
                        onPressed: _toggleFlash,
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Center Scan Frame
                _ScanFrame(width: frameWidth, height: frameHeight),

                const SizedBox(height: 20),

                // Hint Teks & Status Privasi
                Text(
                  'Posisikan struk belanja di dalam bingkai',
                  style: AppTypography.caption.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 13,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '100% On-Device & Privat',
                      style: AppTypography.caption2.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Bottom Control Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Galeri Picker Button
                      _buildCircleButton(
                        icon: Icons.photo_library_outlined,
                        tooltip: 'Pilih dari Galeri',
                        onTap: () => _pickImage(ImageSource.gallery),
                      ),

                      // Shutter Capture Button
                      GestureDetector(
                        onTap: _isProcessing ? null : _capture,
                        child: Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3.5),
                          ),
                          padding: const EdgeInsets.all(4.5),
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // Input Manual Button
                      _buildCircleButton(
                        icon: Icons.edit_note_outlined,
                        tooltip: 'Input Manual',
                        onTap: () {
                          unawaited(AppHaptics.light());
                          Navigator.of(context).pop();
                          AddTransactionSheet.show(context, initialType: TransactionType.expense);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Loading Overlay saat OCR sedang memproses
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.75),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _statusMessage,
                      style: AppTypography.subhead.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Memproses teks secara lokal pada perangkat Anda...',
                      style: AppTypography.caption.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 0.8,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

/// Bingkai pemindaian minimalis dengan 4 sudut penanda (Document Scanner Frame)
class _ScanFrame extends StatelessWidget {
  final double width;
  final double height;

  const _ScanFrame({
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Border garis tipis tembus pandang
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.35),
                width: 1.0,
              ),
            ),
          ),
          // 4 Sudut Penanda
          Positioned(
            top: 0,
            left: 0,
            child: _buildCorner(isTop: true, isLeft: true),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _buildCorner(isTop: true, isLeft: false),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: _buildCorner(isTop: false, isLeft: true),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: _buildCorner(isTop: false, isLeft: false),
          ),
        ],
      ),
    );
  }

  Widget _buildCorner({required bool isTop, required bool isLeft}) {
    const length = 22.0;
    const thickness = 3.0;
    const radius = Radius.circular(16);

    return Container(
      width: length,
      height: length,
      decoration: BoxDecoration(
        border: Border(
          top: isTop ? const BorderSide(color: Colors.white, width: thickness) : BorderSide.none,
          bottom: !isTop ? const BorderSide(color: Colors.white, width: thickness) : BorderSide.none,
          left: isLeft ? const BorderSide(color: Colors.white, width: thickness) : BorderSide.none,
          right: !isLeft ? const BorderSide(color: Colors.white, width: thickness) : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: isTop && isLeft ? radius : Radius.zero,
          topRight: isTop && !isLeft ? radius : Radius.zero,
          bottomLeft: !isTop && isLeft ? radius : Radius.zero,
          bottomRight: !isTop && !isLeft ? radius : Radius.zero,
        ),
      ),
    );
  }
}
