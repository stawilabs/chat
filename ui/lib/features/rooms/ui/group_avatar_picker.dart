import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/files/files_upload_service.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/theme/app_theme.dart';

/// A widget for picking and uploading group avatars
///
/// Displays the current avatar (or a placeholder with the group initial)
/// and allows the user to select a new image from camera or gallery.
/// Handles uploading to the server and returns the new URL.
class GroupAvatarPicker extends ConsumerStatefulWidget {
  const GroupAvatarPicker({
    required this.roomId,
    required this.groupName,
    required this.onAvatarChanged,
    this.currentAvatarUrl,
    this.size = 120,
    super.key,
  });

  final String roomId;
  final String? currentAvatarUrl;
  final String groupName;
  final void Function(String? newUrl) onAvatarChanged;
  final double size;

  @override
  ConsumerState<GroupAvatarPicker> createState() => _GroupAvatarPickerState();
}

class _GroupAvatarPickerState extends ConsumerState<GroupAvatarPicker> {
  bool _isUploading = false;
  double _uploadProgress = 0;
  String? _localImagePath;
  final ImagePicker _picker = ImagePicker();

  /// Builds a styled icon container for bottom sheet options
  Widget _buildIconContainer({required IconData icon, required Color color}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
    );
  }

  Future<void> _showPickerOptions() async {
    await showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: _buildIconContainer(
                icon: Icons.camera_alt,
                color: AppTheme.primaryGreen,
              ),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: _buildIconContainer(
                icon: Icons.photo_library,
                color: AppTheme.primaryGreen,
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (widget.currentAvatarUrl != null || _localImagePath != null)
              ListTile(
                leading: _buildIconContainer(
                  icon: Icons.delete,
                  color: Colors.red.shade600,
                ),
                title: Text(
                  'Remove Photo',
                  style: TextStyle(color: Colors.red.shade600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removePhoto();
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _localImagePath = pickedFile.path;
        _isUploading = true;
        _uploadProgress = 0;
      });

      // Upload the image
      final uploadService = ref.read(filesUploadServiceProvider);
      final result = await uploadService.uploadFile(
        File(pickedFile.path),
        mimeType: 'image/jpeg',
        onProgress: (progress) {
          if (mounted) {
            setState(() => _uploadProgress = progress);
          }
        },
      );

      widget.onAvatarChanged(result.contentUri);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Group photo updated')));
      }
    } catch (e, stackTrace) {
      AppLogger.error('Image picker error', error: e, stackTrace: stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0;
        });
      }
    }
  }

  void _removePhoto() {
    setState(() {
      _localImagePath = null;
    });
    widget.onAvatarChanged(null);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Group photo removed')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: _isUploading ? null : _showPickerOptions,
      child: Stack(
        children: [
          // Avatar container
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryGreen.withValues(alpha: 0.2),
              border: Border.all(
                color: AppTheme.primaryGreen.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: ClipOval(child: _buildAvatarContent(theme)),
          ),

          // Edit badge
          if (!_isUploading)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 3,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),

          // Upload progress overlay
          if (_isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          value: _uploadProgress > 0 ? _uploadProgress : null,
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                      if (_uploadProgress > 0) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${(_uploadProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatarContent(ThemeData theme) {
    // Show local image while uploading
    if (_localImagePath != null) {
      return Image.file(
        File(_localImagePath!),
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
      );
    }

    // Show network image if available
    if (widget.currentAvatarUrl != null) {
      return Image.network(
        widget.currentAvatarUrl!,
        fit: BoxFit.cover,
        width: widget.size,
        height: widget.size,
        errorBuilder: (_, _, _) => _buildPlaceholder(theme),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                  : null,
              color: AppTheme.primaryGreen,
              strokeWidth: 2,
            ),
          );
        },
      );
    }

    // Show placeholder with initial
    return _buildPlaceholder(theme);
  }

  Widget _buildPlaceholder(ThemeData theme) {
    final initial = widget.groupName.isNotEmpty
        ? widget.groupName[0].toUpperCase()
        : '?';

    return Container(
      width: widget.size,
      height: widget.size,
      color: AppTheme.primaryGreen.withValues(alpha: 0.2),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: widget.size * 0.4,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryGreen,
          ),
        ),
      ),
    );
  }
}
