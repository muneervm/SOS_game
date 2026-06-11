import 'package:flutter/widgets.dart';

class SizeConfig {
  static late MediaQueryData _mediaQueryData;
  static late double screenWidth;
  static late double screenHeight;
  static late double devicePixelRatio;

  static const double baseWidth = 375.0;
  static const double baseHeight = 812.0;

  static void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    devicePixelRatio = _mediaQueryData.devicePixelRatio;
  }

  static double get scaleFactor {
    double factor = screenWidth / baseWidth;
    if (factor > 1.6) return 1.6;
    if (factor < 0.7) return 0.7;
    return factor;
  }

  static double get scaleFactorHeight {
    double factor = screenHeight / baseHeight;
    if (factor > 1.6) return 1.6;
    if (factor < 0.7) return 0.7;
    return factor;
  }

  static double scaleW(double size) => size * scaleFactor;
  static double scaleH(double size) => size * scaleFactorHeight;
  static double scaleSp(double size) => size * scaleFactor;
}

extension SizeConfigExtension on num {
  double get w => SizeConfig.scaleW(toDouble());
  double get h => SizeConfig.scaleH(toDouble());
  double get sp => SizeConfig.scaleSp(toDouble());
}
