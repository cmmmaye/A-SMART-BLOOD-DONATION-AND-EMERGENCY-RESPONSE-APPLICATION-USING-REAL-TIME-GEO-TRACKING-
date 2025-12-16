import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../common/assets.dart';
import '../utils/image_storage.dart';

/// Widget that displays a profile image, handling both local files and network URLs
class ProfileImage extends StatelessWidget {
  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;

  const ProfileImage({
    Key? key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildPlaceholder();
    }

    // Check if it's a local file or network URL
    if (ImageStorage.isLocalPath(imagePath)) {
      final file = ImageStorage.getLocalFile(imagePath!);
      if (file != null) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        );
      } else {
        return _buildPlaceholder();
      }
    } else {
      // Network image
      return CachedNetworkImage(
        imageUrl: imagePath!,
        width: width,
        height: height,
        fit: fit,
        placeholder: (_, __) => _buildPlaceholder(isLoading: true),
        errorWidget: (_, __, ___) => _buildPlaceholder(),
      );
    }
  }

  Widget _buildPlaceholder({bool isLoading = false}) {
    if (isLoading) {
      return SizedBox(
        width: width,
        height: height,
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white70,
            ),
          ),
        ),
      );
    }
    
    if (width != null && height != null) {
      return SizedBox(
        width: width,
        height: height,
        child: SvgPicture.asset(IconAssets.donor),
      );
    }
    
    return SvgPicture.asset(IconAssets.donor);
  }
}

