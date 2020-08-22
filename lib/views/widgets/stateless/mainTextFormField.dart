import 'package:flutter/material.dart';
import 'package:post/style/appColors.dart';
import 'package:post/utils/sizeConfig.dart';

abstract class MainTextFormField extends StatelessWidget {
  final FocusNode currentFocusNode, nextFocusNode;
  final TextEditingController currentController;
  final String hintText;
  final TextInputType keyboardType;
  final Function(String) validator;
  final Icon icon;

  MainTextFormField({
    @required this.currentController,
    @required this.currentFocusNode,
    @required this.nextFocusNode,
    @required this.hintText,
    this.keyboardType,
    @required this.validator,
    @required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      margin: EdgeInsets.fromLTRB(16, SizeConfig.safeBlockVertical * 3, 16, 0),
      child: TextFormField(
          focusNode: this.currentFocusNode,
          controller: this.currentController,
          keyboardType: this.keyboardType,
          maxLines: 1,
          style: TextStyle(fontSize: 14),
          decoration: InputDecoration(
            contentPadding: EdgeInsets.all(0),
            hintText: this.hintText,
            prefixIcon: this.icon,
            border: InputBorder.none,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.PRIMARY_COLOR,
                width: 1,
              ),
              borderRadius: const BorderRadius.all(
                const Radius.circular(50),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: AppColors.PRIMARY_COLOR,
                width: 1,
              ),
              borderRadius: const BorderRadius.all(
                const Radius.circular(50),
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.red,
                width: 1,
              ),
              borderRadius: const BorderRadius.all(
                const Radius.circular(50),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.red,
                width: 1,
              ),
              borderRadius: const BorderRadius.all(
                const Radius.circular(50),
              ),
            ),
          ),
          validator: this.validator,
          onFieldSubmitted: (String value) {
            FocusScope.of(context).requestFocus(this.nextFocusNode);
          }),
    );
  }
}
