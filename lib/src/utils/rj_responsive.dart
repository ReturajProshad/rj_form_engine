import 'package:flutter/material.dart';

/// Responsive breakpoint thresholds.
class RjBreakpoints {
  static const double phone = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
}

/// Screen size category.
enum RjScreenSize { phone, tablet, desktop }

/// Utility for responsive sizing within the form engine.
class RjResponsive {
  /// Determine the current screen size category from available width.
  static RjScreenSize screenSize(double width) {
    if (width >= RjBreakpoints.desktop) return RjScreenSize.desktop;
    if (width >= RjBreakpoints.tablet) return RjScreenSize.tablet;
    return RjScreenSize.phone;
  }

  /// Responsive image tile size.
  static double imageTileSize(double width) {
    if (width >= RjBreakpoints.desktop) return 110;
    if (width >= RjBreakpoints.tablet) return 100;
    return 90;
  }

  /// Responsive spinner button size.
  static double spinnerButtonSize(double width) {
    if (width >= RjBreakpoints.desktop) return 56;
    if (width >= RjBreakpoints.tablet) return 54;
    return 52;
  }

  /// Responsive content padding.
  static EdgeInsets contentPadding(double width) {
    if (width >= RjBreakpoints.tablet) {
      return const EdgeInsets.symmetric(horizontal: 20, vertical: 16);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  }

  /// Responsive label font size.
  static double labelFontSize(double width) {
    if (width >= RjBreakpoints.tablet) return 14;
    return 13;
  }

  /// Responsive input font size.
  static double inputFontSize(double width) {
    if (width >= RjBreakpoints.tablet) return 15;
    return 14;
  }

  /// Responsive field spacing.
  static double fieldSpacing(double width) {
    if (width >= RjBreakpoints.desktop) return 24;
    if (width >= RjBreakpoints.tablet) return 22;
    return 20;
  }

  /// Responsive border radius.
  static double borderRadius(double width) {
    if (width >= RjBreakpoints.tablet) return 12;
    return 10;
  }

  /// Responsive wrap spacing for chips.
  static double chipSpacing(double width) {
    if (width >= RjBreakpoints.tablet) return 10;
    return 8;
  }

  /// Responsive wrap spacing for image grid.
  static double imageGridSpacing(double width) {
    if (width >= RjBreakpoints.tablet) return 12;
    return 10;
  }

  /// Responsive icon size for suffix icons.
  static double suffixIconSize(double width) {
    if (width >= RjBreakpoints.tablet) return 20;
    return 18;
  }

  /// Responsive spinner icon size.
  static double spinnerIconSize(double width) {
    if (width >= RjBreakpoints.tablet) return 22;
    return 20;
  }

  /// Responsive slider min/max label font size.
  static double sliderLabelFontSize(double width) {
    if (width >= RjBreakpoints.tablet) return 12;
    return 11;
  }

  /// Responsive slider value badge font size.
  static double sliderBadgeFontSize(double width) {
    if (width >= RjBreakpoints.tablet) return 14;
    return 13;
  }

  /// Responsive toggle label font size.
  static double toggleLabelFontSize(double width) {
    if (width >= RjBreakpoints.tablet) return 15;
    return 14;
  }

  /// Responsive radio option font size.
  static double radioOptionFontSize(double width) {
    if (width >= RjBreakpoints.tablet) return 15;
    return 14;
  }

  /// Responsive chip label font size.
  static double chipLabelFontSize(double width) {
    if (width >= RjBreakpoints.tablet) return 14;
    return 13;
  }

  /// Responsive error text font size.
  static double errorFontSize(double width) {
    if (width >= RjBreakpoints.tablet) return 13;
    return 12;
  }

  /// Responsive submit button font size.
  static double submitButtonFontSize(double width) {
    if (width >= RjBreakpoints.tablet) return 16;
    return 15;
  }

  /// Responsive submit button padding.
  static EdgeInsets submitButtonPadding(double width) {
    if (width >= RjBreakpoints.tablet) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 18);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  /// Responsive add tile label font size.
  static double addTileLabelFontSize(double width) {
    if (width >= RjBreakpoints.tablet) return 11;
    return 10;
  }

  /// Responsive add tile icon size.
  static double addTileIconSize(double width) {
    if (width >= RjBreakpoints.tablet) return 32;
    return 28;
  }

  /// Responsive remove button icon size (image tiles).
  static double removeIconSize(double width) {
    if (width >= RjBreakpoints.tablet) return 16;
    return 14;
  }

  /// Responsive value display font size (spinner).
  static double spinnerValueFontSize(double width) {
    if (width >= RjBreakpoints.desktop) return 20;
    if (width >= RjBreakpoints.tablet) return 19;
    return 18;
  }
}
