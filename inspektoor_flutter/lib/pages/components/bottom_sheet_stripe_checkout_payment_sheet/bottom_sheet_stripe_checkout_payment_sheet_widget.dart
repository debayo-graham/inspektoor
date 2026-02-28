import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_web_view.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'bottom_sheet_stripe_checkout_payment_sheet_model.dart';
export 'bottom_sheet_stripe_checkout_payment_sheet_model.dart';

class BottomSheetStripeCheckoutPaymentSheetWidget extends StatefulWidget {
  const BottomSheetStripeCheckoutPaymentSheetWidget({
    super.key,
    required this.url,
  });

  final String? url;

  @override
  State<BottomSheetStripeCheckoutPaymentSheetWidget> createState() =>
      _BottomSheetStripeCheckoutPaymentSheetWidgetState();
}

class _BottomSheetStripeCheckoutPaymentSheetWidgetState
    extends State<BottomSheetStripeCheckoutPaymentSheetWidget> {
  late BottomSheetStripeCheckoutPaymentSheetModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(
        context, () => BottomSheetStripeCheckoutPaymentSheetModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FlutterFlowWebView(
      content: widget!.url!,
      bypass: true,
      height: 500.0,
      verticalScroll: false,
      horizontalScroll: false,
    );
  }
}
