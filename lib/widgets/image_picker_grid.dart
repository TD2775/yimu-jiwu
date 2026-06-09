import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';

/// 图片选择网格
class ImagePickerGrid extends StatelessWidget {
  final List<String> imagePaths;
  final ValueChanged<List<String>> onChanged;
  final int maxImages;

  const ImagePickerGrid({
    super.key,
    required this.imagePaths,
    required this.onChanged,
    this.maxImages = 9,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...imagePaths.asMap().entries.map((entry) => _imageTile(entry.key, entry.value)),
        if (imagePaths.length < maxImages) _addButton(context),
      ],
    );
  }

  Widget _imageTile(int index, String path) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            path,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // path might be a regular file path
              return Image.file(
                File(path),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: AppColors.bgSecondary,
                  child: const Icon(Icons.broken_image, color: AppColors.textHint),
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              final paths = List<String>.from(imagePaths);
              paths.removeAt(index);
              onChanged(paths);
            },
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _pickImage(context),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.bgSecondary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider, width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, color: AppColors.textSecondary, size: 24),
            const SizedBox(height: 4),
            Text(
              '${imagePaths.length}/$maxImages',
              style: TextStyle(fontSize: 11, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final paths = List<String>.from(imagePaths);
      paths.add(picked.path);
      onChanged(paths);
    }
  }
}
