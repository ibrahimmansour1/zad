import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:zad_aldaia/generated/l10n.dart';

import '../theming/my_colors.dart';
import '../theming/my_text_style.dart';

class NoItemsWidget extends StatelessWidget {
  const NoItemsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return  Center(child: Column(mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.library_books_rounded,color: MyColors.primaryColor,size: 35.h,),
        Text(S.of(context).noItems,style: MyTextStyle.font16primaryRegular,)
      ],
    ));
  }
}
