import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zad_aldaia/core/helpers/font_weight_helper.dart';
import 'package:zad_aldaia/core/theming/my_colors.dart';

class MyTextStyle {
  static final font36primaryBold = TextStyle(
    fontSize: 36.sp,
    fontWeight: FontWeightHelper.bold,
    color: MyColors.primaryColor
  );

  static final font22primaryBold = TextStyle(
      fontSize: 22.sp,
      fontWeight: FontWeightHelper.bold,
      color: MyColors.primaryColor
  );

  static final font18BlackRegular = TextStyle(
      fontSize: 18.sp,
      fontWeight: FontWeightHelper.regular,
      color: Colors.black
  );

  static final font16BlackRegular = TextStyle(
      fontSize: 16.sp,
      fontWeight: FontWeightHelper.regular,
      color: Colors.black
  );

  static final font18GreyRegular = TextStyle(
      fontSize: 18.sp,
      fontWeight: FontWeightHelper.regular,
      color: Colors.grey[600]
  );


  static final font16WhiteRegular = TextStyle(
      fontSize: 16.sp,
      fontWeight: FontWeightHelper.regular,
      color: Colors.white
  );

  static final font16WhiteBold = TextStyle(
      fontSize: 16.sp,
      fontWeight: FontWeightHelper.bold,
      color: Colors.white
  );

  static final font18WhiteRegular = TextStyle(
      fontSize: 18.sp,
      fontWeight: FontWeightHelper.regular,
      color: Colors.white
  );

  static final font18BlackBold = TextStyle(
      fontSize: 18.sp,
      fontWeight: FontWeightHelper.bold,
      color: Colors.black
  );


  static final font14primaryRegular = TextStyle(
      fontSize: 14.sp,
      fontWeight: FontWeightHelper.regular,
      color: MyColors.primaryColor
  );

  static final font16primaryRegular = TextStyle(
      fontSize: 16.sp,
      fontWeight: FontWeightHelper.regular,
      color: MyColors.primaryColor
  );

  static final font20primaryBold = TextStyle(
      fontSize: 20.sp,
      fontWeight: FontWeightHelper.bold,
      color: MyColors.primaryColor
  );


  static final font14BlackRegular = TextStyle(
      fontSize: 14.sp,
      fontWeight: FontWeightHelper.regular,
      color: Colors.black
  );

  static var font16Grey;
}
