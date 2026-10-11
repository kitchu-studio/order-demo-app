import 'package:flutter/material.dart';

import 'config.dart';
import 'theme.dart';

/// Square photo of a menu item. Falls back to a dashed empty frame so a
/// menu without photos still reads as intentional.
class ProductPhoto extends StatelessWidget {
  const ProductPhoto({
    super.key,
    required this.url,
    this.size = 56,
    this.soldOut = false,
  });

  final String url;
  final double size;
  final bool soldOut;

  @override
  Widget build(BuildContext context) {
    final empty = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        border: Border.all(color: Palette.rule),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Icon(Icons.local_cafe_outlined,
          size: size * 0.4, color: Palette.rule),
    );
    if (url.isEmpty) return empty;

    Widget img = ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Image.network(
        '${AppConfig.apiBaseUrl}$url',
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * 3).round(),
        errorBuilder: (_, __, ___) => empty,
        loadingBuilder: (_, child, p) => p == null ? child : empty,
      ),
    );
    if (soldOut) {
      img = Opacity(
        opacity: 0.4,
        child: ColorFiltered(
          colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
          child: img,
        ),
      );
    }
    return img;
  }
}
