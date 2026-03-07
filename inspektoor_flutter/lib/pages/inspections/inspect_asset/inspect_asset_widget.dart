import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/features/inspection/inspection_runner_view.dart';
import '/features/inspection/inspection_session.dart';
import '/common/components/confirm_quit_inspection_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'inspect_asset_model.dart';
export 'inspect_asset_model.dart';

class InspectAssetWidget extends StatefulWidget {
  const InspectAssetWidget({super.key});

  static String routeName = 'InspectAsset';
  static String routePath = '/inspectAsset';

  @override
  State<InspectAssetWidget> createState() => _InspectAssetWidgetState();
}

class _InspectAssetWidgetState extends State<InspectAssetWidget> {
  late InspectAssetModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => InspectAssetModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  /// Called by both the AppBar back icon and the system back gesture.
  ///
  /// If the user has answered at least one item, shows a confirmation dialog
  /// that requires typing "confirm" before allowing navigation away.
  Future<void> _handleBackTap() async {
    final hasStarted = _hasInteracted ||
        InspectionSession.answeredCount(FFAppState().inspectionDraftJson) > 0;

    if (!hasStarted) {
      Navigator.of(context).pop();
      return;
    }

    final confirmed = await ConfirmQuitInspectionDialog.show(
      context,
      themeColor: FlutterFlowTheme.of(context).tertiary,
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();
    final assetName =
        InspectionSession.assetName(FFAppState().inspectionDraftJson);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (_, __) => _handleBackTap(),
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                InkWell(
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: _handleBackTap,
                  child: Container(
                    width: 24.0,
                    height: 24.0,
                    decoration: const BoxDecoration(),
                    child: Icon(
                      FFIcons.kchevronLeft,
                      color: FlutterFlowTheme.of(context).primary,
                      size: 24.0,
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: const AlignmentDirectional(0.0, 0.0),
                    child: Text(
                      assetName.isNotEmpty ? assetName : 'Inspection',
                      style: FlutterFlowTheme.of(context).titleLarge.override(
                            font: GoogleFonts.inter(
                              fontWeight: FontWeight.w500,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleLarge
                                  .fontStyle,
                            ),
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w500,
                            fontStyle: FlutterFlowTheme.of(context)
                                .titleLarge
                                .fontStyle,
                          ),
                    ),
                  ),
                ),
                // Balances the leading icon so the title stays visually centred.
                const SizedBox(width: 24.0),
              ],
            ),
            centerTitle: false,
            elevation: 0.0,
            scrolledUnderElevation: 0.0,
          ),
          body: SafeArea(
            top: true,
            child: InspectionRunnerView(
              onInteracted: () {
                if (!_hasInteracted) setState(() => _hasInteracted = true);
              },
            ),
          ),
        ),
      ),
    );
  }
}
