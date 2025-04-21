import 'package:flutter/material.dart';

class ColorUtils {
  /// Performs a free (unrestricted) linear interpolation between two ranges
  ///
  /// Maps a value from the range [minVal, maxVal] to the range [minReturn, maxReturn]
  ///
  /// @param value The value to interpolate
  /// @param minVal The minimum value of the source range
  /// @param maxVal The maximum value of the source range
  /// @param minReturn The minimum value of the target range
  /// @param maxReturn The maximum value of the target range
  /// @return The interpolated value in the target range
  static double freeInterpolate(
    double value,
    double minVal,
    double maxVal,
    double minReturn,
    double maxReturn,
  ) {
    // Guard clause for value below minimum
    if (value <= minVal) {
      return minReturn;
    }

    // Guard clause for value above maximum
    if (value >= maxVal) {
      return maxReturn;
    }

    return minReturn +
        (value - minVal) * (maxReturn - minReturn) / (maxVal - minVal);
  }

  static Color adjustOpacity(Color color, double opacity) {
    double red = color.r / 255.0;
    double green = color.g / 255.0;
    double blue = color.b / 255.0;

    return Color.fromRGBO(
      freeInterpolate(red, 0, 1, 0, 255).toInt(),
      freeInterpolate(green, 0, 1, 0, 255).toInt(),
      freeInterpolate(blue, 0, 1, 0, 255).toInt(),
      opacity,
    );
  }
}
