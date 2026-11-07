import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/View/Components/product_image.dart';

/// Square photo box for one variant. Shows a newly picked [file], else the
/// saved [url]; tapping it asks for camera / gallery and calls [onPick].
class VariantPhotoBox extends StatelessWidget {
  const VariantPhotoBox({
    super.key,
    required this.onPick,
    this.file,
    this.url,
    this.size = 84,
  });

  final File? file;
  final String? url;
  final double size;
  final ValueChanged<ImageSource> onPick;

  bool get _hasPhoto => file != null || (url != null && url!.trim().isNotEmpty);

  void _chooseSource() {
    final context = Get.context;
    if (context == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: AppColors.brand700),
              title: Text('action_take_photo'.tr),
              onTap: () {
                Get.back();
                onPick(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: AppColors.brand700),
              title: Text('action_choose_from_gallery'.tr),
              onTap: () {
                Get.back();
                onPick(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (file != null) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(file!, width: size, height: size, fit: BoxFit.cover),
      );
    } else if (_hasPhoto) {
      content = ProductImage(url: url, size: size, radius: 16);
    } else {
      content = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.brand700.withAlpha(60)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 22, color: AppColors.brand700),
            const SizedBox(height: 4),
            Text(
              'add_photo'.tr,
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.brand700),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _chooseSource,
      child: Stack(
        children: [
          content,
          if (_hasPhoto)
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.edit_rounded, size: 12, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
