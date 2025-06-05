import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
// Supondo que CustomProfileFormField e ProfileFormLayout estejam em arquivos separados:
// import 'package:find_it/widgets/custom_profile_form_field.dart';

// Para este exemplo, as classes CustomProfileFormField e ProfileFormLayout
// estão coladas aqui para ser auto-contido.

// INÍCIO: Classe CustomProfileFormField (cole ou importe de um arquivo separado)
class CustomProfileFormField extends StatelessWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String labelText;
  final IconData iconData;
  final bool isFocused;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final String? initialValue;
  final bool readOnly;
  final Color? cursorColor;
  final TextStyle? textStyle;
  final InputDecoration Function({
    required String labelText,
    required IconData iconData,
    required bool isFocused,
    bool readOnly,
    required BuildContext context,
  }) inputDecorationBuilder;

  const CustomProfileFormField({
    Key? key,
    this.controller,
    this.focusNode,
    required this.labelText,
    required this.iconData,
    required this.isFocused,
    this.keyboardType,
    this.validator,
    this.initialValue,
    this.readOnly = false,
    this.cursorColor,
    this.textStyle,
    required this.inputDecorationBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        key: ValueKey(labelText + (initialValue ?? controller?.text ?? '')), // Chave para garantir atualização correta
        controller: controller,
        focusNode: focusNode,
        initialValue: initialValue,
        readOnly: readOnly,
        keyboardType: keyboardType,
        cursorColor: cursorColor ?? Theme.of(context).primaryColor,
        style: textStyle ??
            TextStyle(
              fontSize: 18,
              color: readOnly
                  ? Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6)
                  : Theme.of(context).textTheme.bodyMedium?.color,
            ),
        validator: validator,
        decoration: inputDecorationBuilder(
          labelText: labelText,
          iconData: iconData,
          isFocused: isFocused,
          readOnly: readOnly,
          context: context,
        ),
      ),
    );
  }
}

class ProfileFormLayout extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ProfileFormLayout({
    Key? key,
    required this.formKey,
    required this.children,
    this.maxWidth = 500, // Valor padrão do código original
    this.padding = const EdgeInsets.all(24), // Valor padrão do código original
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: SingleChildScrollView(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}