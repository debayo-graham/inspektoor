import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'button_main_model.dart';
export 'button_main_model.dart';

class ButtonMainWidget extends StatefulWidget {
  const ButtonMainWidget({
    super.key,
    String? buttonText,
    Color? buttonColor,
    required this.action,
    Color? buttonTextColor,
    Color? borderColor,
    bool? disableButton,
    int? buttonElevation,
  })  : this.buttonText = buttonText ?? 'Button',
        this.buttonColor = buttonColor ?? const Color(0xFF27AAE2),
        this.buttonTextColor = buttonTextColor ?? Colors.white,
        this.borderColor = borderColor ?? Colors.transparent,
        this.disableButton = disableButton ?? true,
        this.buttonElevation = buttonElevation ?? 3;

  final String buttonText;
  final Color buttonColor;
  final Future Function()? action;
  final Color buttonTextColor;
  final Color borderColor;
  final bool disableButton;
  final int buttonElevation;

  @override
  State<ButtonMainWidget> createState() => _ButtonMainWidgetState();
}

class _ButtonMainWidgetState extends State<ButtonMainWidget> {
  late ButtonMainModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => ButtonMainModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget!.disableButton ? 0.5 : 1.0,
      child: Padding(
        padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 16.0),
        child: FFButtonWidget(
          onPressed: (widget!.disableButton == true ? true : false)
              ? null
              : () async {
                  await widget.action?.call();
                },
          text: widget!.buttonText,
          options: FFButtonOptions(
            width: double.infinity,
            height: 50.0,
            padding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
            iconPadding: EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 0.0),
            color: widget!.buttonColor,
            textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                  font: GoogleFonts.inter(
                    fontWeight: FontWeight.normal,
                    fontStyle:
                        FlutterFlowTheme.of(context).titleSmall.fontStyle,
                  ),
                  color: widget!.buttonTextColor,
                  fontSize: 14.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.normal,
                  fontStyle: FlutterFlowTheme.of(context).titleSmall.fontStyle,
                ),
            elevation: widget!.buttonElevation.toDouble(),
            borderSide: BorderSide(
              color: widget!.borderColor,
              width: 1.0,
            ),
            borderRadius: BorderRadius.circular(24.0),
          ),
        ),
      ),
    );
  }
}
