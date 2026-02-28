import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/snackbar/snackbar_widget.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'bootstrap_page_widget.dart' show BootstrapPageWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class BootstrapPageModel extends FlutterFlowModel<BootstrapPageWidget> {
  ///  Local state fields for this page.

  bool bootstrapStatus = false;

  String loaderMsg = 'Getting Organization and entitlement';

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - caBootstrap] action in BootstrapPage widget.
  dynamic? bootstrapResult;
  // Model for snackbar component.
  late SnackbarModel snackbarModel;

  @override
  void initState(BuildContext context) {
    snackbarModel = createModel(context, () => SnackbarModel());
  }

  @override
  void dispose() {
    snackbarModel.dispose();
  }
}
