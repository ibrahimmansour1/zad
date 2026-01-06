import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theming/my_colors.dart';
import '../theming/my_text_style.dart';

class MyDropdownButton extends StatefulWidget {
  final String title;
  final List<DropdownMenuItem<String>> items;
  final Function(String) onSelected;
  final String? initialSelection;
  const MyDropdownButton({super.key, required this.items, required this.onSelected, required this.title, this.initialSelection});

  @override
  State<MyDropdownButton> createState() => _MyDropdownButtonState();
}

class _MyDropdownButtonState extends State<MyDropdownButton> {

  late String? _selected = widget.initialSelection?? widget.items.first.value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.title, style: MyTextStyle.font18GreyRegular),
        SizedBox(height: 5.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            border: Border.all(color: MyColors.primaryColor),
            borderRadius: BorderRadius.circular(15.h),
          ),
          child: DropdownButton(
            underline: Container(),
            isExpanded: true,
            value: _selected,
            items: widget.items,
            onChanged: (value) {
              if (value != null) {
                _selected = value;
                widget.onSelected(value);
                setState(() {});
              }
            },
          ),
        ),
      ],
    );
  }
}



