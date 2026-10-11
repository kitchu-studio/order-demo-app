import 'package:flutter/material.dart';

import '../../core/theme.dart';

/// "–  2  +" written in the margin style: handwritten number, bare glyph buttons, no boxes.
class QtyControl extends StatelessWidget {
  const QtyControl({
    super.key,
    required this.qty,
    required this.onAdd,
    required this.onRemove,
  });

  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    Widget glyph(IconData icon, String tooltip, VoidCallback onTap) {
      return IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        icon: Icon(icon, size: 22, color: Palette.pen),
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        glyph(Icons.remove, 'ลด', onRemove),
        SizedBox(
          width: 28,
          child: Text(
            '$qty',
            textAlign: TextAlign.center,
            style: figures(size: 22),
          ),
        ),
        glyph(Icons.add, 'เพิ่ม', onAdd),
      ],
    );
  }
}
