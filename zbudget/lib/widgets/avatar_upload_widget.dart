import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/profile_service.dart';

class AvatarUploadWidget extends StatefulWidget {
  final double size;
  final bool showUploadButton;
  final bool showDeleteButton;

  const AvatarUploadWidget({
    Key? key,
    this.size = 120,
    this.showUploadButton = true,
    this.showDeleteButton = true,
  }) : super(key: key);

  @override
  State<AvatarUploadWidget> createState() => _AvatarUploadWidgetState();
}

class _AvatarUploadWidgetState extends State<AvatarUploadWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ProfileService>(
      builder: (context, profileService, child) {
        final profile = profileService.currentProfile;
        final isLoading = profileService.isLoading;
        final avatarUrl = profile?.avatar;

        return Column(
          children: [
            // Avatar display
            Stack(
              children: [
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ClipOval(
                          child: avatarUrl != null && avatarUrl.isNotEmpty
                              ? Image.network(
                                  avatarUrl,
                                  width: widget.size,
                                  height: widget.size,
                                  fit: BoxFit.cover,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                          ),
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: widget.size,
                                      height: widget.size,
                                      color: Colors.grey.shade200,
                                      child: Icon(
                                        Icons.person,
                                        size: widget.size * 0.5,
                                        color: Colors.grey.shade500,
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  width: widget.size,
                                  height: widget.size,
                                  color: Colors.grey.shade200,
                                  child: Icon(
                                    Icons.person,
                                    size: widget.size * 0.5,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                        ),
                ),

                // Upload button overlay
                if (widget.showUploadButton)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: IconButton(
                        onPressed: isLoading
                            ? null
                            : () => _showUploadOptions(context),
                        icon: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            if (widget.showDeleteButton && avatarUrl != null) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: isLoading ? null : () => _deleteAvatar(context),
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text(
                  'Xóa ảnh',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],

            // Error message
            if (profileService.errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                profileService.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      },
    );
  }

  void _showUploadOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadAvatar(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Hủy'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadAvatar(BuildContext context) async {
    final profileService = Provider.of<ProfileService>(context, listen: false);

    try {
      await profileService.pickAndUploadAvatar();

      if (mounted && profileService.errorMessage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tải ảnh đại diện thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi tải ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteAvatar(BuildContext context) async {
    final profileService = Provider.of<ProfileService>(context, listen: false);

    // Confirm deletion
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xóa ảnh đại diện'),
          content: const Text('Bạn có chắc chắn muốn xóa ảnh đại diện không?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      try {
        final success = await profileService.deleteAvatar();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                success
                    ? '✅ Xóa ảnh đại diện thành công!'
                    : '❌ Không thể xóa ảnh đại diện',
              ),
              backgroundColor: success ? Colors.green : Colors.red,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Lỗi xóa ảnh: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
