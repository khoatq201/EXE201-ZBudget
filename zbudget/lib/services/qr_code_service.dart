import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../models/settings/user_profile.dart';

/// Service để tạo và xử lý QR Code
class QRCodeService {
  /// Tạo QR Code data cho profile
  static String generateProfileQRData(UserProfile profile) {
    final qrData = {
      'type': 'zbudget_profile',
      'version': '1.0',
      'userId': profile.id,
      'name': profile.name,
      'level': profile.stats.currentLevel,
      'levelTitle': profile.levelTitle,
      'points': profile.stats.totalPoints,
      'achievements': profile.achievements.where((a) => a.isUnlocked).length,
      'totalAchievements': profile.achievements.length,
      'streak': profile.stats.streakDays,
      'activeDays': profile.stats.activeDays,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    return jsonEncode(qrData);
  }

  /// Hiển thị QR Code trong dialog
  static void showQRCodeDialog(BuildContext context, UserProfile profile) {
    final qrData = generateProfileQRData(profile);

    showDialog(
      context: context,
      builder: (context) => QRCodeDialog(profile: profile, qrData: qrData),
    );
  }

  /// Parse QR Code data (cho tương lai khi scan QR)
  static Map<String, dynamic>? parseQRData(String qrCode) {
    try {
      final data = jsonDecode(qrCode);
      if (data['type'] == 'zbudget_profile') {
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

/// Widget hiển thị QR Code Dialog
class QRCodeDialog extends StatefulWidget {
  final UserProfile profile;
  final String qrData;

  const QRCodeDialog({super.key, required this.profile, required this.qrData});

  @override
  State<QRCodeDialog> createState() => _QRCodeDialogState();
}

class _QRCodeDialogState extends State<QRCodeDialog> {
  final GlobalKey _qrKey = GlobalKey();
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.qr_code_2, color: Colors.white, size: 32),
                  const SizedBox(height: 8),
                  Text(
                    'QR Code Profile',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.profile.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),

            // QR Code
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  RepaintBoundary(
                    key: _qrKey,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: QrImageView(
                        data: widget.qrData,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        embeddedImage: const AssetImage(
                          'assets/images/app_icon.png',
                        ),
                        embeddedImageStyle: const QrEmbeddedImageStyle(
                          size: Size(40, 40),
                        ),
                        errorCorrectionLevel: QrErrorCorrectLevel.M,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Profile info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.star,
                              color: widget.profile.levelColor,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Level ${widget.profile.stats.currentLevel} • ${widget.profile.stats.totalPoints} điểm',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '🔥 ${widget.profile.stats.streakDays} ngày • 🏆 ${widget.profile.achievements.where((a) => a.isUnlocked).length} thành tích',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withValues(alpha: 0.7),
                              ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'Quét mã QR để xem thông tin profile',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSharing ? null : _shareQRCode,
                      icon: _isSharing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.share),
                      label: Text(_isSharing ? 'Đang chia sẻ...' : 'Chia sẻ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Đóng'),
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

  Future<void> _shareQRCode() async {
    if (_isSharing) return;

    setState(() {
      _isSharing = true;
    });

    try {
      // Capture QR code as image
      final boundary =
          _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary != null) {
        final image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final uint8List = byteData!.buffer.asUint8List();

        // Share image with text
        await Share.shareXFiles(
          [
            XFile.fromData(
              uint8List,
              name:
                  'zbudget_profile_qr_${widget.profile.name.replaceAll(' ', '_')}.png',
              mimeType: 'image/png',
            ),
          ],
          text:
              'QR Code Profile của ${widget.profile.name} trên ZBudget\n'
              'Level ${widget.profile.stats.currentLevel} • ${widget.profile.stats.totalPoints} điểm\n'
              'Quét mã để xem thông tin chi tiết!',
          subject: 'ZBudget QR Profile - ${widget.profile.name}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi chia sẻ QR Code: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isSharing = false;
      });
    }
  }
}
