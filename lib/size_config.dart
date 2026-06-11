import 'package:flutter/widgets.dart';

class SizeConfig {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double devicePixelRatio;

  // Base design dimensions (standard mobile layout as reference: 375x812)
  static const double baseWidth = 375.0;
  static const double baseHeight = 812.0;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    devicePixelRatio = _mediaQueryData.devicePixelRatio;
  }

  // Scaling factors with bounds for desktop/tablet/mobile consistency
  static double get scaleFactor {
    double factor = screenWidth / baseWidth;
    if (factor > 1.6) return 1.6; // Cap maximum scale factor
    if (factor < 0.7) return 0.7; // Cap minimum scale factor
    return factor;
  }

  static double get scaleFactorHeight {
    double factor = screenHeight / baseHeight;
    if (factor > 1.6) return 1.6;
    if (factor < 0.7) return 0.7;
    return factor;
  }

  // Scaled dimensions
  static double scaleW(double size) => size * scaleFactor;
  static double scaleH(double size) => size * scaleFactorHeight;
  static double scaleSp(double size) => size * scaleFactor;
}

extension SizeConfigExtension on num {
  /// Scaled width representation
  double get w => SizeConfig.scaleW(toDouble());

  /// Scaled height representation
  double get h => SizeConfig.scaleH(toDouble());

  /// Scaled text/spacing representation
  double get sp => SizeConfig.scaleSp(toDouble());
}
