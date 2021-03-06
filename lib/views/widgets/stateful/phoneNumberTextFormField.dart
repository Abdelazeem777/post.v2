import 'package:flutter/material.dart';
import 'package:post/style/appColors.dart';
import 'package:post/utils/validator.dart';
import 'package:post/views/widgets/stateless/mainTextFormField.dart';

class PhoneNumberTextFormField extends MainTextFormField {
  PhoneNumberTextFormField(
      {@required final FocusNode currentFocusNode,
      @required final FocusNode nextFocusNode,
      @required final TextEditingController currentController,
      EdgeInsetsGeometry margin})
      : super(
          currentController: currentController,
          currentFocusNode: currentFocusNode,
          nextFocusNode: nextFocusNode,
          validator: Validator.validatePhoneNumber,
          icon: const Icon(
            Icons.phone,
            color: AppColors.PRIMARY_COLOR,
            size: 21,
          ),
          hintText: "Phone Number",
          keyboardType: TextInputType.phone,
          margin: margin,
        );
}
