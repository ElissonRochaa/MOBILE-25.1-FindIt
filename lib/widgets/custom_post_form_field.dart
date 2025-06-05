import 'package:flutter/material.dart';

class CustomPostFormField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String labelText;
  final IconData iconData;
  final bool isFocused;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final int maxLines;
  final bool obscureText;
  final void Function()? onTap;
  final bool readOnly;

  const CustomPostFormField({
    super.key,
    this.controller,
    this.focusNode,
    required this.labelText,
    required this.iconData,
    required this.isFocused,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.obscureText = false,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color iconColor = isFocused ? theme.primaryColor : theme.iconTheme.color ?? Colors.grey;
    final Color focusedInputFillColor = theme.primaryColor.withOpacity(0.1);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        obscureText: obscureText,
        onTap: onTap,
        readOnly: readOnly,
        style: TextStyle(
          fontSize: 18,
          color: theme.textTheme.bodyMedium?.color,
        ),
        cursorColor: theme.primaryColor,
        decoration: InputDecoration(
          filled: true,
          fillColor: isFocused ? focusedInputFillColor : theme.cardTheme.color?.withOpacity(0.3) ?? Colors.grey[200],
          labelText: labelText,
          labelStyle: TextStyle(color: theme.hintColor, fontSize: 18),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 20, right: 12),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 25),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: theme.dividerColor, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: theme.dividerColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: theme.primaryColor, width: 2.0),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(color: theme.colorScheme.error, width: 2.0),
          ),
        ),
      ),
    );
  }
}