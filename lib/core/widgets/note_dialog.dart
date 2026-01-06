import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zad_aldaia/core/theming/my_colors.dart';
import 'package:zad_aldaia/core/theming/my_text_style.dart';

class NoteDialog extends StatelessWidget {
  final String? title;
  final String note;

  const NoteDialog({super.key, required this.note, this.title});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 3,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 20.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title??"Note", style: MyTextStyle.font18BlackBold),
            SizedBox(height: 10.h),
            SelectableText(note, style: MyTextStyle.font16BlackRegular),
            SizedBox(height: 20.h),
            MaterialButton(
              onPressed: () => Navigator.of(context).pop(),
              color: MyColors.primaryColor,
              child: Text("Dismiss", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
