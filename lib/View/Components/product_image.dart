import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:stock_management/Config/theme/app_theme.dart';
import 'package:stock_management/View/Components/product_image_viewer.dart';

/// A product photo loaded from the API (Cloudinary URL), cached on disk.
/// Falls back to the inventory icon while loading, on error, or when the
/// product has no image.
class ProductImage extends StatelessWidget {
  const ProductImage({
    super.key,
    required this.url,
    this.size = 46,
    this.radius = 14,
    this.iconSize,
    this.viewable = false,
    this.title,
  });

  /// When true (and there is a photo), tapping opens it full screen.
  final bool viewable;

  /// Shown at the top of the full-screen viewer.
  final String? title;

  final String? url;
  final double size;
  final double radius;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    final hasUrl = url != null && url!.trim().isNotEmpty;

    final tag = hasUrl ? 'product-image-${url!.trim()}' : null;

    Widget image = ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: size,
        height: size,
        child: hasUrl
            ? CachedNetworkImage(
                imageUrl: url!.trim(),
                width: size,
                height: size,
                fit: BoxFit.cover,
                fadeInDuration: const Duration(milliseconds: 150),
                placeholder: (_, _) => _fallback(),
                errorWidget: (_, _, _) => _fallback(),
              )
            : _fallback(),
      ),
    );

    if (!(viewable && hasUrl)) return image;

    return GestureDetector(
      onTap: () => showProductImageViewer(context, url: url!.trim(), title: title, heroTag: tag),
      child: Hero(tag: tag!, child: image),
    );
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      color: AppColors.brand50,
      alignment: Alignment.center,
      child: Icon(Icons.inventory_2_outlined, size: iconSize ?? size * 0.43, color: AppColors.brand700),
    );
  }
}
