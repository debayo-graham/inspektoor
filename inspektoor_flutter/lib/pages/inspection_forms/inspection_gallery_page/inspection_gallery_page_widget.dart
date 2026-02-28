import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/app_drawer_content/app_drawer_content_widget.dart';
import '/pages/components/custom_confirm_dialog/custom_confirm_dialog_widget.dart';
import '/pages/components/inspection_gallery_more_options/inspection_gallery_more_options_widget.dart';
import '/pages/components/snackbar/snackbar_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'inspection_gallery_page_model.dart';
export 'inspection_gallery_page_model.dart';

class InspectionGalleryPageWidget extends StatefulWidget {
  const InspectionGalleryPageWidget({super.key});

  static String routeName = 'InspectionGalleryPage';
  static String routePath = '/inspectionGalleryPage';

  @override
  State<InspectionGalleryPageWidget> createState() =>
      _InspectionGalleryPageWidgetState();
}

class _InspectionGalleryPageWidgetState
    extends State<InspectionGalleryPageWidget> with TickerProviderStateMixin {
  late InspectionGalleryPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  final animationsMap = <String, AnimationInfo>{};

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => InspectionGalleryPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (animationsMap['containerOnActionTriggerAnimation1'] != null) {
        await animationsMap['containerOnActionTriggerAnimation1']!
            .controller
            .forward(from: 0.0);
      }
    });

    _model.searchTextFieldTextController ??= TextEditingController();
    _model.searchTextFieldFocusNode ??= FocusNode();

    animationsMap.addAll({
      'containerOnActionTriggerAnimation1': AnimationInfo(
        trigger: AnimationTrigger.onActionTrigger,
        applyInitialState: true,
        effectsBuilder: null,
      ),
      'containerOnActionTriggerAnimation2': AnimationInfo(
        trigger: AnimationTrigger.onActionTrigger,
        applyInitialState: true,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeIn,
            delay: 0.0.ms,
            duration: 200.0.ms,
            begin: Offset(-85.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
      'containerOnActionTriggerAnimation3': AnimationInfo(
        trigger: AnimationTrigger.onActionTrigger,
        applyInitialState: true,
        effectsBuilder: () => [
          MoveEffect(
            curve: Curves.easeIn,
            delay: 0.0.ms,
            duration: 200.0.ms,
            begin: Offset(-30.0, 0.0),
            end: Offset(0.0, 0.0),
          ),
        ],
      ),
    });
    setupAnimations(
      animationsMap.values.where((anim) =>
          anim.trigger == AnimationTrigger.onActionTrigger ||
          !anim.applyInitialState),
      this,
    );

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
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        drawer: Drawer(
          elevation: 16.0,
          child: WebViewAware(
            child: wrapWithModel(
              model: _model.appDrawerContentModel,
              updateCallback: () => safeSetState(() {}),
              child: AppDrawerContentWidget(),
            ),
          ),
        ),
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          automaticallyImplyLeading: false,
          title: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              InkWell(
                splashColor: Colors.transparent,
                focusColor: Colors.transparent,
                hoverColor: Colors.transparent,
                highlightColor: Colors.transparent,
                onTap: () async {
                  scaffoldKey.currentState!.openDrawer();
                },
                child: Container(
                  decoration: BoxDecoration(),
                  child: Icon(
                    FFIcons.kmenu,
                    color: FlutterFlowTheme.of(context).primary,
                    size: 24.0,
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Text(
                    'Inspection Gallery',
                    style: FlutterFlowTheme.of(context).headlineMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FontWeight.w500,
                            fontStyle: FlutterFlowTheme.of(context)
                                .headlineMedium
                                .fontStyle,
                          ),
                          color: FlutterFlowTheme.of(context).primaryText,
                          fontSize: 20.0,
                          letterSpacing: 0.0,
                          fontWeight: FontWeight.w500,
                          fontStyle: FlutterFlowTheme.of(context)
                              .headlineMedium
                              .fontStyle,
                        ),
                  ),
                ),
              ),
            ],
          ),
          actions: [],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                15.0, 30.0, 15.0, 0.0),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      InkWell(
                                        splashColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () async {
                                          if (_model.fliterTab !=
                                              'org_created') {
                                            _model.fliterTab = 'org_created';
                                            safeSetState(() {});
                                            if (animationsMap[
                                                    'containerOnActionTriggerAnimation2'] !=
                                                null) {
                                              animationsMap[
                                                      'containerOnActionTriggerAnimation2']!
                                                  .controller
                                                  .reset();
                                            }
                                            if (animationsMap[
                                                    'containerOnActionTriggerAnimation3'] !=
                                                null) {
                                              animationsMap[
                                                      'containerOnActionTriggerAnimation3']!
                                                  .controller
                                                  .reset();
                                            }
                                            if (animationsMap[
                                                    'containerOnActionTriggerAnimation1'] !=
                                                null) {
                                              await animationsMap[
                                                      'containerOnActionTriggerAnimation1']!
                                                  .controller
                                                  .forward(from: 0.0);
                                            }
                                            safeSetState(() => _model
                                                .inspectionFormTemplateListViewPagingController
                                                ?.refresh());
                                            await _model
                                                .waitForOnePageForInspectionFormTemplateListView();
                                          }
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Container(
                                                width: 125.0,
                                                height: 23.0,
                                                child:
                                                    custom_widgets.DynamicText(
                                                  width: 125.0,
                                                  height: 23.0,
                                                  text: 'Created Forms',
                                                  condition: false,
                                                  falseWeight:
                                                      _model.fliterTab ==
                                                              'org_created'
                                                          ? 600
                                                          : 400,
                                                  color: _model.fliterTab ==
                                                          'org_created'
                                                      ? FlutterFlowTheme.of(
                                                              context)
                                                          .primary
                                                      : FlutterFlowTheme.of(
                                                              context)
                                                          .primaryText,
                                                  textAlign: 'center',
                                                ),
                                              ),
                                              Align(
                                                alignment: AlignmentDirectional(
                                                    0.0, 1.0),
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 5.0, 0.0, 0.0),
                                                  child: ClipRRect(
                                                    child: Container(
                                                      width: 125.0,
                                                      height: 2.0,
                                                      decoration: BoxDecoration(
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .primaryBackground,
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(35.0),
                                                        child: Container(
                                                          width: 85.0,
                                                          height: 5.0,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primary,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        35.0),
                                                          ),
                                                        ),
                                                      ).animateOnActionTrigger(
                                                        animationsMap[
                                                            'containerOnActionTriggerAnimation1']!,
                                                        effects: [
                                                          MoveEffect(
                                                            curve:
                                                                Curves.easeIn,
                                                            delay: 0.0.ms,
                                                            duration: 200.0.ms,
                                                            begin: Offset(
                                                                valueOrDefault<
                                                                    double>(
                                                                  -125,
                                                                  -125.0,
                                                                ),
                                                                0.0),
                                                            end: Offset(
                                                                0.0, 0.0),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        splashColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () async {
                                          if (_model.fliterTab != 'templates') {
                                            _model.fliterTab = 'predefined';
                                            safeSetState(() {});
                                            if (animationsMap[
                                                    'containerOnActionTriggerAnimation1'] !=
                                                null) {
                                              animationsMap[
                                                      'containerOnActionTriggerAnimation1']!
                                                  .controller
                                                  .reset();
                                            }
                                            if (animationsMap[
                                                    'containerOnActionTriggerAnimation3'] !=
                                                null) {
                                              animationsMap[
                                                      'containerOnActionTriggerAnimation3']!
                                                  .controller
                                                  .reset();
                                            }
                                            if (animationsMap[
                                                    'containerOnActionTriggerAnimation2'] !=
                                                null) {
                                              await animationsMap[
                                                      'containerOnActionTriggerAnimation2']!
                                                  .controller
                                                  .forward(from: 0.0);
                                            }
                                            safeSetState(() => _model
                                                .inspectionFormTemplateListViewPagingController
                                                ?.refresh());
                                            await _model
                                                .waitForOnePageForInspectionFormTemplateListView();
                                          }
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Container(
                                                width: 85.0,
                                                height: 23.0,
                                                child:
                                                    custom_widgets.DynamicText(
                                                  width: 85.0,
                                                  height: 23.0,
                                                  text: 'Templates',
                                                  condition: false,
                                                  falseWeight:
                                                      _model.fliterTab ==
                                                              'templates'
                                                          ? 600
                                                          : 400,
                                                  color:
                                                      _model.fliterTab ==
                                                              'templates'
                                                          ? FlutterFlowTheme.of(
                                                                  context)
                                                              .primary
                                                          : FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                  textAlign: 'center',
                                                ),
                                              ),
                                              Align(
                                                alignment: AlignmentDirectional(
                                                    0.0, 1.0),
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 5.0, 0.0, 0.0),
                                                  child: ClipRRect(
                                                    child: Container(
                                                      width: 85.0,
                                                      height: 2.0,
                                                      decoration: BoxDecoration(
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .primaryBackground,
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(35.0),
                                                        child: Container(
                                                          width: 85.0,
                                                          height: 5.0,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primary,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        35.0),
                                                          ),
                                                        ),
                                                      ).animateOnActionTrigger(
                                                        animationsMap[
                                                            'containerOnActionTriggerAnimation2']!,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      InkWell(
                                        splashColor: Colors.transparent,
                                        focusColor: Colors.transparent,
                                        hoverColor: Colors.transparent,
                                        highlightColor: Colors.transparent,
                                        onTap: () async {
                                          if (_model.fliterTab != 'all') {
                                            _model.fliterTab = 'all';
                                            safeSetState(() {});
                                            if (animationsMap[
                                                    'containerOnActionTriggerAnimation1'] !=
                                                null) {
                                              animationsMap[
                                                      'containerOnActionTriggerAnimation1']!
                                                  .controller
                                                  .reset();
                                            }
                                            if (animationsMap[
                                                    'containerOnActionTriggerAnimation2'] !=
                                                null) {
                                              animationsMap[
                                                      'containerOnActionTriggerAnimation2']!
                                                  .controller
                                                  .reset();
                                            }
                                            if (animationsMap[
                                                    'containerOnActionTriggerAnimation3'] !=
                                                null) {
                                              await animationsMap[
                                                      'containerOnActionTriggerAnimation3']!
                                                  .controller
                                                  .forward(from: 0.0);
                                            }
                                            safeSetState(() => _model
                                                .inspectionFormTemplateListViewPagingController
                                                ?.refresh());
                                            await _model
                                                .waitForOnePageForInspectionFormTemplateListView();
                                          }
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Container(
                                                width: 30.0,
                                                height: 23.0,
                                                child:
                                                    custom_widgets.DynamicText(
                                                  width: 30.0,
                                                  height: 23.0,
                                                  text: 'All',
                                                  condition: false,
                                                  falseWeight:
                                                      _model.fliterTab == 'all'
                                                          ? 600
                                                          : 400,
                                                  color:
                                                      _model.fliterTab == 'all'
                                                          ? FlutterFlowTheme.of(
                                                                  context)
                                                              .primary
                                                          : FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                  textAlign: 'center',
                                                ),
                                              ),
                                              Align(
                                                alignment: AlignmentDirectional(
                                                    0.0, 1.0),
                                                child: Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 5.0, 0.0, 0.0),
                                                  child: ClipRRect(
                                                    child: Container(
                                                      width: 30.0,
                                                      height: 2.0,
                                                      decoration: BoxDecoration(
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .primaryBackground,
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(35.0),
                                                        child: Container(
                                                          width: 85.0,
                                                          height: 5.0,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primary,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        35.0),
                                                          ),
                                                        ),
                                                      ).animateOnActionTrigger(
                                                        animationsMap[
                                                            'containerOnActionTriggerAnimation3']!,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 20.0, 0.0, 25.0),
                                          child: Container(
                                            width: MediaQuery.sizeOf(context)
                                                    .width *
                                                3.45,
                                            child: TextFormField(
                                              controller: _model
                                                  .searchTextFieldTextController,
                                              focusNode: _model
                                                  .searchTextFieldFocusNode,
                                              onChanged: (_) =>
                                                  EasyDebounce.debounce(
                                                '_model.searchTextFieldTextController',
                                                Duration(milliseconds: 400),
                                                () async {
                                                  _model.searchText = _model
                                                      .searchTextFieldTextController
                                                      .text;
                                                  safeSetState(() {});
                                                  safeSetState(() => _model
                                                      .inspectionFormTemplateListViewPagingController
                                                      ?.refresh());
                                                  await _model
                                                      .waitForOnePageForInspectionFormTemplateListView();
                                                },
                                              ),
                                              autofocus: false,
                                              autofillHints: [
                                                AutofillHints.name
                                              ],
                                              textCapitalization:
                                                  TextCapitalization.sentences,
                                              obscureText: false,
                                              decoration: InputDecoration(
                                                labelStyle: FlutterFlowTheme.of(
                                                        context)
                                                    .labelLarge
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelLarge
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .labelLarge
                                                                .fontStyle,
                                                      ),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText,
                                                      fontSize: 16.0,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelLarge
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .labelLarge
                                                              .fontStyle,
                                                    ),
                                                hintText:
                                                    'Search by name or category',
                                                hintStyle: FlutterFlowTheme.of(
                                                        context)
                                                    .bodyLarge
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyLarge
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyLarge
                                                                .fontStyle,
                                                      ),
                                                      color: Color(0x661D354F),
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyLarge
                                                              .fontWeight,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .bodyLarge
                                                              .fontStyle,
                                                    ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primaryBackground,
                                                    width: 2.0,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    width: 2.0,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                ),
                                                errorBorder: OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .alternate,
                                                    width: 2.0,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                ),
                                                focusedErrorBorder:
                                                    OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .alternate,
                                                    width: 2.0,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                ),
                                                filled: true,
                                                fillColor:
                                                    FlutterFlowTheme.of(context)
                                                        .primaryBackground,
                                                contentPadding:
                                                    EdgeInsetsDirectional
                                                        .fromSTEB(10.0, 0.0,
                                                            10.0, 0.0),
                                                suffixIcon: Icon(
                                                  Icons.search_outlined,
                                                  color: Color(0xFF757575),
                                                  size: 22.0,
                                                ),
                                              ),
                                              style:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyLarge
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyLarge
                                                                  .fontStyle,
                                                        ),
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyLarge
                                                                .fontWeight,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyLarge
                                                                .fontStyle,
                                                      ),
                                              validator: _model
                                                  .searchTextFieldTextControllerValidator
                                                  .asValidator(context),
                                              inputFormatters: [
                                                if (!isAndroid && !isiOS)
                                                  TextInputFormatter
                                                      .withFunction(
                                                          (oldValue, newValue) {
                                                    return TextEditingValue(
                                                      selection:
                                                          newValue.selection,
                                                      text: newValue.text
                                                          .toCapitalization(
                                                              TextCapitalization
                                                                  .sentences),
                                                    );
                                                  }),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  15.0, 0.0, 15.0, 0.0),
                              child: Container(
                                decoration: BoxDecoration(),
                                child: RefreshIndicator(
                                  onRefresh: () async {
                                    safeSetState(() => _model
                                        .inspectionFormTemplateListViewPagingController
                                        ?.refresh());
                                    await _model
                                        .waitForOnePageForInspectionFormTemplateListView();
                                  },
                                  child:
                                      PagedListView<ApiPagingParams, dynamic>(
                                    pagingController: _model
                                        .setInspectionFormTemplateListViewController(
                                      (nextPageMarker) =>
                                          SearchInspectionFormTemplatesCall
                                              .call(
                                        pOrg: FFAppState().currentOrgId,
                                        pScope: _model.fliterTab,
                                        pQ: _model
                                            .searchTextFieldTextController.text,
                                        pLimit: 25,
                                        pOffset: nextPageMarker.numItems,
                                        pSortBy: 'created_at',
                                        pSortDir: 'desc',
                                        userAccessToken:
                                            FFAppState().userAccessToken,
                                      ),
                                    ),
                                    padding: EdgeInsets.zero,
                                    shrinkWrap: true,
                                    reverse: false,
                                    scrollDirection: Axis.vertical,
                                    builderDelegate:
                                        PagedChildBuilderDelegate<dynamic>(
                                      // Customize what your widget looks like when it's loading the first page.
                                      firstPageProgressIndicatorBuilder: (_) =>
                                          Center(
                                        child: SizedBox(
                                          width: 50.0,
                                          height: 50.0,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              FlutterFlowTheme.of(context)
                                                  .primary,
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Customize what your widget looks like when it's loading another page.
                                      newPageProgressIndicatorBuilder: (_) =>
                                          Center(
                                        child: SizedBox(
                                          width: 50.0,
                                          height: 50.0,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              FlutterFlowTheme.of(context)
                                                  .primary,
                                            ),
                                          ),
                                        ),
                                      ),

                                      itemBuilder: (context, _,
                                          inspectionFormTemplateListIndex) {
                                        final inspectionFormTemplateListItem =
                                            _model.inspectionFormTemplateListViewPagingController!
                                                    .itemList![
                                                inspectionFormTemplateListIndex];
                                        return Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 0.0, 0.0, 10.0),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(10.0, 10.0,
                                                          10.0, 10.0),
                                                  child: InkWell(
                                                    splashColor:
                                                        Colors.transparent,
                                                    focusColor:
                                                        Colors.transparent,
                                                    hoverColor:
                                                        Colors.transparent,
                                                    highlightColor:
                                                        Colors.transparent,
                                                    onTap: () async {
                                                      context.pushNamed(
                                                        EditInspectionFormPageWidget
                                                            .routeName,
                                                        queryParameters: {
                                                          'inspectionFormTemplateRow':
                                                              serializeParam(
                                                            inspectionFormTemplateListItem,
                                                            ParamType.JSON,
                                                          ),
                                                        }.withoutNulls,
                                                      );
                                                    },
                                                    child: Container(
                                                      decoration:
                                                          BoxDecoration(),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          Expanded(
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .secondaryBackground,
                                                              ),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                children: [
                                                                  Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            0.0,
                                                                            10.0,
                                                                            0.0),
                                                                    child: Icon(
                                                                      Icons
                                                                          .library_books_outlined,
                                                                      color: FlutterFlowTheme.of(
                                                                              context)
                                                                          .primaryText,
                                                                      size:
                                                                          24.0,
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    child:
                                                                        Column(
                                                                      mainAxisSize:
                                                                          MainAxisSize
                                                                              .max,
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Text(
                                                                          valueOrDefault<
                                                                              String>(
                                                                            getJsonField(
                                                                              inspectionFormTemplateListItem,
                                                                              r'''$.name''',
                                                                            )?.toString(),
                                                                            'no name',
                                                                          ),
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .override(
                                                                                font: GoogleFonts.inter(
                                                                                  fontWeight: FontWeight.w600,
                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                ),
                                                                                fontSize: 16.0,
                                                                                letterSpacing: 0.0,
                                                                                fontWeight: FontWeight.w600,
                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                              ),
                                                                        ),
                                                                        Text(
                                                                          'Created by:  ${getJsonField(
                                                                            inspectionFormTemplateListItem,
                                                                            r'''$.creator_first_name''',
                                                                          ).toString()} ${getJsonField(
                                                                            inspectionFormTemplateListItem,
                                                                            r'''$.creator_last_name''',
                                                                          ).toString()} | ${functions.formatDate(getJsonField(
                                                                            inspectionFormTemplateListItem,
                                                                            r'''$.created_at''',
                                                                          ).toString())}',
                                                                          style: FlutterFlowTheme.of(context)
                                                                              .bodyMedium
                                                                              .override(
                                                                                font: GoogleFonts.inter(
                                                                                  fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                  fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                ),
                                                                                fontSize: 10.0,
                                                                                letterSpacing: 0.0,
                                                                                fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                              ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          Builder(
                                                            builder:
                                                                (context) =>
                                                                    InkWell(
                                                              splashColor: Colors
                                                                  .transparent,
                                                              focusColor: Colors
                                                                  .transparent,
                                                              hoverColor: Colors
                                                                  .transparent,
                                                              highlightColor:
                                                                  Colors
                                                                      .transparent,
                                                              onTap: () async {
                                                                await showAlignedDialog(
                                                                  barrierColor:
                                                                      Colors
                                                                          .transparent,
                                                                  context:
                                                                      context,
                                                                  isGlobal:
                                                                      false,
                                                                  avoidOverflow:
                                                                      true,
                                                                  targetAnchor: AlignmentDirectional(
                                                                          -1.0,
                                                                          1.0)
                                                                      .resolve(
                                                                          Directionality.of(
                                                                              context)),
                                                                  followerAnchor: AlignmentDirectional(
                                                                          1.0,
                                                                          -1.0)
                                                                      .resolve(
                                                                          Directionality.of(
                                                                              context)),
                                                                  builder:
                                                                      (dialogContext) {
                                                                    return Material(
                                                                      color: Colors
                                                                          .transparent,
                                                                      child:
                                                                          WebViewAware(
                                                                        child:
                                                                            GestureDetector(
                                                                          onTap:
                                                                              () {
                                                                            FocusScope.of(dialogContext).unfocus();
                                                                            FocusManager.instance.primaryFocus?.unfocus();
                                                                          },
                                                                          child:
                                                                              InspectionGalleryMoreOptionsWidget(
                                                                            editTemplate:
                                                                                () async {
                                                                              context.pushNamed(
                                                                                EditInspectionFormPageWidget.routeName,
                                                                                queryParameters: {
                                                                                  'inspectionFormTemplateRow': serializeParam(
                                                                                    inspectionFormTemplateListItem,
                                                                                    ParamType.JSON,
                                                                                  ),
                                                                                }.withoutNulls,
                                                                              );

                                                                              Navigator.pop(context);
                                                                            },
                                                                            deleteTemplate:
                                                                                () async {
                                                                              await showDialog(
                                                                                context: context,
                                                                                builder: (dialogContext) {
                                                                                  return Dialog(
                                                                                    elevation: 0,
                                                                                    insetPadding: EdgeInsets.zero,
                                                                                    backgroundColor: Colors.transparent,
                                                                                    alignment: AlignmentDirectional(0.0, 0.0).resolve(Directionality.of(context)),
                                                                                    child: WebViewAware(
                                                                                      child: GestureDetector(
                                                                                        onTap: () {
                                                                                          FocusScope.of(dialogContext).unfocus();
                                                                                          FocusManager.instance.primaryFocus?.unfocus();
                                                                                        },
                                                                                        child: CustomConfirmDialogWidget(
                                                                                          themeColor: FlutterFlowTheme.of(context).tertiary,
                                                                                          title: 'Confirm delete',
                                                                                          body: 'Are you sure you want to remove this inspection template? This action will delete it permanently and it cannot be recovered.',
                                                                                          icon: FaIcon(
                                                                                            FontAwesomeIcons.trashAlt,
                                                                                            color: FlutterFlowTheme.of(context).tertiary,
                                                                                            size: 60.0,
                                                                                          ),
                                                                                          onConfirm: () async {
                                                                                            _model.isDeletedInspectionFormItem = await InspectionTemplatesTable().delete(
                                                                                              matchingRows: (rows) => rows.eqOrNull(
                                                                                                'id',
                                                                                                getJsonField(
                                                                                                  inspectionFormTemplateListItem,
                                                                                                  r'''$.id''',
                                                                                                ).toString(),
                                                                                              ),
                                                                                              returnRows: true,
                                                                                            );
                                                                                            if (_model.isDeletedInspectionFormItem!.length > 0) {
                                                                                              Navigator.pop(context);
                                                                                            } else {
                                                                                              FFAppState().snackbarMsg = 'Delete was unsuccessful. Please try again ';
                                                                                              safeSetState(() {});
                                                                                              FFAppState().showSnackbar = false;
                                                                                              safeSetState(() {});
                                                                                              await Future.delayed(
                                                                                                Duration(
                                                                                                  milliseconds: 2000,
                                                                                                ),
                                                                                              );
                                                                                              FFAppState().showSnackbar = true;
                                                                                              safeSetState(() {});
                                                                                            }
                                                                                          },
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  );
                                                                                },
                                                                              );

                                                                              Navigator.pop(context);
                                                                              safeSetState(() => _model.inspectionFormTemplateListViewPagingController?.refresh());
                                                                              await _model.waitForOnePageForInspectionFormTemplateListView();
                                                                            },
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    );
                                                                  },
                                                                );

                                                                safeSetState(
                                                                    () {});
                                                              },
                                                              child: Icon(
                                                                FFIcons
                                                                    .kmoreVert,
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
                                                                size: 24.0,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                Divider(
                                                  thickness: 1.0,
                                                  color: Color(0xFFDEDEDE),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (FFAppState().showSnackbar)
                Align(
                  alignment: AlignmentDirectional(0.0, 1.0),
                  child: wrapWithModel(
                    model: _model.snackbarModel,
                    updateCallback: () => safeSetState(() {}),
                    child: SnackbarWidget(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
