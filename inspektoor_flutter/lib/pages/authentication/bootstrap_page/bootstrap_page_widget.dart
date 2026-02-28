import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/snackbar/snackbar_widget.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'bootstrap_page_model.dart';
export 'bootstrap_page_model.dart';

class BootstrapPageWidget extends StatefulWidget {
  const BootstrapPageWidget({super.key});

  static String routeName = 'BootstrapPage';
  static String routePath = '/bootstrapPage';

  @override
  State<BootstrapPageWidget> createState() => _BootstrapPageWidgetState();
}

class _BootstrapPageWidgetState extends State<BootstrapPageWidget> {
  late BootstrapPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BootstrapPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.bootstrapResult = await actions.caBootstrap();
      await Future.delayed(
        Duration(
          milliseconds: 200,
        ),
      );
      FFAppState().entitlementStatus = getJsonField(
        _model.bootstrapResult,
        r'''$.status''',
      ).toString();
      safeSetState(() {});
      _model.bootstrapStatus = getJsonField(
        _model.bootstrapResult,
        r'''$.ok''',
      );
      safeSetState(() {});
      if (_model.bootstrapStatus == true) {
        _model.loaderMsg = 'Checking entitlement....';
        safeSetState(() {});
        await Future.delayed(
          Duration(
            milliseconds: 200,
          ),
        );
        if (FFAppState().entitlementStatus ==
            FFAppConstants.ENTITLEMENTSTATUSACTIVE) {
          FFAppState().currentOrgId = getJsonField(
            _model.bootstrapResult,
            r'''$.orgId''',
          ).toString();
          FFAppState().assetLimit = getJsonField(
            _model.bootstrapResult,
            r'''$.assetLimit''',
          );
          FFAppState().features = getJsonField(
            _model.bootstrapResult,
            r'''$.features''',
          );
          FFAppState().planId = getJsonField(
            _model.bootstrapResult,
            r'''$.planId''',
          ).toString();
          safeSetState(() {});
          FFAppState().userAccessToken = functions.getSupabaseToken()!;
          safeSetState(() {});

          context.pushNamed(HomePageWidget.routeName);
        } else {
          FFAppState().snackbarMsg =
              FFAppConstants.SNACKBARNOACTIVEENTITLEMENTMSG;
          FFAppState().snackbarColor = FlutterFlowTheme.of(context).error;
          FFAppState().showSnackbar = true;
          safeSetState(() {});
          await Future.delayed(
            Duration(
              milliseconds: 2500,
            ),
          );
          FFAppState().showSnackbar = false;
          safeSetState(() {});

          context.pushNamed(LoginWidget.routeName);
        }
      } else {
        FFAppState().snackbarMsg = FFAppConstants.SNACKBARNOORGORENTITLEMENTMSG;
        FFAppState().snackbarColor = FlutterFlowTheme.of(context).error;
        FFAppState().showSnackbar = true;
        safeSetState(() {});
        await Future.delayed(
          Duration(
            milliseconds: 2500,
          ),
        );
        FFAppState().showSnackbar = false;
        safeSetState(() {});
        await Future.delayed(
          Duration(
            milliseconds: 600,
          ),
        );

        context.pushNamed(LoginWidget.routeName);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/jsons/Loading_Files.json',
                      width: 200.0,
                      height: 200.0,
                      fit: BoxFit.contain,
                      animate: true,
                    ),
                    Text(
                      valueOrDefault<String>(
                        _model.loaderMsg,
                        'Getting Organization and entitlement....',
                      ),
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                          ),
                    ),
                  ],
                ),
              ),
              if (FFAppState().showSnackbar == true)
                Align(
                  alignment: AlignmentDirectional(0.0, 1.0),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 50.0),
                    child: wrapWithModel(
                      model: _model.snackbarModel,
                      updateCallback: () => safeSetState(() {}),
                      child: SnackbarWidget(),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
