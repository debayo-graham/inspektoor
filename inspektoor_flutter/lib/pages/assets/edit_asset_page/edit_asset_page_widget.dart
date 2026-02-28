import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_button_tabbar.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/upload_data.dart';
import '/pages/components/bottom_sheet_add_forms_to_asset/bottom_sheet_add_forms_to_asset_widget.dart';
import '/pages/components/custom_confirm_dialog/custom_confirm_dialog_widget.dart';
import '/pages/components/custom_message_dialog/custom_message_dialog_widget.dart';
import '/pages/components/empty_list/empty_list_widget.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';
import 'edit_asset_page_model.dart';
export 'edit_asset_page_model.dart';

class EditAssetPageWidget extends StatefulWidget {
  const EditAssetPageWidget({
    super.key,
    required this.assetRow,
  });

  final AssetsRow? assetRow;

  static String routeName = 'EditAssetPage';
  static String routePath = '/editAssetPage';

  @override
  State<EditAssetPageWidget> createState() => _EditAssetPageWidgetState();
}

class _EditAssetPageWidgetState extends State<EditAssetPageWidget>
    with TickerProviderStateMixin {
  late EditAssetPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EditAssetPageModel());

    // On page load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.inspectionsFormsQuery = await actions.getAssetForms(
        widget!.assetRow!.id,
      );
      _model.actionSuccess = getJsonField(
        _model.inspectionsFormsQuery,
        r'''$.success''',
      );
      _model.errorCode = getJsonField(
        _model.inspectionsFormsQuery,
        r'''$.status''',
      );
      _model.errorMsg = getJsonField(
        _model.inspectionsFormsQuery,
        r'''$.error''',
      ).toString();
      safeSetState(() {});
      if (_model.actionSuccess == true) {
        _model.selectedForms = getJsonField(
          _model.inspectionsFormsQuery,
          r'''$.data.forms''',
          true,
        )!
            .toList()
            .cast<dynamic>();
        _model.selectedFormIds = (getJsonField(
          _model.inspectionsFormsQuery,
          r'''$.data.ids''',
          true,
        ) as List?)!
            .map<String>((e) => e.toString())
            .toList()
            .cast<String>()
            .toList()
            .cast<String>();
        safeSetState(() {});
      } else {
        await showDialog(
          context: context,
          builder: (dialogContext) {
            return Dialog(
              elevation: 0,
              insetPadding: EdgeInsets.zero,
              backgroundColor: Colors.transparent,
              alignment: AlignmentDirectional(0.0, 0.0)
                  .resolve(Directionality.of(context)),
              child: WebViewAware(
                child: GestureDetector(
                  onTap: () {
                    FocusScope.of(dialogContext).unfocus();
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  child: CustomMessageDialogWidget(
                    themeColor: FlutterFlowTheme.of(context).customRedDark,
                    title: 'Couldn’t Load Forms',
                    body:
                        'We couldn’t load the inspection forms for this asset. Check your connection and try again.',
                    icon: Icon(
                      Icons.info_outlined,
                      color: FlutterFlowTheme.of(context).customRedDark,
                      size: 60.0,
                    ),
                    onConfirm: () async {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            );
          },
        );
      }
    });

    _model.tabBarController = TabController(
      vsync: this,
      length: 2,
      initialIndex: 0,
    )..addListener(() => safeSetState(() {}));

    _model.assetNameTextController ??=
        TextEditingController(text: widget!.assetRow?.name);
    _model.assetNameFocusNode ??= FocusNode();

    _model.makeTextController ??=
        TextEditingController(text: widget!.assetRow?.make);
    _model.makeFocusNode ??= FocusNode();

    _model.modelTextController ??=
        TextEditingController(text: widget!.assetRow?.model);
    _model.modelFocusNode ??= FocusNode();

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

    return Builder(
      builder: (context) => GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          key: scaffoldKey,
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          appBar: AppBar(
            backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                InkWell(
                  splashColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onTap: () async {
                    context.safePop();
                  },
                  child: Container(
                    width: 24.0,
                    height: 24.0,
                    decoration: BoxDecoration(),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.asset(
                        'assets/images/arrow_back_ios_new.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional(0.0, 0.0),
                    child: Text(
                      'Edit Asset',
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
              ],
            ),
            actions: [],
            centerTitle: false,
            elevation: 0.0,
          ),
          body: SafeArea(
            top: true,
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(25.0, 0.0, 25.0, 0.0),
              child: Stack(
                children: [
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 0.0),
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment(0.0, 0),
                          child: FlutterFlowButtonTabBar(
                            useToggleButtonStyle: true,
                            labelStyle: FlutterFlowTheme.of(context)
                                .titleMedium
                                .override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                                  fontSize: 16.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontStyle,
                                ),
                            unselectedLabelStyle: FlutterFlowTheme.of(context)
                                .titleMedium
                                .override(
                                  font: GoogleFonts.inter(
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleMedium
                                        .fontStyle,
                                  ),
                                  fontSize: 14.0,
                                  letterSpacing: 0.0,
                                  fontWeight: FontWeight.w500,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleMedium
                                      .fontStyle,
                                ),
                            labelColor: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            unselectedLabelColor:
                                FlutterFlowTheme.of(context).secondaryText,
                            backgroundColor:
                                FlutterFlowTheme.of(context).primary,
                            unselectedBackgroundColor:
                                FlutterFlowTheme.of(context).formFields,
                            borderColor:
                                FlutterFlowTheme.of(context).formFields,
                            unselectedBorderColor:
                                FlutterFlowTheme.of(context).formFields,
                            borderWidth: 2.0,
                            borderRadius: 30.0,
                            elevation: 0.0,
                            buttonMargin: EdgeInsetsDirectional.fromSTEB(
                                8.0, 0.0, 8.0, 0.0),
                            tabs: [
                              Tab(
                                text: 'Asset Details',
                              ),
                              Tab(
                                text: 'Choose Forms',
                              ),
                            ],
                            controller: _model.tabBarController,
                            onTap: (i) async {
                              [() async {}, () async {}][i]();
                            },
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _model.tabBarController,
                            children: [
                              KeepAliveWidgetWrapper(
                                builder: (context) => Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 20.0, 0.0, 0.0),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8.0),
                                                    child: Image.asset(
                                                      'assets/images/photo.png',
                                                      width: 48.0,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Align(
                                                      alignment:
                                                          AlignmentDirectional(
                                                              -1.0, 0.0),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    14.0,
                                                                    0.0,
                                                                    0.0,
                                                                    0.0),
                                                        child: Text(
                                                          'Upload Photo',
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                fontSize: 20.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Text(
                                                    '1',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          fontSize: 24.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                              Align(
                                                alignment: AlignmentDirectional(
                                                    -1.0, 0.0),
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
                                                    final selectedMedia =
                                                        await selectMediaWithSourceBottomSheet(
                                                      context: context,
                                                      maxWidth: 2048.00,
                                                      maxHeight: 2048.00,
                                                      imageQuality: 85,
                                                      allowPhoto: true,
                                                    );
                                                    if (selectedMedia != null &&
                                                        selectedMedia.every((m) =>
                                                            validateFileFormat(
                                                                m.storagePath,
                                                                context))) {
                                                      safeSetState(() => _model
                                                              .isDataUploading_uploadData5jf =
                                                          true);
                                                      var selectedUploadedFiles =
                                                          <FFUploadedFile>[];

                                                      try {
                                                        selectedUploadedFiles =
                                                            selectedMedia
                                                                .map((m) =>
                                                                    FFUploadedFile(
                                                                      name: m
                                                                          .storagePath
                                                                          .split(
                                                                              '/')
                                                                          .last,
                                                                      bytes: m
                                                                          .bytes,
                                                                      height: m
                                                                          .dimensions
                                                                          ?.height,
                                                                      width: m
                                                                          .dimensions
                                                                          ?.width,
                                                                      blurHash:
                                                                          m.blurHash,
                                                                      originalFilename:
                                                                          m.originalFilename,
                                                                    ))
                                                                .toList();
                                                      } finally {
                                                        _model.isDataUploading_uploadData5jf =
                                                            false;
                                                      }
                                                      if (selectedUploadedFiles
                                                              .length ==
                                                          selectedMedia
                                                              .length) {
                                                        safeSetState(() {
                                                          _model.uploadedLocalFile_uploadData5jf =
                                                              selectedUploadedFiles
                                                                  .first;
                                                        });
                                                      } else {
                                                        safeSetState(() {});
                                                        return;
                                                      }
                                                    }
                                                  },
                                                  child: Container(
                                                    width: 200.0,
                                                    height: 200.0,
                                                    child: Stack(
                                                      children: [
                                                        Align(
                                                          alignment:
                                                              AlignmentDirectional(
                                                                  -1.0, 0.0),
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(),
                                                            child: Builder(
                                                              builder:
                                                                  (context) {
                                                                if (_model.uploadedLocalFile_uploadData5jf !=
                                                                        null &&
                                                                    (_model
                                                                            .uploadedLocalFile_uploadData5jf
                                                                            .bytes
                                                                            ?.isNotEmpty ??
                                                                        false)) {
                                                                  return Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            10.0,
                                                                            0.0,
                                                                            0.0),
                                                                    child:
                                                                        ClipRRect(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8.0),
                                                                      child: Image
                                                                          .memory(
                                                                        _model.uploadedLocalFile_uploadData5jf.bytes ??
                                                                            Uint8List.fromList([]),
                                                                        width:
                                                                            200.0,
                                                                        height:
                                                                            200.0,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ),
                                                                    ),
                                                                  );
                                                                } else {
                                                                  return Padding(
                                                                    padding: EdgeInsetsDirectional
                                                                        .fromSTEB(
                                                                            0.0,
                                                                            10.0,
                                                                            0.0,
                                                                            0.0),
                                                                    child:
                                                                        ClipRRect(
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              8.0),
                                                                      child: Image
                                                                          .network(
                                                                        valueOrDefault<
                                                                            String>(
                                                                          widget!
                                                                              .assetRow
                                                                              ?.picUrl,
                                                                          'https://storage.googleapis.com/flutterflow-io-6f20.appspot.com/projects/inspektoor-9kkv8v/assets/p8k573c1okwh/upload-your-photo.png',
                                                                        ),
                                                                        width:
                                                                            200.0,
                                                                        height:
                                                                            200.0,
                                                                        fit: BoxFit
                                                                            .cover,
                                                                      ),
                                                                    ),
                                                                  );
                                                                }
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                        Align(
                                                          alignment:
                                                              AlignmentDirectional(
                                                                  0.85, -0.79),
                                                          child: Icon(
                                                            Icons.add_a_photo,
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .primary,
                                                            size: 24.0,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 30.0, 0.0, 0.0),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    Container(
                                                      width: 56.0,
                                                      height: 56.0,
                                                      decoration:
                                                          BoxDecoration(),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                        child: Image.asset(
                                                          'assets/images/stack-asset-font-color.png',
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    14.0,
                                                                    0.0,
                                                                    0.0,
                                                                    0.0),
                                                        child: Text(
                                                          'Asset Name',
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                fontSize: 20.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      width: 100.0,
                                                      decoration: BoxDecoration(
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .secondaryBackground,
                                                      ),
                                                    ),
                                                    Text(
                                                      '2',
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            font: GoogleFonts
                                                                .inter(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                            ),
                                                            fontSize: 24.0,
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 10.0, 0.0, 0.0),
                                                  child: Text(
                                                    'Enter the name of your asset eg: Kenworth C500, Tank 301',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ),
                                                Stack(
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  10.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Container(
                                                        width: double.infinity,
                                                        child: TextFormField(
                                                          controller: _model
                                                              .assetNameTextController,
                                                          focusNode: _model
                                                              .assetNameFocusNode,
                                                          onChanged: (_) =>
                                                              EasyDebounce
                                                                  .debounce(
                                                            '_model.assetNameTextController',
                                                            Duration(
                                                                milliseconds:
                                                                    100),
                                                            () async {
                                                              _model.fldValidationResult =
                                                                  functions.validateField(
                                                                      _model
                                                                          .assetNameTextController
                                                                          .text,
                                                                      'text',
                                                                      true,
                                                                      'Asset Name',
                                                                      null,
                                                                      null,
                                                                      null,
                                                                      null,
                                                                      null,
                                                                      null,
                                                                      null);
                                                              safeSetState(
                                                                  () {});
                                                              _model.assetNameState =
                                                                  getJsonField(
                                                                _model
                                                                    .fldValidationResult,
                                                                r'''$.valid''',
                                                              );
                                                              safeSetState(
                                                                  () {});
                                                              if (_model
                                                                  .assetNameState) {
                                                                _model.assetNameErrMsg =
                                                                    null;
                                                                safeSetState(
                                                                    () {});
                                                                if ((_model.assetNameState == true) &&
                                                                    (_model.makeState ==
                                                                        true) &&
                                                                    (_model.modelState ==
                                                                        true) &&
                                                                    (_model.categoryState ==
                                                                        true) &&
                                                                    (_model.selectedForms
                                                                            .length >
                                                                        0)) {
                                                                  _model.isFormValidationOk =
                                                                      true;
                                                                  safeSetState(
                                                                      () {});
                                                                } else {
                                                                  _model.isFormValidationOk =
                                                                      false;
                                                                  safeSetState(
                                                                      () {});
                                                                }
                                                              } else {
                                                                _model.assetNameErrMsg =
                                                                    getJsonField(
                                                                  _model
                                                                      .fldValidationResult,
                                                                  r'''$.error''',
                                                                ).toString();
                                                                safeSetState(
                                                                    () {});
                                                                _model.isFormValidationOk =
                                                                    false;
                                                                safeSetState(
                                                                    () {});
                                                              }
                                                            },
                                                          ),
                                                          autofocus: false,
                                                          autofillHints: [
                                                            AutofillHints.name
                                                          ],
                                                          textCapitalization:
                                                              TextCapitalization
                                                                  .sentences,
                                                          textInputAction:
                                                              TextInputAction
                                                                  .next,
                                                          obscureText: false,
                                                          decoration:
                                                              InputDecoration(
                                                            labelText:
                                                                'Asset Name',
                                                            labelStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyLarge
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .bodyLarge
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyLarge
                                                                            .fontStyle,
                                                                      ),
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyLarge
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyLarge
                                                                          .fontStyle,
                                                                    ),
                                                            alignLabelWithHint:
                                                                false,
                                                            enabledBorder:
                                                                OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                color: _model.assetNameErrMsg !=
                                                                            null &&
                                                                        _model.assetNameErrMsg !=
                                                                            ''
                                                                    ? FlutterFlowTheme.of(
                                                                            context)
                                                                        .customRedDark
                                                                    : Color(
                                                                        0x00000000),
                                                                width: 2.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5.0),
                                                            ),
                                                            focusedBorder:
                                                                OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                                width: 2.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5.0),
                                                            ),
                                                            errorBorder:
                                                                OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .alternate,
                                                                width: 2.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5.0),
                                                            ),
                                                            focusedErrorBorder:
                                                                OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .alternate,
                                                                width: 2.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5.0),
                                                            ),
                                                            filled: true,
                                                            fillColor: FlutterFlowTheme
                                                                    .of(context)
                                                                .primaryBackground,
                                                          ),
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyLarge
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyLarge
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyLarge
                                                                      .fontStyle,
                                                                ),
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyLarge
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyLarge
                                                                    .fontStyle,
                                                              ),
                                                          enableInteractiveSelection:
                                                              true,
                                                          validator: _model
                                                              .assetNameTextControllerValidator
                                                              .asValidator(
                                                                  context),
                                                          inputFormatters: [
                                                            if (!isAndroid &&
                                                                !isiOS)
                                                              TextInputFormatter
                                                                  .withFunction(
                                                                      (oldValue,
                                                                          newValue) {
                                                                return TextEditingValue(
                                                                  selection:
                                                                      newValue
                                                                          .selection,
                                                                  text: newValue
                                                                      .text
                                                                      .toCapitalization(
                                                                          TextCapitalization
                                                                              .sentences),
                                                                );
                                                              }),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  5.0,
                                                                  10.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Text(
                                                        '*',
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .customRedDark,
                                                                  fontSize:
                                                                      22.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 30.0, 0.0, 0.0),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    Container(
                                                      width: 56.0,
                                                      height: 56.0,
                                                      decoration:
                                                          BoxDecoration(),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                        child: Image.asset(
                                                          'assets/images/tag.png',
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    14.0,
                                                                    0.0,
                                                                    0.0,
                                                                    0.0),
                                                        child: Text(
                                                          'Make',
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                fontSize: 20.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      width: 100.0,
                                                      decoration: BoxDecoration(
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .secondaryBackground,
                                                      ),
                                                    ),
                                                    Text(
                                                      '3',
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            font: GoogleFonts
                                                                .inter(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                            ),
                                                            fontSize: 24.0,
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 10.0, 0.0, 0.0),
                                                  child: Text(
                                                    'Enter the make of your asset eg: Kenworth',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ),
                                                Stack(
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  10.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Container(
                                                        width: double.infinity,
                                                        child: TextFormField(
                                                          controller: _model
                                                              .makeTextController,
                                                          focusNode: _model
                                                              .makeFocusNode,
                                                          onChanged: (_) =>
                                                              EasyDebounce
                                                                  .debounce(
                                                            '_model.makeTextController',
                                                            Duration(
                                                                milliseconds:
                                                                    100),
                                                            () async {
                                                              _model.fldValidationResult =
                                                                  functions.validateField(
                                                                      _model
                                                                          .makeTextController
                                                                          .text,
                                                                      'text',
                                                                      true,
                                                                      'Make',
                                                                      null,
                                                                      null,
                                                                      null,
                                                                      null,
                                                                      null,
                                                                      null,
                                                                      null);
                                                              safeSetState(
                                                                  () {});
                                                              _model.makeState =
                                                                  getJsonField(
                                                                _model
                                                                    .fldValidationResult,
                                                                r'''$.valid''',
                                                              );
                                                              safeSetState(
                                                                  () {});
                                                              if (_model
                                                                  .makeState) {
                                                                _model.makeErrMsg =
                                                                    null;
                                                                safeSetState(
                                                                    () {});
                                                                if ((_model.assetNameState == true) &&
                                                                    (_model.makeState ==
                                                                        true) &&
                                                                    (_model.modelState ==
                                                                        true) &&
                                                                    (_model.categoryState ==
                                                                        true) &&
                                                                    (_model.selectedForms
                                                                            .length >
                                                                        0)) {
                                                                  _model.isFormValidationOk =
                                                                      true;
                                                                  safeSetState(
                                                                      () {});
                                                                } else {
                                                                  _model.isFormValidationOk =
                                                                      false;
                                                                  safeSetState(
                                                                      () {});
                                                                }
                                                              } else {
                                                                _model.makeErrMsg =
                                                                    getJsonField(
                                                                  _model
                                                                      .fldValidationResult,
                                                                  r'''$.error''',
                                                                ).toString();
                                                                safeSetState(
                                                                    () {});
                                                                _model.isFormValidationOk =
                                                                    false;
                                                                safeSetState(
                                                                    () {});
                                                              }
                                                            },
                                                          ),
                                                          autofocus: false,
                                                          autofillHints: [
                                                            AutofillHints.name
                                                          ],
                                                          textCapitalization:
                                                              TextCapitalization
                                                                  .sentences,
                                                          textInputAction:
                                                              TextInputAction
                                                                  .next,
                                                          obscureText: false,
                                                          decoration:
                                                              InputDecoration(
                                                            labelText: 'Make',
                                                            labelStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyLarge
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .bodyLarge
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyLarge
                                                                            .fontStyle,
                                                                      ),
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyLarge
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyLarge
                                                                          .fontStyle,
                                                                    ),
                                                            alignLabelWithHint:
                                                                false,
                                                            enabledBorder:
                                                                OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                color: _model.makeErrMsg !=
                                                                            null &&
                                                                        _model.makeErrMsg !=
                                                                            ''
                                                                    ? FlutterFlowTheme.of(
                                                                            context)
                                                                        .customRedDark
                                                                    : Color(
                                                                        0x00000000),
                                                                width: 2.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5.0),
                                                            ),
                                                            focusedBorder:
                                                                OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                                width: 2.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5.0),
                                                            ),
                                                            errorBorder:
                                                                OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .alternate,
                                                                width: 2.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5.0),
                                                            ),
                                                            focusedErrorBorder:
                                                                OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .alternate,
                                                                width: 2.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5.0),
                                                            ),
                                                            filled: true,
                                                            fillColor: FlutterFlowTheme
                                                                    .of(context)
                                                                .primaryBackground,
                                                          ),
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyLarge
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyLarge
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyLarge
                                                                      .fontStyle,
                                                                ),
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyLarge
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyLarge
                                                                    .fontStyle,
                                                              ),
                                                          enableInteractiveSelection:
                                                              true,
                                                          validator: _model
                                                              .makeTextControllerValidator
                                                              .asValidator(
                                                                  context),
                                                          inputFormatters: [
                                                            if (!isAndroid &&
                                                                !isiOS)
                                                              TextInputFormatter
                                                                  .withFunction(
                                                                      (oldValue,
                                                                          newValue) {
                                                                return TextEditingValue(
                                                                  selection:
                                                                      newValue
                                                                          .selection,
                                                                  text: newValue
                                                                      .text
                                                                      .toCapitalization(
                                                                          TextCapitalization
                                                                              .sentences),
                                                                );
                                                              }),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    Align(
                                                      alignment:
                                                          AlignmentDirectional(
                                                              -1.0, -1.0),
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    5.0,
                                                                    10.0,
                                                                    0.0,
                                                                    0.0),
                                                        child: Text(
                                                          '*',
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .customRedDark,
                                                                fontSize: 22.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
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
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 30.0, 0.0, 0.0),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    Container(
                                                      width: 56.0,
                                                      height: 56.0,
                                                      decoration:
                                                          BoxDecoration(),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                        child: Image.asset(
                                                          'assets/images/model.png',
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    14.0,
                                                                    0.0,
                                                                    0.0,
                                                                    0.0),
                                                        child: Text(
                                                          'Model',
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                fontSize: 20.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      width: 100.0,
                                                      decoration: BoxDecoration(
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .secondaryBackground,
                                                      ),
                                                    ),
                                                    Text(
                                                      '4',
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            font: GoogleFonts
                                                                .inter(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                            ),
                                                            fontSize: 24.0,
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 10.0, 0.0, 0.0),
                                                  child: Text(
                                                    'Enter the model of your asset eg: C500',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ),
                                                Stack(
                                                  children: [
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  0.0,
                                                                  10.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Container(
                                                        width: double.infinity,
                                                        child: TextFormField(
                                                          controller: _model
                                                              .modelTextController,
                                                          focusNode: _model
                                                              .modelFocusNode,
                                                          onChanged: (_) =>
                                                              EasyDebounce
                                                                  .debounce(
                                                            '_model.modelTextController',
                                                            Duration(
                                                                milliseconds:
                                                                    100),
                                                            () async {
                                                              _model.fldValidationResult =
                                                                  functions.validateField(
                                                                      _model
                                                                          .modelTextController
                                                                          .text,
                                                                      'text',
                                                                      true,
                                                                      'Model',
                                                                      null,
                                                                      null,
                                                                      null,
                                                                      null,
                                                                      null,
                                                                      null,
                                                                      null);
                                                              safeSetState(
                                                                  () {});
                                                              _model.modelState =
                                                                  getJsonField(
                                                                _model
                                                                    .fldValidationResult,
                                                                r'''$.valid''',
                                                              );
                                                              safeSetState(
                                                                  () {});
                                                              if (_model
                                                                  .modelState) {
                                                                _model.modelErrMsg =
                                                                    null;
                                                                safeSetState(
                                                                    () {});
                                                                if ((_model.assetNameState == true) &&
                                                                    (_model.makeState ==
                                                                        true) &&
                                                                    (_model.modelState ==
                                                                        true) &&
                                                                    (_model.categoryState ==
                                                                        true) &&
                                                                    (_model.selectedForms
                                                                            .length >
                                                                        0)) {
                                                                  _model.isFormValidationOk =
                                                                      true;
                                                                  safeSetState(
                                                                      () {});
                                                                } else {
                                                                  _model.isFormValidationOk =
                                                                      false;
                                                                  safeSetState(
                                                                      () {});
                                                                }
                                                              } else {
                                                                _model.modelErrMsg =
                                                                    getJsonField(
                                                                  _model
                                                                      .fldValidationResult,
                                                                  r'''$.error''',
                                                                ).toString();
                                                                safeSetState(
                                                                    () {});
                                                                _model.isFormValidationOk =
                                                                    false;
                                                                safeSetState(
                                                                    () {});
                                                              }
                                                            },
                                                          ),
                                                          autofocus: false,
                                                          autofillHints: [
                                                            AutofillHints.name
                                                          ],
                                                          textCapitalization:
                                                              TextCapitalization
                                                                  .sentences,
                                                          textInputAction:
                                                              TextInputAction
                                                                  .next,
                                                          obscureText: false,
                                                          decoration:
                                                              InputDecoration(
                                                            labelText: 'Model',
                                                            labelStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyLarge
                                                                    .override(
                                                                      font: GoogleFonts
                                                                          .inter(
                                                                        fontWeight: FlutterFlowTheme.of(context)
                                                                            .bodyLarge
                                                                            .fontWeight,
                                                                        fontStyle: FlutterFlowTheme.of(context)
                                                                            .bodyLarge
                                                                            .fontStyle,
                                                                      ),
                                                                      letterSpacing:
                                                                          0.0,
                                                                      fontWeight: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyLarge
                                                                          .fontWeight,
                                                                      fontStyle: FlutterFlowTheme.of(
                                                                              context)
                                                                          .bodyLarge
                                                                          .fontStyle,
                                                                    ),
                                                            alignLabelWithHint:
                                                                false,
                                                            enabledBorder:
                                                                OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                color: _model.modelErrMsg !=
                                                                            null &&
                                                                        _model.modelErrMsg !=
                                                                            ''
                                                                    ? FlutterFlowTheme.of(
                                                                            context)
                                                                        .customRedDark
                                                                    : Color(
                                                                        0x00000000),
                                                                width: 2.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5.0),
                                                            ),
                                                            focusedBorder:
                                                                OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primary,
                                                                width: 2.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5.0),
                                                            ),
                                                            errorBorder:
                                                                OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .alternate,
                                                                width: 2.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5.0),
                                                            ),
                                                            focusedErrorBorder:
                                                                OutlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .alternate,
                                                                width: 2.0,
                                                              ),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5.0),
                                                            ),
                                                            filled: true,
                                                            fillColor: FlutterFlowTheme
                                                                    .of(context)
                                                                .primaryBackground,
                                                          ),
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyLarge
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyLarge
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyLarge
                                                                      .fontStyle,
                                                                ),
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyLarge
                                                                    .fontWeight,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyLarge
                                                                    .fontStyle,
                                                              ),
                                                          enableInteractiveSelection:
                                                              true,
                                                          validator: _model
                                                              .modelTextControllerValidator
                                                              .asValidator(
                                                                  context),
                                                          inputFormatters: [
                                                            if (!isAndroid &&
                                                                !isiOS)
                                                              TextInputFormatter
                                                                  .withFunction(
                                                                      (oldValue,
                                                                          newValue) {
                                                                return TextEditingValue(
                                                                  selection:
                                                                      newValue
                                                                          .selection,
                                                                  text: newValue
                                                                      .text
                                                                      .toCapitalization(
                                                                          TextCapitalization
                                                                              .sentences),
                                                                );
                                                              }),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding:
                                                          EdgeInsetsDirectional
                                                              .fromSTEB(
                                                                  5.0,
                                                                  10.0,
                                                                  0.0,
                                                                  0.0),
                                                      child: Text(
                                                        '*',
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    fontWeight: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontWeight,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .customRedDark,
                                                                  fontSize:
                                                                      22.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontWeight,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 30.0, 0.0, 0.0),
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryBackground,
                                            ),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    Container(
                                                      width: 56.0,
                                                      height: 56.0,
                                                      decoration:
                                                          BoxDecoration(),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8.0),
                                                        child: Image.asset(
                                                          'assets/images/stack-asset-font-color.png',
                                                          fit: BoxFit.cover,
                                                        ),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    14.0,
                                                                    0.0,
                                                                    0.0,
                                                                    0.0),
                                                        child: Text(
                                                          'Category',
                                                          style: FlutterFlowTheme
                                                                  .of(context)
                                                              .bodyMedium
                                                              .override(
                                                                font:
                                                                    GoogleFonts
                                                                        .inter(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                                fontSize: 20.0,
                                                                letterSpacing:
                                                                    0.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                fontStyle: FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    Container(
                                                      width: 100.0,
                                                      decoration: BoxDecoration(
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .secondaryBackground,
                                                      ),
                                                    ),
                                                    Text(
                                                      '5',
                                                      style: FlutterFlowTheme
                                                              .of(context)
                                                          .bodyMedium
                                                          .override(
                                                            font: GoogleFonts
                                                                .inter(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              fontStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                            ),
                                                            fontSize: 24.0,
                                                            letterSpacing: 0.0,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 10.0, 0.0, 0.0),
                                                  child: Text(
                                                    'Enter the name of your asset eg: Kenworth C500, Tank 301',
                                                    style: FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 10.0, 0.0, 0.0),
                                                  child: FlutterFlowDropDown<
                                                      String>(
                                                    controller: _model
                                                            .categoryValueController ??=
                                                        FormFieldController<
                                                            String>(
                                                      _model.categoryValue ??=
                                                          widget!.assetRow
                                                              ?.category,
                                                    ),
                                                    options: List<String>.from([
                                                      'vehicle',
                                                      'trailer',
                                                      'heavy_equipment',
                                                      'access_equipment',
                                                      'power_equipment',
                                                      'fluid_handling',
                                                      'safety_equipment',
                                                      'other'
                                                    ]),
                                                    optionLabels: [
                                                      'Vehicle (Trucks/Vans/Pickups)',
                                                      'Trailer (Flatbed/Lowboy)',
                                                      'Heavy Equipment (Excavators/Loaders/Dozers)',
                                                      'Access Equipment (Scissor/Boom Lifts)',
                                                      'Power Equipment (Generators/Compressors)',
                                                      'Fluid Handling (Pumps/Tanks)',
                                                      'Safety Equipment (Extinguishers/Ladders)',
                                                      'Other'
                                                    ],
                                                    onChanged: (val) async {
                                                      safeSetState(() => _model
                                                          .categoryValue = val);
                                                      _model.fldValidationResult =
                                                          functions.validateField(
                                                              _model
                                                                  .categoryValue,
                                                              'text',
                                                              true,
                                                              'Category',
                                                              null,
                                                              null,
                                                              null,
                                                              null,
                                                              null,
                                                              null,
                                                              null);
                                                      safeSetState(() {});
                                                      _model.categoryState =
                                                          getJsonField(
                                                        _model
                                                            .fldValidationResult,
                                                        r'''$.valid''',
                                                      );
                                                      safeSetState(() {});
                                                      if (_model
                                                          .categoryState) {
                                                        _model.categoryErrMsg =
                                                            null;
                                                        safeSetState(() {});
                                                        if ((_model.assetNameState == true) &&
                                                            (_model.makeState ==
                                                                true) &&
                                                            (_model.modelState ==
                                                                true) &&
                                                            (_model.categoryState ==
                                                                true) &&
                                                            (_model.selectedForms
                                                                    .length >
                                                                0)) {
                                                          _model.isFormValidationOk =
                                                              true;
                                                          safeSetState(() {});
                                                        } else {
                                                          _model.isFormValidationOk =
                                                              false;
                                                          safeSetState(() {});
                                                        }
                                                      } else {
                                                        _model.categoryErrMsg =
                                                            getJsonField(
                                                          _model
                                                              .fldValidationResult,
                                                          r'''$.error''',
                                                        ).toString();
                                                        safeSetState(() {});
                                                        _model.isFormValidationOk =
                                                            false;
                                                        safeSetState(() {});
                                                      }
                                                    },
                                                    width: double.infinity,
                                                    height: 50.0,
                                                    textStyle: FlutterFlowTheme
                                                            .of(context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          fontSize: 16.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                    hintText: 'Select...',
                                                    icon: Icon(
                                                      Icons
                                                          .keyboard_arrow_down_rounded,
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .secondaryText,
                                                      size: 24.0,
                                                    ),
                                                    fillColor:
                                                        FlutterFlowTheme.of(
                                                                context)
                                                            .primaryBackground,
                                                    elevation: 2.0,
                                                    borderColor:
                                                        _model.categoryErrMsg !=
                                                                    null &&
                                                                _model.categoryErrMsg !=
                                                                    ''
                                                            ? FlutterFlowTheme
                                                                    .of(context)
                                                                .customRedDark
                                                            : Color(0x00000000),
                                                    borderWidth: 0.0,
                                                    borderRadius: 8.0,
                                                    margin:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(12.0, 0.0,
                                                                12.0, 0.0),
                                                    hidesUnderline: true,
                                                    isOverButton: false,
                                                    isSearchable: false,
                                                    isMultiSelect: false,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ].addToEnd(SizedBox(height: 100.0)),
                                    ),
                                  ),
                                ),
                              ),
                              KeepAliveWidgetWrapper(
                                builder: (context) => SingleChildScrollView(
                                  primary: false,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    children: [
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 25.0, 0.0, 0.0),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.max,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            if (_model.selectedForms.length > 0)
                                              Text(
                                                '${_model.selectedForms.length.toString()} ${_model.selectedForms.length > 1 ? 'forms' : 'form'} selected',
                                                style:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyMedium
                                                        .override(
                                                          font:
                                                              GoogleFonts.inter(
                                                            fontWeight:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontWeight,
                                                            fontStyle:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .bodyMedium
                                                                    .fontStyle,
                                                          ),
                                                          fontSize: 16.0,
                                                          letterSpacing: 0.0,
                                                          fontWeight:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontWeight,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                              ),
                                            if (_model.selectedForms.length > 0)
                                              Builder(
                                                builder: (context) => InkWell(
                                                  splashColor:
                                                      Colors.transparent,
                                                  focusColor:
                                                      Colors.transparent,
                                                  hoverColor:
                                                      Colors.transparent,
                                                  highlightColor:
                                                      Colors.transparent,
                                                  onTap: () async {
                                                    await showDialog(
                                                      context: context,
                                                      builder: (dialogContext) {
                                                        return Dialog(
                                                          elevation: 0,
                                                          insetPadding:
                                                              EdgeInsets.zero,
                                                          backgroundColor:
                                                              Colors
                                                                  .transparent,
                                                          alignment: AlignmentDirectional(
                                                                  0.0, 0.0)
                                                              .resolve(
                                                                  Directionality.of(
                                                                      context)),
                                                          child: WebViewAware(
                                                            child:
                                                                GestureDetector(
                                                              onTap: () {
                                                                FocusScope.of(
                                                                        dialogContext)
                                                                    .unfocus();
                                                                FocusManager
                                                                    .instance
                                                                    .primaryFocus
                                                                    ?.unfocus();
                                                              },
                                                              child:
                                                                  CustomConfirmDialogWidget(
                                                                themeColor: FlutterFlowTheme.of(
                                                                        context)
                                                                    .customRedDark,
                                                                title: _model
                                                                            .formIdsToDelete
                                                                            .length >
                                                                        0
                                                                    ? 'Remove selected Inspection Forms?'
                                                                    : 'Remove all Inspection Forms?',
                                                                body: _model.formIdsToDelete
                                                                            .length >
                                                                        0
                                                                    ? 'Are you sure you want to remove the selected inspection forms from the asset? You can add it again later if needed.'
                                                                    : 'Are you sure you want to remove all inspection forms from the asset? You can add it again later if needed.',
                                                                icon: Icon(
                                                                  Icons
                                                                      .info_outline,
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .customRedDark,
                                                                  size: 60.0,
                                                                ),
                                                                onConfirm:
                                                                    () async {
                                                                  Navigator.pop(
                                                                      context);
                                                                  _model.deleteFormsFromAssetResponse =
                                                                      await actions
                                                                          .deleteAllFormsFromAsset(
                                                                    widget!
                                                                        .assetRow!
                                                                        .id,
                                                                    _model
                                                                        .formIdsToDelete
                                                                        .toList(),
                                                                  );
                                                                  _model.actionSuccess =
                                                                      getJsonField(
                                                                    _model
                                                                        .deleteFormsFromAssetResponse,
                                                                    r'''$.success''',
                                                                  );
                                                                  _model.errorCode =
                                                                      getJsonField(
                                                                    _model
                                                                        .deleteFormsFromAssetResponse,
                                                                    r'''$.status''',
                                                                  );
                                                                  _model.errorMsg =
                                                                      getJsonField(
                                                                    _model
                                                                        .deleteFormsFromAssetResponse,
                                                                    r'''$.error''',
                                                                  ).toString();
                                                                  _model.formsCurrentlyDeletedCnt =
                                                                      getJsonField(
                                                                    _model
                                                                        .deleteFormsFromAssetResponse,
                                                                    r'''$.deletedCount''',
                                                                  );
                                                                  safeSetState(
                                                                      () {});
                                                                  if (_model
                                                                      .actionSuccess) {
                                                                    await actions
                                                                        .triggerSnackbar(
                                                                      '${_model.formsCurrentlyDeletedCnt.toString()}  associated  Inspection  ${_model.formsCurrentlyDeletedCnt > 1 ? 'Forms' : 'Form'} deleted.',
                                                                      2500,
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .customGreenDark,
                                                                      FlutterFlowTheme.of(
                                                                              context)
                                                                          .secondaryBackground,
                                                                    );
                                                                    if (_model
                                                                            .formIdsToDelete
                                                                            .length >
                                                                        0) {
                                                                      for (int loop1Index =
                                                                              0;
                                                                          loop1Index <
                                                                              getJsonField(
                                                                                _model.deleteFormsFromAssetResponse,
                                                                                r'''$.data''',
                                                                                true,
                                                                              )!
                                                                                  .length;
                                                                          loop1Index++) {
                                                                        final currentLoop1Item =
                                                                            getJsonField(
                                                                          _model
                                                                              .deleteFormsFromAssetResponse,
                                                                          r'''$.data''',
                                                                          true,
                                                                        )![loop1Index];
                                                                        _model.removeFromSelectedFormIds(
                                                                            getJsonField(
                                                                          currentLoop1Item,
                                                                          r'''$.inspection_template_id''',
                                                                        ).toString());
                                                                        safeSetState(
                                                                            () {});
                                                                      }
                                                                      _model.selectedForms = functions
                                                                          .removeDeletedForms(
                                                                              _model.selectedForms.toList(),
                                                                              getJsonField(
                                                                                _model.deleteFormsFromAssetResponse,
                                                                                r'''$.data''',
                                                                                true,
                                                                              )!)
                                                                          .toList()
                                                                          .cast<dynamic>();
                                                                      safeSetState(
                                                                          () {});
                                                                    } else {
                                                                      _model.selectedFormIds =
                                                                          [];
                                                                      _model.selectedForms =
                                                                          [];
                                                                      safeSetState(
                                                                          () {});
                                                                    }
                                                                  } else {
                                                                    await showDialog(
                                                                      context:
                                                                          context,
                                                                      builder:
                                                                          (dialogContext) {
                                                                        return Dialog(
                                                                          elevation:
                                                                              0,
                                                                          insetPadding:
                                                                              EdgeInsets.zero,
                                                                          backgroundColor:
                                                                              Colors.transparent,
                                                                          alignment:
                                                                              AlignmentDirectional(0.0, 0.0).resolve(Directionality.of(context)),
                                                                          child:
                                                                              WebViewAware(
                                                                            child:
                                                                                GestureDetector(
                                                                              onTap: () {
                                                                                FocusScope.of(dialogContext).unfocus();
                                                                                FocusManager.instance.primaryFocus?.unfocus();
                                                                              },
                                                                              child: CustomMessageDialogWidget(
                                                                                themeColor: FlutterFlowTheme.of(context).customRedDark,
                                                                                title: 'Unable to delete all associated inspection forms.',
                                                                                body: 'An unexpected error occurred while deleting all associated Inspection Forms. Please try again or contact support.',
                                                                                icon: Icon(
                                                                                  Icons.info_outline,
                                                                                  color: FlutterFlowTheme.of(context).customRedDark,
                                                                                  size: 60.0,
                                                                                ),
                                                                                onConfirm: () async {
                                                                                  Navigator.pop(context);
                                                                                },
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        );
                                                                      },
                                                                    );
                                                                  }

                                                                  if ((_model.assetNameState == true) &&
                                                                      (_model.modelState ==
                                                                          true) &&
                                                                      (_model.makeState ==
                                                                          true) &&
                                                                      (_model.categoryState ==
                                                                          true) &&
                                                                      (_model.selectedForms
                                                                              .length >
                                                                          0)) {
                                                                    _model.isFormValidationOk =
                                                                        true;
                                                                    safeSetState(
                                                                        () {});
                                                                  } else {
                                                                    _model.isFormValidationOk =
                                                                        false;
                                                                    safeSetState(
                                                                        () {});
                                                                  }

                                                                  _model.formIdsToDelete =
                                                                      [];
                                                                  safeSetState(
                                                                      () {});
                                                                },
                                                              ),
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                    );

                                                    safeSetState(() {});
                                                  },
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.max,
                                                    children: [
                                                      Padding(
                                                        padding:
                                                            EdgeInsetsDirectional
                                                                .fromSTEB(
                                                                    0.0,
                                                                    0.0,
                                                                    5.0,
                                                                    0.0),
                                                        child: FaIcon(
                                                          FontAwesomeIcons
                                                              .trashAlt,
                                                          color: FlutterFlowTheme
                                                                  .of(context)
                                                              .customRedDark,
                                                          size: 16.0,
                                                        ),
                                                      ),
                                                      Text(
                                                        _model.formIdsToDelete
                                                                    .length >
                                                                0
                                                            ? 'Delete Selected'
                                                            : 'Delete All',
                                                        style:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .override(
                                                                  font:
                                                                      GoogleFonts
                                                                          .inter(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w500,
                                                                    fontStyle: FlutterFlowTheme.of(
                                                                            context)
                                                                        .bodyMedium
                                                                        .fontStyle,
                                                                  ),
                                                                  color: FlutterFlowTheme.of(
                                                                          context)
                                                                      .customRedDark,
                                                                  fontSize:
                                                                      16.0,
                                                                  letterSpacing:
                                                                      0.0,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  fontStyle: FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                                ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Padding(
                                        padding: EdgeInsetsDirectional.fromSTEB(
                                            0.0, 20.0, 0.0, 0.0),
                                        child: Container(
                                          constraints: BoxConstraints(
                                            minHeight:
                                                MediaQuery.sizeOf(context)
                                                        .height *
                                                    0.52,
                                            maxHeight:
                                                MediaQuery.sizeOf(context)
                                                        .height *
                                                    0.52,
                                          ),
                                          decoration: BoxDecoration(
                                            color: FlutterFlowTheme.of(context)
                                                .secondaryBackground,
                                          ),
                                          child: Builder(
                                            builder: (context) {
                                              final selectedFormsListView =
                                                  _model.selectedForms
                                                      .map((e) => getJsonField(
                                                            e,
                                                            r'''$''',
                                                          ))
                                                      .toList();
                                              if (selectedFormsListView
                                                  .isEmpty) {
                                                return EmptyListWidget(
                                                  icon: Icon(
                                                    Icons.description_outlined,
                                                    color: Color(0xFF94A3B8),
                                                    size: 40.0,
                                                  ),
                                                  title: 'No Forms Selected',
                                                  body:
                                                      'Select inspection forms that will be available for this asset',
                                                );
                                              }

                                              return ListView.builder(
                                                padding: EdgeInsets.zero,
                                                shrinkWrap: true,
                                                scrollDirection: Axis.vertical,
                                                itemCount: selectedFormsListView
                                                    .length,
                                                itemBuilder: (context,
                                                    selectedFormsListViewIndex) {
                                                  final selectedFormsListViewItem =
                                                      selectedFormsListView[
                                                          selectedFormsListViewIndex];
                                                  return Padding(
                                                    padding:
                                                        EdgeInsetsDirectional
                                                            .fromSTEB(0.0, 0.0,
                                                                0.0, 10.0),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: FlutterFlowTheme
                                                                .of(context)
                                                            .secondaryBackground,
                                                      ),
                                                      child: Column(
                                                        mainAxisSize:
                                                            MainAxisSize.max,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                EdgeInsetsDirectional
                                                                    .fromSTEB(
                                                                        10.0,
                                                                        10.0,
                                                                        10.0,
                                                                        10.0),
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(),
                                                              child: Row(
                                                                mainAxisSize:
                                                                    MainAxisSize
                                                                        .max,
                                                                children: [
                                                                  Expanded(
                                                                    child:
                                                                        Container(
                                                                      decoration:
                                                                          BoxDecoration(
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .secondaryBackground,
                                                                      ),
                                                                      child:
                                                                          Row(
                                                                        mainAxisSize:
                                                                            MainAxisSize.max,
                                                                        children: [
                                                                          Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                0.0,
                                                                                0.0,
                                                                                5.0,
                                                                                0.0),
                                                                            child:
                                                                                Theme(
                                                                              data: ThemeData(
                                                                                checkboxTheme: CheckboxThemeData(
                                                                                  visualDensity: VisualDensity.compact,
                                                                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                                                  shape: RoundedRectangleBorder(
                                                                                    borderRadius: BorderRadius.circular(4.0),
                                                                                  ),
                                                                                ),
                                                                                unselectedWidgetColor: FlutterFlowTheme.of(context).alternate,
                                                                              ),
                                                                              child: Checkbox(
                                                                                value: _model.checkboxValueMap[selectedFormsListViewItem] ??= false,
                                                                                onChanged: (newValue) async {
                                                                                  safeSetState(() => _model.checkboxValueMap[selectedFormsListViewItem] = newValue!);
                                                                                  if (newValue!) {
                                                                                    _model.addToFormIdsToDelete(getJsonField(
                                                                                      selectedFormsListViewItem,
                                                                                      r'''$.id''',
                                                                                    ).toString());
                                                                                    safeSetState(() {});
                                                                                  } else {
                                                                                    _model.removeFromFormIdsToDelete(getJsonField(
                                                                                      selectedFormsListViewItem,
                                                                                      r'''$.id''',
                                                                                    ).toString());
                                                                                    safeSetState(() {});
                                                                                  }
                                                                                },
                                                                                side: (FlutterFlowTheme.of(context).alternate != null)
                                                                                    ? BorderSide(
                                                                                        width: 2,
                                                                                        color: FlutterFlowTheme.of(context).alternate!,
                                                                                      )
                                                                                    : null,
                                                                                activeColor: FlutterFlowTheme.of(context).primary,
                                                                                checkColor: FlutterFlowTheme.of(context).info,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                          Padding(
                                                                            padding: EdgeInsetsDirectional.fromSTEB(
                                                                                0.0,
                                                                                0.0,
                                                                                10.0,
                                                                                0.0),
                                                                            child:
                                                                                Icon(
                                                                              Icons.library_books_outlined,
                                                                              color: FlutterFlowTheme.of(context).primaryText,
                                                                              size: 24.0,
                                                                            ),
                                                                          ),
                                                                          Expanded(
                                                                            child:
                                                                                Column(
                                                                              mainAxisSize: MainAxisSize.max,
                                                                              crossAxisAlignment: CrossAxisAlignment.start,
                                                                              children: [
                                                                                Text(
                                                                                  valueOrDefault<String>(
                                                                                    getJsonField(
                                                                                      selectedFormsListViewItem,
                                                                                      r'''$.name''',
                                                                                    )?.toString(),
                                                                                    'no name',
                                                                                  ),
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
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
                                                                                    selectedFormsListViewItem,
                                                                                    r'''$.creator_first_name''',
                                                                                  ).toString()} ${getJsonField(
                                                                                    selectedFormsListViewItem,
                                                                                    r'''$.creator_last_name''',
                                                                                  ).toString()} | ${functions.formatDate(getJsonField(
                                                                                    selectedFormsListViewItem,
                                                                                    r'''$.created_at''',
                                                                                  ).toString())}',
                                                                                  maxLines: 2,
                                                                                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                                                                                        font: GoogleFonts.inter(
                                                                                          fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                          fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                        ),
                                                                                        fontSize: 10.0,
                                                                                        letterSpacing: 0.0,
                                                                                        fontWeight: FlutterFlowTheme.of(context).bodyMedium.fontWeight,
                                                                                        fontStyle: FlutterFlowTheme.of(context).bodyMedium.fontStyle,
                                                                                      ),
                                                                                  overflow: TextOverflow.ellipsis,
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
                                                                            FlutterFlowIconButton(
                                                                      borderRadius:
                                                                          8.0,
                                                                      buttonSize:
                                                                          40.0,
                                                                      fillColor:
                                                                          Color(
                                                                              0xFFFEE2E2),
                                                                      icon:
                                                                          FaIcon(
                                                                        FontAwesomeIcons
                                                                            .trashAlt,
                                                                        color: FlutterFlowTheme.of(context)
                                                                            .customRedDark,
                                                                        size:
                                                                            24.0,
                                                                      ),
                                                                      onPressed:
                                                                          () async {
                                                                        await showDialog(
                                                                          context:
                                                                              context,
                                                                          builder:
                                                                              (dialogContext) {
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
                                                                                    themeColor: FlutterFlowTheme.of(context).customRedDark,
                                                                                    title: 'Remove Inspection Form?',
                                                                                    body: 'Are you sure you want to remove this form from the asset? You can add it again later if needed.',
                                                                                    icon: Icon(
                                                                                      Icons.info_outlined,
                                                                                      color: FlutterFlowTheme.of(context).customRedDark,
                                                                                      size: 60.0,
                                                                                    ),
                                                                                    onConfirm: () async {
                                                                                      Navigator.pop(context);
                                                                                      _model.deleteAsstFormsResponse = await actions.deleteAssetForms(
                                                                                        widget!.assetRow!.id,
                                                                                        getJsonField(
                                                                                          selectedFormsListViewItem,
                                                                                          r'''$.id''',
                                                                                        ).toString(),
                                                                                      );
                                                                                      _model.actionSuccess = getJsonField(
                                                                                        _model.deleteAsstFormsResponse,
                                                                                        r'''$.success''',
                                                                                      );
                                                                                      _model.errorCode = getJsonField(
                                                                                        _model.deleteAsstFormsResponse,
                                                                                        r'''$.status''',
                                                                                      );
                                                                                      _model.errorMsg = getJsonField(
                                                                                        _model.deleteAsstFormsResponse,
                                                                                        r'''$.error''',
                                                                                      ).toString();
                                                                                      safeSetState(() {});
                                                                                      if (_model.actionSuccess == true) {
                                                                                        await actions.triggerSnackbar(
                                                                                          'Inspection Form Removed.',
                                                                                          2600,
                                                                                          FlutterFlowTheme.of(context).customGreenDark,
                                                                                          FlutterFlowTheme.of(context).secondaryBackground,
                                                                                        );
                                                                                        _model.removeFromSelectedFormIds(getJsonField(
                                                                                          selectedFormsListViewItem,
                                                                                          r'''$.id''',
                                                                                        ).toString());
                                                                                        _model.removeFromSelectedForms(selectedFormsListViewItem);
                                                                                        safeSetState(() {});
                                                                                      } else {
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
                                                                                                  child: CustomMessageDialogWidget(
                                                                                                    themeColor: FlutterFlowTheme.of(context).customRedDark,
                                                                                                    title: 'Couldn’t Remove Inspection Form',
                                                                                                    body: 'An unexpected error occurred while trying to remove form. Please try again or contact support.',
                                                                                                    icon: Icon(
                                                                                                      Icons.info_outline,
                                                                                                      color: FlutterFlowTheme.of(context).customRedDark,
                                                                                                      size: 60.0,
                                                                                                    ),
                                                                                                    onConfirm: () async {
                                                                                                      Navigator.pop(context);
                                                                                                    },
                                                                                                  ),
                                                                                                ),
                                                                                              ),
                                                                                            );
                                                                                          },
                                                                                        );
                                                                                      }

                                                                                      if ((_model.assetNameState == true) && (_model.makeState == true) && (_model.modelState == true) && (_model.categoryState == true) && (_model.selectedForms.length > 0)) {
                                                                                        _model.isFormValidationOk = true;
                                                                                        safeSetState(() {});
                                                                                      } else {
                                                                                        _model.isFormValidationOk = false;
                                                                                        safeSetState(() {});
                                                                                      }
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
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          Divider(
                                                            thickness: 1.0,
                                                            color: Color(
                                                                0xFFDEDEDE),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      Builder(
                                        builder: (context) => Padding(
                                          padding:
                                              EdgeInsetsDirectional.fromSTEB(
                                                  0.0, 25.0, 0.0, 0.0),
                                          child: InkWell(
                                            splashColor: Colors.transparent,
                                            focusColor: Colors.transparent,
                                            hoverColor: Colors.transparent,
                                            highlightColor: Colors.transparent,
                                            onTap: () async {
                                              await showModalBottomSheet(
                                                isScrollControlled: true,
                                                backgroundColor:
                                                    Colors.transparent,
                                                context: context,
                                                builder: (context) {
                                                  return WebViewAware(
                                                    child: GestureDetector(
                                                      onTap: () {
                                                        FocusScope.of(context)
                                                            .unfocus();
                                                        FocusManager.instance
                                                            .primaryFocus
                                                            ?.unfocus();
                                                      },
                                                      child: Padding(
                                                        padding: MediaQuery
                                                            .viewInsetsOf(
                                                                context),
                                                        child: Container(
                                                          height:
                                                              MediaQuery.sizeOf(
                                                                          context)
                                                                      .height *
                                                                  0.7,
                                                          child:
                                                              BottomSheetAddFormsToAssetWidget(
                                                            initialSelectedIds:
                                                                _model
                                                                    .selectedFormIds,
                                                            onConfirm: (selectedIds,
                                                                selectedForms) async {
                                                              Navigator.pop(
                                                                  context);
                                                              _model.addFormsToAssetResponse =
                                                                  await actions
                                                                      .addFormsToAsset(
                                                                widget!
                                                                    .assetRow!
                                                                    .id,
                                                                selectedIds
                                                                    .toList(),
                                                              );
                                                              _model.actionSuccess =
                                                                  getJsonField(
                                                                _model
                                                                    .addFormsToAssetResponse,
                                                                r'''$.success''',
                                                              );
                                                              _model.errorCode =
                                                                  getJsonField(
                                                                _model
                                                                    .addFormsToAssetResponse,
                                                                r'''$.status''',
                                                              );
                                                              _model.errorMsg =
                                                                  getJsonField(
                                                                _model
                                                                    .addFormsToAssetResponse,
                                                                r'''$.error''',
                                                              ).toString();
                                                              _model.formsCurrentlyAdded =
                                                                  getJsonField(
                                                                _model
                                                                    .addFormsToAssetResponse,
                                                                r'''$.data''',
                                                                true,
                                                              )!
                                                                      .toList()
                                                                      .cast<
                                                                          dynamic>();
                                                              safeSetState(
                                                                  () {});
                                                              if (_model
                                                                  .actionSuccess) {
                                                                if (_model
                                                                        .formsCurrentlyAdded
                                                                        .length >
                                                                    0) {
                                                                  await actions
                                                                      .triggerSnackbar(
                                                                    '${_model.formsCurrentlyAdded.length.toString()} Inspection ${_model.formsCurrentlyAdded.length > 1 ? 'Forms' : 'Form'} added successfully',
                                                                    2500,
                                                                    FlutterFlowTheme.of(
                                                                            context)
                                                                        .customGreenDark,
                                                                    FlutterFlowTheme.of(
                                                                            context)
                                                                        .secondaryBackground,
                                                                  );
                                                                  _model.selectedFormIds = functions
                                                                      .mergeFormIds(
                                                                          _model
                                                                              .selectedFormIds
                                                                              .toList(),
                                                                          selectedIds
                                                                              .toList())
                                                                      .toList()
                                                                      .cast<
                                                                          String>();
                                                                  _model.selectedForms = functions
                                                                      .mergeFormObjects(
                                                                          _model
                                                                              .selectedForms
                                                                              .toList(),
                                                                          selectedForms
                                                                              .toList())
                                                                      .toList()
                                                                      .cast<
                                                                          dynamic>();
                                                                  safeSetState(
                                                                      () {});
                                                                }
                                                              } else {
                                                                await showDialog(
                                                                  context:
                                                                      context,
                                                                  builder:
                                                                      (dialogContext) {
                                                                    return Dialog(
                                                                      elevation:
                                                                          0,
                                                                      insetPadding:
                                                                          EdgeInsets
                                                                              .zero,
                                                                      backgroundColor:
                                                                          Colors
                                                                              .transparent,
                                                                      alignment: AlignmentDirectional(
                                                                              0.0,
                                                                              0.0)
                                                                          .resolve(
                                                                              Directionality.of(context)),
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
                                                                              CustomMessageDialogWidget(
                                                                            themeColor:
                                                                                FlutterFlowTheme.of(context).customRedDark,
                                                                            title:
                                                                                'Unable to add Inspection Form(s)',
                                                                            body:
                                                                                'An unexpected error occurred while adding Inspection Form(s). Please try again or contact support.',
                                                                            icon:
                                                                                Icon(
                                                                              Icons.info_outline,
                                                                              color: FlutterFlowTheme.of(context).customRedDark,
                                                                              size: 60.0,
                                                                            ),
                                                                            onConfirm:
                                                                                () async {
                                                                              Navigator.pop(context);
                                                                            },
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    );
                                                                  },
                                                                );
                                                              }

                                                              if ((_model.assetNameState == true) &&
                                                                  (_model.makeState ==
                                                                      true) &&
                                                                  (_model.modelState ==
                                                                      true) &&
                                                                  (_model.categoryState ==
                                                                      true) &&
                                                                  (_model.selectedForms
                                                                          .length >
                                                                      0)) {
                                                                _model.isFormValidationOk =
                                                                    true;
                                                                safeSetState(
                                                                    () {});
                                                              } else {
                                                                _model.isFormValidationOk =
                                                                    false;
                                                                safeSetState(
                                                                    () {});
                                                              }
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ).then((value) =>
                                                  safeSetState(() {}));

                                              safeSetState(() {});
                                            },
                                            child: Row(
                                              mainAxisSize: MainAxisSize.max,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 0.0, 10.0, 0.0),
                                                  child: FaIcon(
                                                    FontAwesomeIcons.plus,
                                                    color: FlutterFlowTheme.of(
                                                            context)
                                                        .primary,
                                                    size: 24.0,
                                                  ),
                                                ),
                                                Text(
                                                  'Select forms available for this asset',
                                                  style: FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .override(
                                                        font: GoogleFonts.inter(
                                                          fontWeight:
                                                              FontWeight.normal,
                                                          fontStyle:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .bodyMedium
                                                                  .fontStyle,
                                                        ),
                                                        color:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primary,
                                                        fontSize: 16.0,
                                                        letterSpacing: 0.0,
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .bodyMedium
                                                                .fontStyle,
                                                      ),
                                                ),
                                              ],
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
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional(0.0, 1.0),
                    child: Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 20.0, 0.0, 0.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Opacity(
                            opacity: _model.isFormValidationOk ? 1.0 : 0.5,
                            child: Builder(
                              builder: (context) => Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 10.0, 0.0),
                                child: FFButtonWidget(
                                  onPressed: (_model.isFormValidationOk
                                          ? false
                                          : true)
                                      ? null
                                      : () async {
                                          if (_model.uploadedLocalFile_uploadData5jf !=
                                                  null &&
                                              (_model.uploadedLocalFile_uploadData5jf
                                                      .bytes?.isNotEmpty ??
                                                  false)) {
                                            {
                                              safeSetState(() => _model
                                                      .isDataUploading_uploadDataNqy2 =
                                                  true);
                                              var selectedUploadedFiles =
                                                  <FFUploadedFile>[];
                                              var selectedMedia =
                                                  <SelectedFile>[];
                                              var downloadUrls = <String>[];
                                              try {
                                                selectedUploadedFiles = _model
                                                        .uploadedLocalFile_uploadData5jf
                                                        .bytes!
                                                        .isNotEmpty
                                                    ? [
                                                        _model
                                                            .uploadedLocalFile_uploadData5jf
                                                      ]
                                                    : <FFUploadedFile>[];
                                                selectedMedia =
                                                    selectedFilesFromUploadedFiles(
                                                  selectedUploadedFiles,
                                                  storageFolderPath: 'pics',
                                                );
                                                downloadUrls =
                                                    await uploadSupabaseStorageFiles(
                                                  bucketName: 'asset_pics',
                                                  selectedFiles: selectedMedia,
                                                );
                                              } finally {
                                                _model.isDataUploading_uploadDataNqy2 =
                                                    false;
                                              }
                                              if (selectedUploadedFiles
                                                          .length ==
                                                      selectedMedia.length &&
                                                  downloadUrls.length ==
                                                      selectedMedia.length) {
                                                safeSetState(() {
                                                  _model.uploadedLocalFile_uploadDataNqy2 =
                                                      selectedUploadedFiles
                                                          .first;
                                                  _model.uploadedFileUrl_uploadDataNqy2 =
                                                      downloadUrls.first;
                                                });
                                              } else {
                                                safeSetState(() {});
                                                return;
                                              }
                                            }

                                            if (widget!.assetRow?.picUrl !=
                                                    null &&
                                                widget!.assetRow?.picUrl !=
                                                    '') {
                                              await deleteSupabaseFileFromPublicUrl(
                                                  widget!.assetRow!.picUrl!);
                                            }
                                            _model.updateResponseWithPhoto =
                                                await actions.upsertAsset(
                                              widget!.assetRow?.id,
                                              FFAppState().currentOrgId,
                                              _model
                                                  .assetNameTextController.text,
                                              _model.categoryValue!,
                                              _model.makeTextController.text,
                                              _model.modelTextController.text,
                                              _model.selectedFormIds.toList(),
                                              _model
                                                  .uploadedFileUrl_uploadDataNqy2,
                                            );
                                            _model.actionSuccess = getJsonField(
                                              _model.updateResponseWithPhoto,
                                              r'''$.success''',
                                            );
                                            _model.errorCode = getJsonField(
                                              _model.updateResponseWithPhoto,
                                              r'''$.status''',
                                            );
                                            _model.errorMsg = getJsonField(
                                              _model.updateResponseWithPhoto,
                                              r'''$.error''',
                                            ).toString();
                                            safeSetState(() {});
                                            if (_model.actionSuccess == true) {
                                              await showDialog(
                                                barrierDismissible: false,
                                                context: context,
                                                builder: (dialogContext) {
                                                  return Dialog(
                                                    elevation: 0,
                                                    insetPadding:
                                                        EdgeInsets.zero,
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    alignment:
                                                        AlignmentDirectional(
                                                                0.0, 0.0)
                                                            .resolve(
                                                                Directionality.of(
                                                                    context)),
                                                    child: WebViewAware(
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          FocusScope.of(
                                                                  dialogContext)
                                                              .unfocus();
                                                          FocusManager.instance
                                                              .primaryFocus
                                                              ?.unfocus();
                                                        },
                                                        child:
                                                            CustomMessageDialogWidget(
                                                          themeColor:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .customGreenDark,
                                                          title: 'Asset Saved!',
                                                          body:
                                                              'Your asset was successfully created.',
                                                          icon: FaIcon(
                                                            FontAwesomeIcons
                                                                .checkCircle,
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .customGreenDark,
                                                            size: 60.0,
                                                          ),
                                                          onConfirm: () async {
                                                            Navigator.pop(
                                                                context);
                                                            FFAppState()
                                                                .clearAssetDahbosrdCacheCache();
                                                            context.safePop();
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            } else {
                                              if (_model.errorCode == 409) {
                                                await deleteSupabaseFileFromPublicUrl(
                                                    _model
                                                        .uploadedFileUrl_uploadDataNqy2);
                                                await showDialog(
                                                  barrierDismissible: false,
                                                  context: context,
                                                  builder: (dialogContext) {
                                                    return Dialog(
                                                      elevation: 0,
                                                      insetPadding:
                                                          EdgeInsets.zero,
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      alignment:
                                                          AlignmentDirectional(
                                                                  0.0, 0.0)
                                                              .resolve(
                                                                  Directionality.of(
                                                                      context)),
                                                      child: WebViewAware(
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            FocusScope.of(
                                                                    dialogContext)
                                                                .unfocus();
                                                            FocusManager
                                                                .instance
                                                                .primaryFocus
                                                                ?.unfocus();
                                                          },
                                                          child:
                                                              CustomMessageDialogWidget(
                                                            themeColor:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .customRedDark,
                                                            title:
                                                                'Duplicate Asset Name',
                                                            body:
                                                                'Another asset in this organization already uses this name.',
                                                            icon: Icon(
                                                              Icons
                                                                  .info_outline,
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .customRedDark,
                                                              size: 60.0,
                                                            ),
                                                            onConfirm:
                                                                () async {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              } else {
                                                await deleteSupabaseFileFromPublicUrl(
                                                    _model
                                                        .uploadedFileUrl_uploadDataNqy2);
                                                await showDialog(
                                                  barrierDismissible: false,
                                                  context: context,
                                                  builder: (dialogContext) {
                                                    return Dialog(
                                                      elevation: 0,
                                                      insetPadding:
                                                          EdgeInsets.zero,
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      alignment:
                                                          AlignmentDirectional(
                                                                  0.0, 0.0)
                                                              .resolve(
                                                                  Directionality.of(
                                                                      context)),
                                                      child: WebViewAware(
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            FocusScope.of(
                                                                    dialogContext)
                                                                .unfocus();
                                                            FocusManager
                                                                .instance
                                                                .primaryFocus
                                                                ?.unfocus();
                                                          },
                                                          child:
                                                              CustomMessageDialogWidget(
                                                            themeColor:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .customRedDark,
                                                            title:
                                                                'Unable to Save Asset',
                                                            body:
                                                                'An unexpected error occurred while saving the asset. Please try again or contact support',
                                                            icon: Icon(
                                                              Icons
                                                                  .info_outline,
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .customRedDark,
                                                              size: 60.0,
                                                            ),
                                                            onConfirm:
                                                                () async {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              }
                                            }
                                          } else {
                                            await AssetsTable().update(
                                              data: {
                                                'name': _model
                                                    .assetNameTextController
                                                    .text,
                                                'category':
                                                    _model.categoryValue,
                                                'make': _model
                                                    .makeTextController.text,
                                                'model': _model
                                                    .modelTextController.text,
                                              },
                                              matchingRows: (rows) =>
                                                  rows.eqOrNull(
                                                'id',
                                                widget!.assetRow?.id,
                                              ),
                                            );
                                            _model.updateResponse =
                                                await actions.upsertAsset(
                                              widget!.assetRow?.id,
                                              FFAppState().currentOrgId,
                                              _model
                                                  .assetNameTextController.text,
                                              _model.categoryValue!,
                                              _model.makeTextController.text,
                                              _model.modelTextController.text,
                                              _model.selectedFormIds.toList(),
                                              widget!.assetRow?.picUrl,
                                            );
                                            _model.actionSuccess = getJsonField(
                                              _model.updateResponse,
                                              r'''$.success''',
                                            );
                                            _model.errorCode = getJsonField(
                                              _model.updateResponse,
                                              r'''$.status''',
                                            );
                                            _model.errorMsg = getJsonField(
                                              _model.updateResponse,
                                              r'''$.error''',
                                            ).toString();
                                            safeSetState(() {});
                                            if (_model.actionSuccess == true) {
                                              await showDialog(
                                                barrierDismissible: false,
                                                context: context,
                                                builder: (dialogContext) {
                                                  return Dialog(
                                                    elevation: 0,
                                                    insetPadding:
                                                        EdgeInsets.zero,
                                                    backgroundColor:
                                                        Colors.transparent,
                                                    alignment:
                                                        AlignmentDirectional(
                                                                0.0, 0.0)
                                                            .resolve(
                                                                Directionality.of(
                                                                    context)),
                                                    child: WebViewAware(
                                                      child: GestureDetector(
                                                        onTap: () {
                                                          FocusScope.of(
                                                                  dialogContext)
                                                              .unfocus();
                                                          FocusManager.instance
                                                              .primaryFocus
                                                              ?.unfocus();
                                                        },
                                                        child:
                                                            CustomMessageDialogWidget(
                                                          themeColor:
                                                              FlutterFlowTheme.of(
                                                                      context)
                                                                  .customGreenDark,
                                                          title: 'Asset Saved!',
                                                          body:
                                                              'Your asset was successfully created.',
                                                          icon: FaIcon(
                                                            FontAwesomeIcons
                                                                .checkCircle,
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .customGreenDark,
                                                            size: 60.0,
                                                          ),
                                                          onConfirm: () async {
                                                            Navigator.pop(
                                                                context);
                                                            FFAppState()
                                                                .clearAssetDahbosrdCacheCache();
                                                            context.safePop();
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              );
                                            } else {
                                              if (_model.errorCode == 409) {
                                                await showDialog(
                                                  barrierDismissible: false,
                                                  context: context,
                                                  builder: (dialogContext) {
                                                    return Dialog(
                                                      elevation: 0,
                                                      insetPadding:
                                                          EdgeInsets.zero,
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      alignment:
                                                          AlignmentDirectional(
                                                                  0.0, 0.0)
                                                              .resolve(
                                                                  Directionality.of(
                                                                      context)),
                                                      child: WebViewAware(
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            FocusScope.of(
                                                                    dialogContext)
                                                                .unfocus();
                                                            FocusManager
                                                                .instance
                                                                .primaryFocus
                                                                ?.unfocus();
                                                          },
                                                          child:
                                                              CustomMessageDialogWidget(
                                                            themeColor:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .customRedDark,
                                                            title:
                                                                'Duplicate Asset Name',
                                                            body:
                                                                'Another asset in this organization already uses this name.',
                                                            icon: Icon(
                                                              Icons
                                                                  .info_outline,
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .customRedDark,
                                                              size: 60.0,
                                                            ),
                                                            onConfirm:
                                                                () async {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              } else {
                                                await showDialog(
                                                  barrierDismissible: false,
                                                  context: context,
                                                  builder: (dialogContext) {
                                                    return Dialog(
                                                      elevation: 0,
                                                      insetPadding:
                                                          EdgeInsets.zero,
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      alignment:
                                                          AlignmentDirectional(
                                                                  0.0, 0.0)
                                                              .resolve(
                                                                  Directionality.of(
                                                                      context)),
                                                      child: WebViewAware(
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            FocusScope.of(
                                                                    dialogContext)
                                                                .unfocus();
                                                            FocusManager
                                                                .instance
                                                                .primaryFocus
                                                                ?.unfocus();
                                                          },
                                                          child:
                                                              CustomMessageDialogWidget(
                                                            themeColor:
                                                                FlutterFlowTheme.of(
                                                                        context)
                                                                    .customRedDark,
                                                            title:
                                                                'Unable to Save Asset',
                                                            body:
                                                                'An unexpected error occurred while saving the asset. Please try again or contact support',
                                                            icon: Icon(
                                                              Icons
                                                                  .info_outline,
                                                              color: FlutterFlowTheme
                                                                      .of(context)
                                                                  .customRedDark,
                                                              size: 60.0,
                                                            ),
                                                            onConfirm:
                                                                () async {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                          ),
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              }
                                            }
                                          }

                                          safeSetState(() {});
                                        },
                                  text: 'Save',
                                  icon: FaIcon(
                                    FontAwesomeIcons.save,
                                    size: 24.0,
                                  ),
                                  options: FFButtonOptions(
                                    width: 140.0,
                                    height: 50.0,
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        16.0, 0.0, 16.0, 0.0),
                                    iconPadding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 0.0, 0.0, 0.0),
                                    color: FlutterFlowTheme.of(context).primary,
                                    textStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .override(
                                          font: GoogleFonts.inter(
                                            fontWeight: FontWeight.normal,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .titleSmall
                                                    .fontStyle,
                                          ),
                                          color: Colors.white,
                                          fontSize: 14.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.normal,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .titleSmall
                                                  .fontStyle,
                                        ),
                                    elevation: 0.0,
                                    borderRadius: BorderRadius.circular(500.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          FFButtonWidget(
                            onPressed: () async {
                              await deleteSupabaseFileFromPublicUrl(
                                  widget!.assetRow!.picUrl!);
                              await AssetsTable().delete(
                                matchingRows: (rows) => rows.eqOrNull(
                                  'id',
                                  widget!.assetRow?.id,
                                ),
                              );
                              context.safePop();
                            },
                            text: 'Remove',
                            icon: Icon(
                              Icons.delete_forever,
                              size: 24.0,
                            ),
                            options: FFButtonOptions(
                              width: 140.0,
                              height: 50.0,
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  16.0, 0.0, 16.0, 0.0),
                              iconPadding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 0.0),
                              color: FlutterFlowTheme.of(context).customRedDark,
                              textStyle: FlutterFlowTheme.of(context)
                                  .titleSmall
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .titleSmall
                                          .fontStyle,
                                    ),
                                    color: Colors.white,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .titleSmall
                                        .fontStyle,
                                  ),
                              elevation: 0.0,
                              borderRadius: BorderRadius.circular(500.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Align(
                    alignment: AlignmentDirectional(0.0, 1.0),
                    child: custom_widgets.Snackbar(
                      width: null,
                      height: null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
