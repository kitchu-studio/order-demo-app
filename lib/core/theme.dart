import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// An order pad at a café counter: ruled paper, a red margin line, ballpoint-blue ink,
/// and a red rubber stamp. Blue is for what the customer writes (quantities, prices),
/// red is only ever the shop's own mark (margin, stamp).
class Palette {
  Palette._();

  static const paper = Color(0xFFFAFBFD);
  static const ink = Color(0xFF141B33); // printed text
  static const pen = Color(0xFF1F46B5); // ballpoint blue
  static const stamp = Color(0xFFD6342C); // margin line and rubber stamp
  static const steel = Color(0xFF6A7390);
  static const rule = Color(0xFFD3DCF0); // ruled lines
}

/// Digits of equal width, so prices line up in a column.
const tabularFigures = [FontFeature.tabularFigures()];

/// Kanit (clear, slightly condensed Thai) for quantities, prices and order numbers,
/// set in ballpoint blue so they read as what was filled in on the pad.
TextStyle figures({
  double size = 18,
  Color color = Palette.pen,
  FontWeight weight = FontWeight.w400,
}) =>
    GoogleFonts.kanit(fontSize: size, color: color, fontWeight: weight);

TextTheme buildTextTheme() {
  final body = GoogleFonts.sarabunTextTheme()
      .apply(bodyColor: Palette.ink, displayColor: Palette.ink);

  TextStyle bold(TextStyle? base, FontWeight weight) =>
      base?.copyWith(fontWeight: weight) ?? TextStyle(fontWeight: weight);

  return body.copyWith(
    headlineMedium: bold(body.headlineMedium, FontWeight.w700),
    headlineSmall: bold(body.headlineSmall, FontWeight.w700),
    titleLarge: bold(body.titleLarge, FontWeight.w700),
    titleMedium: bold(body.titleMedium, FontWeight.w600),
    titleSmall: bold(body.titleSmall, FontWeight.w600),
    labelLarge: bold(body.labelLarge, FontWeight.w600),
  );
}

ThemeData buildTheme() {
  final text = buildTextTheme();
  const scheme = ColorScheme.light(
    primary: Palette.pen,
    onPrimary: Colors.white,
    secondary: Palette.stamp,
    onSecondary: Colors.white,
    surface: Palette.paper,
    onSurface: Palette.ink,
    error: Palette.stamp,
    onError: Colors.white,
    outline: Palette.rule,
  );

  const underline = UnderlineInputBorder(
    borderSide: BorderSide(color: Palette.rule, width: 1.5),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: Palette.paper,
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: Palette.paper,
      foregroundColor: Palette.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: text.titleLarge,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: Palette.ink,
      unselectedLabelColor: Palette.steel,
      labelStyle: text.labelLarge,
      unselectedLabelStyle: text.labelLarge,
      indicatorColor: Palette.stamp,
      indicatorSize: TabBarIndicatorSize.tab,
      dividerColor: Palette.rule,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.pen,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Palette.rule,
        disabledForegroundColor: Palette.steel,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        textStyle: text.labelLarge?.copyWith(fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Palette.ink,
        side: const BorderSide(color: Palette.ink),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
        textStyle: text.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Palette.pen,
        textStyle: text.labelLarge,
      ),
    ),
    // Fields are a line on the page, not a white box.
    inputDecorationTheme: const InputDecorationTheme(
      filled: false,
      border: underline,
      enabledBorder: underline,
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Palette.pen, width: 2),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Palette.stamp, width: 1.5),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Palette.stamp, width: 2),
      ),
      labelStyle: TextStyle(color: Palette.steel),
    ),
    dividerTheme: const DividerThemeData(
      color: Palette.rule,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Palette.ink,
      contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
    ),
  );
}

/// The ruled-paper backdrop: horizontal lines are the row borders; this adds the red margin.
class MarginLine extends StatelessWidget {
  const MarginLine({super.key, required this.child, this.x = 52});

  final Widget child;
  final double x;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          left: x,
          top: 0,
          bottom: 0,
          child: IgnorePointer(
            child: Container(
              width: 1.5,
              color: Palette.stamp.withValues(alpha: 0.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dashed line, like the tear-off guide on a printed slip.
class DashedRule extends StatelessWidget {
  const DashedRule({super.key});

  @override
  Widget build(BuildContext context) =>
      const SizedBox(height: 1, child: CustomPaint(painter: _DashPainter()));
}

class _DashPainter extends CustomPainter {
  const _DashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Palette.steel.withValues(alpha: 0.6)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 8) {
      canvas.drawLine(Offset(x, 0), Offset(x + 4, 0), paint);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => false;
}

/// Zig-zag bottom edge, as if the slip was torn off the roll.
class TornEdgeClipper extends CustomClipper<Path> {
  static const _depth = 8.0;
  static const _tooth = 16.0;

  @override
  Path getClip(Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height - _depth);
    final n = (size.width / _tooth).round().clamp(1, 1000);
    final step = size.width / n;
    for (var i = 0; i < n; i++) {
      final right = size.width - step * i;
      path
        ..lineTo(right - step / 2, size.height)
        ..lineTo(right - step, size.height - _depth);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(TornEdgeClipper old) => false;
}
