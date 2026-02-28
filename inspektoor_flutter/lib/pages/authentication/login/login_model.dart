import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/button_main/button_main_widget.dart';
import '/pages/components/snackbar/snackbar_widget.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'login_widget.dart' show LoginWidget;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class LoginModel extends FlutterFlowModel<LoginWidget> {
  ///  Local state fields for this page.

  dynamic validationResult;

  String? emailErrorMsg;

  bool emailState = false;

  String? passwordErrorMsg;

  bool passwordState = false;

  bool loginState = false;

  ///  State fields for stateful widgets in this page.

  // State field(s) for emailAddress widget.
  FocusNode? emailAddressFocusNode;
  TextEditingController? emailAddressTextController;
  String? Function(BuildContext, String?)? emailAddressTextControllerValidator;
  // State field(s) for password widget.
  FocusNode? passwordFocusNode;
  TextEditingController? passwordTextController;
  late bool passwordVisibility;
  String? Function(BuildContext, String?)? passwordTextControllerValidator;
  // Model for buttonMain component.
  late ButtonMainModel buttonMainModel;
  // Stores action output result for [Custom Action - caLogin] action in buttonMain widget.
  dynamic? loginResults;
  // Model for snackbar component.
  late SnackbarModel snackbarModel;

  @override
  void initState(BuildContext context) {
    passwordVisibility = false;
    buttonMainModel = createModel(context, () => ButtonMainModel());
    snackbarModel = createModel(context, () => SnackbarModel());
  }

  @override
  void dispose() {
    emailAddressFocusNode?.dispose();
    emailAddressTextController?.dispose();

    passwordFocusNode?.dispose();
    passwordTextController?.dispose();

    buttonMainModel.dispose();
    snackbarModel.dispose();
  }
}
