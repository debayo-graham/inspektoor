import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/button_main/button_main_widget.dart';
import 'dart:ui';
import '/index.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'get_started_page_model.dart';
export 'get_started_page_model.dart';

class GetStartedPageWidget extends StatefulWidget {
  const GetStartedPageWidget({super.key});

  static String routeName = 'GetStartedPage';
  static String routePath = '/getStartedPage';

  @override
  State<GetStartedPageWidget> createState() => _GetStartedPageWidgetState();
}

class _GetStartedPageWidgetState extends State<GetStartedPageWidget> {
  late GetStartedPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => GetStartedPageModel());

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF82D9FF), FlutterFlowTheme.of(context).primary],
              stops: [0.0, 1.0],
              begin: AlignmentDirectional(1.0, 0.0),
              end: AlignmentDirectional(-1.0, 0),
            ),
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(25.0, 0.0, 25.0, 0.0),
            child: Container(
              decoration: BoxDecoration(),
              child: Visibility(
                visible: responsiveVisibility(
                  context: context,
                  tablet: false,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      children: [
                        Align(
                          alignment: AlignmentDirectional(0.0, 0.0),
                          child: Container(
                            width: 315.0,
                            height: 233.0,
                            decoration: BoxDecoration(),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.asset(
                                'assets/images/inspector-icon_(6).png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Flexible(
                      child: Text(
                        'Simplify Asset Inspections & Beyond, All in One Place',
                        textAlign: TextAlign.center,
                        style: FlutterFlowTheme.of(context).titleLarge.override(
                              font: GoogleFonts.inter(
                                fontWeight: FontWeight.w300,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleLarge
                                    .fontStyle,
                              ),
                              color: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                              fontSize: 29.0,
                              letterSpacing: 0.0,
                              fontWeight: FontWeight.w300,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .titleLarge
                                  .fontStyle,
                              lineHeight: 1.5,
                            ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 20.0,
                      decoration: BoxDecoration(),
                    ),
                    Text(
                      'Experience Smart and Easy Inspections with\nInspecktoor Mobile Application',
                      textAlign: TextAlign.center,
                      style: FlutterFlowTheme.of(context).bodyMedium.override(
                            font: GoogleFonts.inter(
                              fontWeight: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontWeight,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .fontStyle,
                            ),
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            letterSpacing: 0.0,
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                            fontStyle: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontStyle,
                            lineHeight: 1.5,
                          ),
                    ),
                    Container(
                      width: double.infinity,
                      height: 20.0,
                      decoration: BoxDecoration(),
                    ),
                    Container(
                      width: 283.0,
                      decoration: BoxDecoration(),
                      child: wrapWithModel(
                        model: _model.buttonMainModel,
                        updateCallback: () => safeSetState(() {}),
                        child: ButtonMainWidget(
                          buttonText: 'Get Started',
                          buttonColor:
                              FlutterFlowTheme.of(context).primaryBackground,
                          buttonTextColor: FlutterFlowTheme.of(context).primary,
                          disableButton: false,
                          action: () async {
                            context.pushNamed(OnboardingPageWidget.routeName);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
