import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import 'bottom_sheet_plan_confirmation_widget.dart'
    show BottomSheetPlanConfirmationWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class BottomSheetPlanConfirmationModel
    extends FlutterFlowModel<BottomSheetPlanConfirmationWidget> {
  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - API (Create Stripe Checkout Session)] action in Button widget.
  ApiCallResponse? apiResultyurl;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
