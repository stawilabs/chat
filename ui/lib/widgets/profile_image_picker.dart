import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/files/files_upload_service.dart';
import '../../core/logging/app_logger.dart';
import '../../core/theme/app_theme.dart';

enum ProfileImageSource { gallery, camera }

class PickedImage {
  const PickedImage({
    required this.bytes,
    required this.fileName,
    this.mimeType = 'image/jpeg',
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;
}

class ProfileImagePicker extends ConsumerStatefulWidget {
  const ProfileImagePicker({
    required this.onImagePicked,
    super.key,
    this.size = 144,
    this.currentImageUrl,
    this.enabled = true,
  });

  final void Function(PickedImage image) onImagePicked;
  final double size;
  final String? currentImageUrl;
  final bool enabled;

  @override
  ConsumerState<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends ConsumerState<ProfileImagePicker> {
  final _imagePicker = ImagePicker();
  PickedImage? _selectedImage;
  final bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? _showImageSourceDialog : null,
      child: Stack(
        children: [
          CircleAvatar(
            radius: widget.size / 2,
            backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
            backgroundImage: _getBackgroundImage(),
            child: _selectedImage == null && widget.currentImageUrl == null
                ? Icon(
                    Icons.person,
                    size: widget.size * 0.44,
                    color: AppTheme.primaryGreen.withValues(alpha: 0.5),
                  )
                : null,
          ),
          if (widget.enabled)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: widget.size * 0.28,
                height: widget.size * 0.28,
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: widget.size * 0.14,
                      ),
              ),
            ),
        ],
      ),
    );
  }

  ImageProvider? _getBackgroundImage() {
    if (_selectedImage != null) {
      return MemoryImage(_selectedImage!.bytes);
    }
    if (widget.currentImageUrl != null) {
      return NetworkImage(widget.currentImageUrl!);
    }
    return null;
  }

  void _showImageSourceDialog() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ProfileImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ProfileImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ProfileImageSource source) async {
    final imageSource = source == ProfileImageSource.gallery
        ? ImageSource.gallery
        : ImageSource.camera;

    try {
      final pickedFile = await _imagePicker.pickImage(
        source: imageSource,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      Uint8List imageBytes;

      if (kIsWeb) {
        imageBytes = await pickedFile.readAsBytes();
      } else {
        final croppedBytes = await _cropImage(pickedFile.path);
        if (croppedBytes == null) return;
        imageBytes = croppedBytes;
      }

      final fileName = pickedFile.name;

      setState(() {
        _selectedImage = PickedImage(bytes: imageBytes, fileName: fileName);
      });

      widget.onImagePicked(_selectedImage!);
    } catch (e) {
      AppLogger.warning('Failed to pick image', error: e);
    }
  }

  Future<Uint8List?> _cropImage(String path) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop photo',
          toolbarColor: AppTheme.primaryGreen,
          toolbarWidgetColor: Colors.white,
          hideBottomControls: true,
          lockAspectRatio: true,
          initAspectRatio: CropAspectRatioPreset.square,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
          ],
        ),
        IOSUiSettings(
          title: 'Crop photo',
          aspectRatioLockEnabled: true,
          aspectRatioPickerButtonHidden: true,
          resetAspectRatioEnabled: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
          ],
        ),
        WebUiSettings(context: context),
      ],
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
    );

    if (cropped == null) return null;

    return cropped.readAsBytes();
  }
}

class ProfileImageUploader extends ConsumerStatefulWidget {
  const ProfileImageUploader({
    required this.selectedImage,
    required this.currentImageUrl,
    super.key,
    this.size = 144,
    this.onUploadComplete,
    this.onUploadError,
  });

  final PickedImage? selectedImage;
  final String? currentImageUrl;
  final double size;
  final void Function(String avatarUrl)? onUploadComplete;
  final void Function(String error)? onUploadError;

  @override
  ConsumerState<ProfileImageUploader> createState() =>
      _ProfileImageUploaderState();
}

class _ProfileImageUploaderState extends ConsumerState<ProfileImageUploader> {
  bool _isUploading = false;

  @override
  void didUpdateWidget(ProfileImageUploader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedImage != null &&
        widget.selectedImage != oldWidget.selectedImage) {
      _uploadImage(widget.selectedImage!);
    }
  }

  Future<void> _uploadImage(PickedImage image) async {
    if (_isUploading) return;

    setState(() => _isUploading = true);

    try {
      final uploadService = ref.read(filesUploadServiceProvider);
      final result = await uploadService.uploadBytes(
        image.bytes,
        image.fileName,
        image.mimeType,
      );

      widget.onUploadComplete?.call(result.contentUri);
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to upload profile image',
        error: e,
        stackTrace: stackTrace,
      );
      widget.onUploadError?.call(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: widget.size / 2,
      backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
      backgroundImage: _getBackgroundImage(),
      child: widget.selectedImage != null && _isUploading
          ? const CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.primaryGreen,
            )
          : null,
    );
  }

  ImageProvider? _getBackgroundImage() {
    if (widget.selectedImage != null) {
      return MemoryImage(widget.selectedImage!.bytes);
    }
    if (widget.currentImageUrl != null) {
      return NetworkImage(widget.currentImageUrl!);
    }
    return null;
  }
}
