import '/flutter_flow/flutter_flow_credit_card_form.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'bottom_sheet_stripe_checkout_model.dart';
export 'bottom_sheet_stripe_checkout_model.dart';

class BottomSheetStripeCheckoutWidget extends StatefulWidget {
  const BottomSheetStripeCheckoutWidget({super.key});

  @override
  State<BottomSheetStripeCheckoutWidget> createState() =>
      _BottomSheetStripeCheckoutWidgetState();
}

class _BottomSheetStripeCheckoutWidgetState
    extends State<BottomSheetStripeCheckoutWidget> {
  late BottomSheetStripeCheckoutModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BottomSheetStripeCheckoutModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      children: [
        FlutterFlowCreditCardForm(
          formKey: _model.creditCardFormKey,
          creditCardModel: _model.creditCardInfo,
          obscureNumber: true,
          obscureCvv: false,
          spacing: 12.0,
          textStyle: FlutterFlowTheme.of(context).bodyMedium.override(
                font: GoogleFonts.inter(
                  fontWeight:
                      FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                ),
                letterSpacing: 0.0,
                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
              ),
          inputDecoration: InputDecoration(
            filled: true,
            fillColor: FlutterFlowTheme.of(context).secondaryBackground,
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Color(0x00000000),
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Color(0x00000000),
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ),
      ],
    );
  }
}
