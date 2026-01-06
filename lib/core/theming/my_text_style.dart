import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zad_aldaia/core/helpers/font_weight_helper.dart';
import 'package:zad_aldaia/core/theming/my_colors.dart';

class MyTextStyle {
  // Display Styles
  static final displayLarge = TextStyle(
    fontSize: 36.sp,
    fontWeight: FontWeightHelper.bold,
    color: MyColors.textPrimary,
    letterSpacing: -0.5,
  );

  static final displayMedium = TextStyle(
    fontSize: 28.sp,
    fontWeight: FontWeightHelper.bold,
    color: MyColors.textPrimary,
    letterSpacing: -0.2,
  );

  static final displaySmall = TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWeightHelper.bold,
    color: MyColors.textPrimary,
  );

  // Heading Styles
  static final headingLarge = TextStyle(
    fontSize: 22.sp,
    fontWeight: FontWeightHelper.bold,
    color: MyColors.primaryColor,
  );

  static final headingMedium = TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeightHelper.bold,
    color: MyColors.textPrimary,
  );

  static final headingSmall = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeightHelper.bold,
    color: MyColors.textPrimary,
  );

  // Body Styles
  static final bodyLarge = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeightHelper.regular,
    color: MyColors.textPrimary,
    height: 1.5,
  );

  static final bodyMedium = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeightHelper.regular,
    color: MyColors.textPrimary,
    height: 1.5,
  );

  static final bodySmall = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeightHelper.regular,
    color: MyColors.textSecondary,
    height: 1.4,
  );

  // Label Styles
  static final labelLarge = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeightHelper.semiBold,
    color: MyColors.textPrimary,
    letterSpacing: 0.5,
  );

  static final labelMedium = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeightHelper.semiBold,
    color: MyColors.textSecondary,
    letterSpacing: 0.4,
  );

  static final labelSmall = TextStyle(
    fontSize: 12.sp,
    fontWeight: FontWeightHelper.semiBold,
    color: MyColors.textTertiary,
    letterSpacing: 0.3,
  );

  // Primary Color Variants
  static final font36primaryBold =
      displayLarge.copyWith(color: MyColors.primaryColor);
  static final font22primaryBold = headingLarge;
  static final font20primaryBold = TextStyle(
    fontSize: 20.sp,
    fontWeight: FontWeightHelper.bold,
    color: MyColors.primaryColor,
  );
  static final font16primaryRegular = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeightHelper.regular,
    color: MyColors.primaryColor,
  );
  static final font14primaryRegular = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeightHelper.regular,
    color: MyColors.primaryColor,
  );

  // Black Text Variants
  static final font18BlackRegular = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeightHelper.regular,
    color: MyColors.textPrimary,
  );

  static final font18BlackBold = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeightHelper.bold,
    color: MyColors.textPrimary,
  );

  static final font16BlackRegular = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeightHelper.regular,
    color: MyColors.textPrimary,
  );

  static final font14BlackRegular = TextStyle(
    fontSize: 14.sp,
    fontWeight: FontWeightHelper.regular,
    color: MyColors.textPrimary,
  );

  // Grey Text Variants
  static final font18GreyRegular = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeightHelper.regular,
    color: MyColors.textSecondary,
  );

  static final font16Grey = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeightHelper.regular,
    color: MyColors.textSecondary,
  );

  // White Text Variants
  static final font16WhiteRegular = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeightHelper.regular,
    color: Colors.white,
  );

  static final font16WhiteBold = TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeightHelper.bold,
    color: Colors.white,
  );

  static final font18WhiteRegular = TextStyle(
    fontSize: 18.sp,
    fontWeight: FontWeightHelper.regular,
    color: Colors.white,
  );
}
