import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'bottom_sheet_add_forms_to_asset_model.dart';
export 'bottom_sheet_add_forms_to_asset_model.dart';

class BottomSheetAddFormsToAssetWidget extends StatefulWidget {
  const BottomSheetAddFormsToAssetWidget({
    super.key,
    required this.initialSelectedIds,
    required this.onConfirm,
  });

  final List<String>? initialSelectedIds;
  final Future Function(List<String> selectedIds, List<dynamic> selectedForms)?
      onConfirm;

  @override
  State<BottomSheetAddFormsToAssetWidget> createState() =>
      _BottomSheetAddFormsToAssetWidgetState();
}

class _BottomSheetAddFormsToAssetWidgetState
    extends State<BottomSheetAddFormsToAssetWidget> {
  late BottomSheetAddFormsToAssetModel _model;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => BottomSheetAddFormsToAssetModel());

    // On component load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      _model.tempSelectedIds =
          widget!.initialSelectedIds!.toList().cast<String>();
      safeSetState(() {});
      await actions.refreshSupabaseSession();
      _model.apiResultgwb = await SearchInspectionFormTemplatesCall.call(
        pOrg: FFAppState().currentOrgId,
        pScope: _model.flitterTab,
        pQ: _model.searchTextFieldTextController.text,
        pLimit: _model.pageLimit,
        pOffset: _model.offset,
        pSortBy: 'created_at',
        pSortDir: 'desc',
        userAccessToken: FFAppState().userAccessToken,
      );

      if ((_model.apiResultgwb?.succeeded ?? true)) {
        _model.formsList = functions
            .decodeJsonList((_model.apiResultgwb?.bodyText ?? ''))
            .toList()
            .cast<dynamic>();
        safeSetState(() {});
      }
    });

    _model.switchValue = false;
    _model.searchTextFieldTextController ??= TextEditingController();
    _model.searchTextFieldFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FFAppState>();

    return FutureBuilder<ApiCallResponse>(
      future: SearchInspectionFormTemplatesCall.call(
        pOrg: FFAppState().currentOrgId,
        pScope: _model.flitterTab,
        pQ: _model.searchTextFieldTextController.text,
        pLimit: 25,
        pOffset: 0,
        pSortBy: 'created_at',
        pSortDir: 'desc',
        userAccessToken: FFAppState().userAccessToken,
      ),
      builder: (context, snapshot) {
        // Customize what your widget looks like when it's loading.
        if (!snapshot.hasData) {
          return Center(
            child: SizedBox(
              width: 50.0,
              height: 50.0,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  FlutterFlowTheme.of(context).primary,
                ),
              ),
            ),
          );
        }
        final containerSearchInspectionFormTemplatesResponse = snapshot.data!;

        return ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(0.0),
            bottomRight: Radius.circular(0.0),
            topLeft: Radius.circular(20.0),
            topRight: Radius.circular(20.0),
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(0.0),
                bottomRight: Radius.circular(0.0),
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: FlutterFlowTheme.of(context).primary,
                    ),
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          20.0, 20.0, 20.0, 10.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Align(
                            alignment: AlignmentDirectional(0.0, 0.0),
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 8.0, 0.0),
                              child: Icon(
                                Icons.library_books_outlined,
                                color: FlutterFlowTheme.of(context)
                                    .secondaryBackground,
                                size: 32.0,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Assign Forms',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: FlutterFlowTheme.of(context)
                                        .secondaryBackground,
                                    fontSize: 20.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                          ),
                          Text(
                            'Select All',
                            style: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .override(
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
                                ),
                          ),
                          Container(
                            decoration: BoxDecoration(),
                            child: Switch.adaptive(
                              value: _model.switchValue!,
                              onChanged: (newValue) async {
                                safeSetState(
                                    () => _model.switchValue = newValue!);
                                if (newValue!) {
                                  _model.isSelectAll = true;
                                  _model.isClearAll = false;
                                  safeSetState(() {});
                                } else {
                                  _model.isClearAll = true;
                                  _model.isSelectAll = false;
                                  safeSetState(() {});
                                }
                              },
                              activeColor:
                                  FlutterFlowTheme.of(context).darkThemeBlue,
                              activeTrackColor:
                                  FlutterFlowTheme.of(context).darkBorderColor,
                              inactiveTrackColor:
                                  FlutterFlowTheme.of(context).alternate,
                              inactiveThumbColor: FlutterFlowTheme.of(context)
                                  .secondaryBackground,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(25.0, 20.0, 25.0, 0.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 20.0, 0.0, 25.0),
                                  child: Container(
                                    width:
                                        MediaQuery.sizeOf(context).width * 3.45,
                                    child: TextFormField(
                                      controller:
                                          _model.searchTextFieldTextController,
                                      focusNode:
                                          _model.searchTextFieldFocusNode,
                                      onChanged: (_) => EasyDebounce.debounce(
                                        '_model.searchTextFieldTextController',
                                        Duration(milliseconds: 400),
                                        () async {
                                          await actions
                                              .refreshSupabaseSession();
                                          _model.apiResultz3s =
                                              await SearchInspectionFormTemplatesCall
                                                  .call(
                                            pOrg: FFAppState().currentOrgId,
                                            pScope: _model.flitterTab,
                                            pQ: _model
                                                .searchTextFieldTextController
                                                .text,
                                            pLimit: _model.pageLimit,
                                            pOffset: _model.offset,
                                            pSortBy: 'created_at',
                                            pSortDir: 'desc',
                                            userAccessToken:
                                                FFAppState().userAccessToken,
                                          );

                                          if ((_model.apiResultz3s?.succeeded ??
                                              true)) {
                                            _model.formsList = getJsonField(
                                              (_model.apiResultz3s?.jsonBody ??
                                                  ''),
                                              r'''$''',
                                              true,
                                            )!
                                                .toList()
                                                .cast<dynamic>();
                                            safeSetState(() {});
                                          }

                                          safeSetState(() {});
                                        },
                                      ),
                                      autofocus: false,
                                      autofillHints: [AutofillHints.name],
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      obscureText: false,
                                      decoration: InputDecoration(
                                        labelStyle: FlutterFlowTheme.of(context)
                                            .labelLarge
                                            .override(
                                              font: GoogleFonts.inter(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .labelLarge
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .labelLarge
                                                        .fontStyle,
                                              ),
                                              color:
                                                  FlutterFlowTheme.of(context)
                                                      .secondaryText,
                                              fontSize: 16.0,
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .labelLarge
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .labelLarge
                                                      .fontStyle,
                                            ),
                                        hintText: 'Search by name or category',
                                        hintStyle: FlutterFlowTheme.of(context)
                                            .bodyLarge
                                            .override(
                                              font: GoogleFonts.inter(
                                                fontWeight:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyLarge
                                                        .fontWeight,
                                                fontStyle:
                                                    FlutterFlowTheme.of(context)
                                                        .bodyLarge
                                                        .fontStyle,
                                              ),
                                              color: Color(0x661D354F),
                                              letterSpacing: 0.0,
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .fontStyle,
                                            ),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: FlutterFlowTheme.of(context)
                                                .primaryBackground,
                                            width: 2.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: FlutterFlowTheme.of(context)
                                                .primary,
                                            width: 2.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: FlutterFlowTheme.of(context)
                                                .alternate,
                                            width: 2.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                        focusedErrorBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                            color: FlutterFlowTheme.of(context)
                                                .alternate,
                                            width: 2.0,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                        filled: true,
                                        fillColor: FlutterFlowTheme.of(context)
                                            .primaryBackground,
                                        contentPadding:
                                            EdgeInsetsDirectional.fromSTEB(
                                                10.0, 0.0, 10.0, 0.0),
                                        suffixIcon: Icon(
                                          Icons.search_outlined,
                                          color: Color(0xFF757575),
                                          size: 22.0,
                                        ),
                                      ),
                                      style: FlutterFlowTheme.of(context)
                                          .bodyLarge
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyLarge
                                                      .fontStyle,
                                            ),
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyLarge
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyLarge
                                                    .fontStyle,
                                          ),
                                      validator: _model
                                          .searchTextFieldTextControllerValidator
                                          .asValidator(context),
                                      inputFormatters: [
                                        if (!isAndroid && !isiOS)
                                          TextInputFormatter.withFunction(
                                              (oldValue, newValue) {
                                            return TextEditingValue(
                                              selection: newValue.selection,
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
                          Container(
                            height: 275.0,
                            decoration: BoxDecoration(),
                            child: Container(
                              width: null,
                              height: null,
                              child: custom_widgets.SelectableFormsList(
                                width: null,
                                height: null,
                                selectAll: _model.isSelectAll,
                                clearAll: _model.isClearAll,
                                forms: _model.formsList,
                                selectedIds: _model.tempSelectedIds,
                                onChanged: (seletedIds) async {
                                  _model.tempSelectedIds =
                                      seletedIds.toList().cast<String>();
                                  safeSetState(() {});
                                },
                                onLoadMore: () async {
                                  if (_model.isLoadingMore == false) {
                                    _model.isLoadingMore = true;
                                    _model.offset = functions.addInts(
                                        _model.offset, _model.pageLimit)!;
                                    safeSetState(() {});
                                    await actions.refreshSupabaseSession();
                                    _model.apiResultLoadMore =
                                        await SearchInspectionFormTemplatesCall
                                            .call(
                                      pOrg: FFAppState().currentOrgId,
                                      pScope: _model.flitterTab,
                                      pQ: _model
                                          .searchTextFieldTextController.text,
                                      pLimit: _model.pageLimit,
                                      pOffset: _model.offset,
                                      pSortBy: 'created_at',
                                      pSortDir: 'desc',
                                      userAccessToken:
                                          FFAppState().userAccessToken,
                                    );

                                    if ((_model.apiResultLoadMore?.succeeded ??
                                        true)) {
                                      _model.tempDecodedList = functions
                                          .decodeJsonList((_model
                                                  .apiResultLoadMore
                                                  ?.bodyText ??
                                              ''))
                                          .toList()
                                          .cast<dynamic>();
                                      safeSetState(() {});
                                      for (int loop1Index = 0;
                                          loop1Index <
                                              _model.tempDecodedList.length;
                                          loop1Index++) {
                                        final currentLoop1Item =
                                            _model.tempDecodedList[loop1Index];
                                        _model.addToFormsList(currentLoop1Item);
                                        safeSetState(() {});
                                      }
                                      _model.isLoadingMore = false;
                                      safeSetState(() {});
                                    }
                                  }

                                  safeSetState(() {});
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                0.0, 25.0, 0.0, 25.0),
                            child: FFButtonWidget(
                              onPressed: () async {
                                _model.selecredFormsForReturn = functions
                                    .filterFormsByIds(_model.formsList.toList(),
                                        _model.tempSelectedIds.toList())
                                    .toList()
                                    .cast<dynamic>();
                                safeSetState(() {});
                                await widget.onConfirm?.call(
                                  _model.tempSelectedIds,
                                  _model.selecredFormsForReturn,
                                );
                              },
                              text: 'Assign Selected Forms',
                              options: FFButtonOptions(
                                height: 40.0,
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    16.0, 0.0, 16.0, 0.0),
                                iconPadding: EdgeInsetsDirectional.fromSTEB(
                                    0.0, 0.0, 0.0, 0.0),
                                color: FlutterFlowTheme.of(context).primary,
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
                                borderRadius: BorderRadius.circular(8.0),
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
          ),
        );
      },
    );
  }
}
