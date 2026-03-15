import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/option_row/option_row_widget.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '/features/inspection_form/inspection_item_types.dart';
import 'card_editor_sheet_model.dart';
export 'card_editor_sheet_model.dart';

class CardEditorSheetWidget extends StatefulWidget {
  const CardEditorSheetWidget({
    super.key,
    String? mode,
    required this.type,
    this.incomingItem,
    required this.index,
    required this.onSave,
  }) : this.mode = mode ?? 'create';

  final String mode;
  final String? type;
  final dynamic incomingItem;
  final int? index;
  final Future Function(dynamic card)? onSave;

  @override
  State<CardEditorSheetWidget> createState() => _CardEditorSheetWidgetState();
}

class _CardEditorSheetWidgetState extends State<CardEditorSheetWidget> {
  late CardEditorSheetModel _model;

  // Type-specific config controllers.
  // The model file is frozen so these live on the State class.
  late final TextEditingController _minCtrl;
  late final TextEditingController _maxCtrl;
  late final TextEditingController _placeholderCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _maxLengthCtrl;
  late final TextEditingController _regexCtrl;
  late final TextEditingController _minPhotosCtrl;
  late final TextEditingController _maxPhotosCtrl;
  bool _allowMultiple = false;
  bool _photoRequired = false;
  bool _isRequired = true;

  @override
  void setState(VoidCallback callback) {
    super.setState(callback);
    _model.onUpdate();
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CardEditorSheetModel());

    // On component load action.
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (widget!.mode == FFAppConstants.CREATEMODE) {
        _model.initUuid = await actions.generateUuidAction();
        _model.checksList = functions
            .makeInitialCheck(_model.initUuid!)
            .toList()
            .cast<dynamic>();
        safeSetState(() {});
      } else {
        // EDIT mode: multi-check reads checks; multiple-choice reads options.
        final configPath = widget!.type == 'multiple-choice'
            ? r'''$.config.options'''
            : r'''$.config.checks''';
        final raw = getJsonField(widget!.incomingItem, configPath, true);
        final rawList = (raw ?? []).toList().cast<dynamic>();
        // Ensure each entry has an id so OptionRowWidget can key itself.
        _model.checksList = rawList.asMap().entries.map((e) {
          final m = Map<String, dynamic>.from(e.value as Map);
          return <String, dynamic>{
            'id': m['id'] ?? e.key.toString(),
            'label': m['label'] ?? '',
            'type': 'checkbox',
            'photoRequired': m['photoRequired'] == true,
            'maxPhotos': (m['maxPhotos'] as num?)?.toInt().clamp(1, 5) ?? 5,
          };
        }).toList().cast<dynamic>();
        safeSetState(() {});
      }
    });

    _model.cardTitleTextController ??= TextEditingController(
        text: getJsonField(
                  widget!.incomingItem,
                  r'''$.label''',
                ) !=
                null
            ? getJsonField(
                widget!.incomingItem,
                r'''$.label''',
              ).toString()
            : '');
    _model.cardTitleFocusNode ??= FocusNode();

    // Initialise type-specific controllers.
    _minCtrl         = TextEditingController();
    _maxCtrl         = TextEditingController();
    _placeholderCtrl = TextEditingController();
    _unitCtrl        = TextEditingController();
    _noteCtrl        = TextEditingController();
    _maxLengthCtrl   = TextEditingController();
    _regexCtrl       = TextEditingController();
    _minPhotosCtrl   = TextEditingController();
    _maxPhotosCtrl   = TextEditingController();

    // Pre-populate from saved config on EDIT.
    if (widget.mode == FFAppConstants.EDITMODE && widget.incomingItem is Map) {
      final cfg = (widget.incomingItem as Map)['config'] as Map? ?? {};
      _minCtrl.text         = cfg['min']?.toString()      ?? '';
      _maxCtrl.text         = cfg['max']?.toString()      ?? '';
      _placeholderCtrl.text = cfg['placeholder']           ?? '';
      _unitCtrl.text        = cfg['unit']                  ?? '';
      _noteCtrl.text        = cfg['note']                  ?? '';
      _maxLengthCtrl.text   = cfg['maxLength']?.toString() ?? '';
      _regexCtrl.text       = cfg['formatPattern'] ?? cfg['regex'] ?? '';
      _minPhotosCtrl.text   = cfg['minPhotos']?.toString() ?? '';
      _maxPhotosCtrl.text   = cfg['maxPhotos']?.toString() ?? '';
      _allowMultiple        = cfg['allowMultiple'] == true;
      _photoRequired        = cfg['photoRequired'] == true;
      // For numeric and alphanumeric types, ocrEnabled is stored separately in config.
      final incomingType = (widget.incomingItem as Map)['type'] as String? ?? '';
      if (incomingType == 'numeric' || incomingType == 'alphanumeric' || incomingType == 'comment-box') {
        _photoRequired = cfg['ocrEnabled'] == true;
      }
      _isRequired = (widget.incomingItem as Map)['required'] ?? true;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.maybeDispose();
    _minCtrl.dispose();
    _maxCtrl.dispose();
    _placeholderCtrl.dispose();
    _unitCtrl.dispose();
    _noteCtrl.dispose();
    _maxLengthCtrl.dispose();
    _regexCtrl.dispose();
    _minPhotosCtrl.dispose();
    _maxPhotosCtrl.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(0.0),
        bottomRight: Radius.circular(0.0),
        topLeft: Radius.circular(20.0),
        topRight: Radius.circular(20.0),
      ),
      child: Container(
        decoration: BoxDecoration(
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
                height: MediaQuery.sizeOf(context).height * 0.7,
                decoration: BoxDecoration(
                  color: FlutterFlowTheme.of(context).secondaryBackground,
                ),
                child: Align(
                  alignment: AlignmentDirectional(0.0, 0.0),
                  child: Padding(
                    padding:
                        EdgeInsetsDirectional.fromSTEB(0.0, 30.0, 0.0, 30.0),
                    child: Container(
                      width: 345.0,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                      ),
                      child: Align(
                        alignment: AlignmentDirectional(0.0, -1.0),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryBackground,
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 4.0,
                                      color: Color(0x33000000),
                                      offset: Offset(
                                        0.0,
                                        2.0,
                                      ),
                                    )
                                  ],
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.max,
                                  children: [
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          10.0, 20.0, 10.0, 0.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.max,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Card Title',
                                                      style: FlutterFlowTheme.of(
                                                              context)
                                                          .bodyMedium
                                                          .override(
                                                            font: GoogleFonts.inter(
                                                              fontWeight:
                                                                  FontWeight.w600,
                                                              fontStyle:
                                                                  FlutterFlowTheme.of(
                                                                          context)
                                                                      .bodyMedium
                                                                      .fontStyle,
                                                            ),
                                                            fontSize: 20.0,
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
                                                    const SizedBox(width: 10),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(
                                                          horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFFF1F5F9),
                                                        borderRadius:
                                                            BorderRadius.circular(6),
                                                      ),
                                                      child: Text(
                                                        labelFromType(widget.type),
                                                        style: GoogleFonts.inter(
                                                          fontSize: 11,
                                                          fontWeight: FontWeight.w500,
                                                          color: const Color(0xFF64748B),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Padding(
                                                  padding: EdgeInsetsDirectional
                                                      .fromSTEB(
                                                          0.0, 7.0, 0.0, 0.0),
                                                  child: Container(
                                                    width: double.infinity,
                                                    child: TextFormField(
                                                      controller: _model
                                                          .cardTitleTextController,
                                                      focusNode: _model
                                                          .cardTitleFocusNode,
                                                      autofocus: false,
                                                      autofillHints: [
                                                        AutofillHints.name
                                                      ],
                                                      textCapitalization:
                                                          TextCapitalization
                                                              .sentences,
                                                      textInputAction:
                                                          TextInputAction.next,
                                                      obscureText: false,
                                                      decoration:
                                                          InputDecoration(
                                                        labelStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
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
                                                        alignLabelWithHint:
                                                            false,
                                                        hintText:
                                                            'e.g  Are truck documents up to date?',
                                                        hintStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
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
                                                                  color: Color(
                                                                      0x4C1D354F),
                                                                  fontSize:
                                                                      15.0,
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
                                                        enabledBorder:
                                                            OutlineInputBorder(
                                                          borderSide:
                                                              BorderSide(
                                                            color: Color(
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
                                                            color: FlutterFlowTheme
                                                                    .of(context)
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
                                                            color: FlutterFlowTheme
                                                                    .of(context)
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
                                                            color: FlutterFlowTheme
                                                                    .of(context)
                                                                .alternate,
                                                            width: 2.0,
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      5.0),
                                                        ),
                                                        filled: true,
                                                        fillColor:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .primaryBackground,
                                                      ),
                                                      style:
                                                          FlutterFlowTheme.of(
                                                                  context)
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
                                                                color: FlutterFlowTheme.of(
                                                                        context)
                                                                    .primaryText,
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
                                                          .cardTitleTextControllerValidator
                                                          .asValidator(context),
                                                      inputFormatters: [
                                                        if (!isAndroid &&
                                                            !isiOS)
                                                          TextInputFormatter
                                                              .withFunction(
                                                                  (oldValue,
                                                                      newValue) {
                                                            return TextEditingValue(
                                                              selection: newValue
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
                                              ],
                                            ),
                                          ),
                                          // ── Required / Optional toggle ──────────────────
                                          Padding(
                                            padding: const EdgeInsetsDirectional.fromSTEB(0, 14, 0, 0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                                                const SizedBox(height: 12),
                                                Row(
                                                  crossAxisAlignment: CrossAxisAlignment.center,
                                                  children: [
                                                    const Icon(Icons.rule_rounded, size: 16, color: Color(0xFF64748B)),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            'Step completion',
                                                            style: GoogleFonts.inter(
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.w600,
                                                              color: const Color(0xFF1E293B),
                                                            ),
                                                          ),
                                                          Text(
                                                            'Optional steps can be skipped during inspection',
                                                            style: GoogleFonts.inter(
                                                              fontSize: 11,
                                                              fontWeight: FontWeight.w400,
                                                              color: const Color(0xFF64748B),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Column(
                                                      children: [
                                                        Text(
                                                          _isRequired ? 'Required' : 'Optional',
                                                          style: GoogleFonts.inter(
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w700,
                                                            color: _isRequired
                                                                ? const Color(0xFF0EA5E9)
                                                                : const Color(0xFFF59E0B),
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          height: 24,
                                                          width: 40,
                                                          child: FittedBox(
                                                            fit: BoxFit.contain,
                                                            child: Switch.adaptive(
                                                              value: _isRequired,
                                                              activeTrackColor: const Color(0xFF0EA5E9),
                                                              onChanged: (val) => safeSetState(() {
                                                                _isRequired = val;
                                                              }),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                const Divider(height: 1, thickness: 1, color: Color(0xFFE2E8F0)),
                                              ],
                                            ),
                                          ),
                                          _buildTypeConfig(context),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsetsDirectional.fromSTEB(
                                          0.0, 20.0, 0.0, 0.0),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: FFButtonWidget(
                                              onPressed: () async {
                                                Navigator.pop(context);
                                              },
                                              text: 'Cancel',
                                              icon: FaIcon(
                                                FontAwesomeIcons.times,
                                                size: 24.0,
                                              ),
                                              options: FFButtonOptions(
                                                height: 60.0,
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        16.0, 0.0, 16.0, 0.0),
                                                iconAlignment:
                                                    IconAlignment.end,
                                                iconPadding:
                                                    EdgeInsetsDirectional
                                                        .fromSTEB(
                                                            0.0, 1.0, 0.0, 0.0),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .secondary,
                                                textStyle: FlutterFlowTheme.of(
                                                        context)
                                                    .titleSmall
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleSmall
                                                                .fontStyle,
                                                      ),
                                                      color:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .primaryText,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleSmall
                                                              .fontStyle,
                                                    ),
                                                elevation: 0.0,
                                                borderRadius: BorderRadius.only(
                                                  bottomLeft:
                                                      Radius.circular(16.0),
                                                  bottomRight:
                                                      Radius.circular(0.0),
                                                  topLeft: Radius.circular(0.0),
                                                  topRight:
                                                      Radius.circular(0.0),
                                                ),
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: FFButtonWidget(
                                              onPressed: () async {
                                                final t = widget!.type!;
                                                final checks = t == 'multi-check'
                                                    ? _model.checksList.toList()
                                                    : null;
                                                // Derive item-level values from per-check config (backward compat)
                                                if (t == 'multi-check' && checks != null) {
                                                  _photoRequired = checks.any(
                                                      (c) => c['photoRequired'] == true);
                                                  final maxP = checks
                                                      .map((c) => (c['maxPhotos'] as num?)?.toInt() ?? 5)
                                                      .fold<int>(5, (a, b) => a > b ? a : b);
                                                  _maxPhotosCtrl.text = maxP.toString();
                                                }
                                                final opts = t == 'multiple-choice'
                                                    ? _model.checksList
                                                        .map((c) => {'label': (c['label'] ?? '').toString()})
                                                        .toList()
                                                    : null;
                                                final args = [
                                                  _minCtrl.text.isEmpty         ? null : _minCtrl.text,
                                                  _maxCtrl.text.isEmpty         ? null : _maxCtrl.text,
                                                  _placeholderCtrl.text.isEmpty ? null : _placeholderCtrl.text,
                                                  _unitCtrl.text.isEmpty        ? null : _unitCtrl.text,
                                                  _noteCtrl.text.isEmpty        ? null : _noteCtrl.text,
                                                  _minPhotosCtrl.text.isEmpty   ? null : _minPhotosCtrl.text,
                                                  _maxPhotosCtrl.text.isEmpty   ? null : _maxPhotosCtrl.text,
                                                  _maxLengthCtrl.text.isEmpty   ? null : _maxLengthCtrl.text,
                                                  _regexCtrl.text.isEmpty       ? null : _regexCtrl.text,
                                                ];
                                                if (widget!.mode ==
                                                    FFAppConstants.CREATEMODE) {
                                                  _model.cardOutputOnCreate =
                                                      await actions.buildCard(
                                                    widget!.mode,
                                                    null,
                                                    widget!.index!,
                                                    t,
                                                    _model.cardTitleTextController.text,
                                                    null,
                                                    checks,
                                                    opts,
                                                    _allowMultiple,
                                                    _photoRequired,
                                                    args[0],
                                                    args[1],
                                                    args[2],
                                                    args[3],
                                                    args[4],
                                                    args[5],
                                                    args[6],
                                                    [],
                                                    args[7],
                                                    args[8],
                                                    _isRequired,
                                                  );
                                                  await widget.onSave?.call(
                                                    _model.cardOutputOnCreate!,
                                                  );
                                                } else {
                                                  _model.cardOutputOnEdit =
                                                      await actions.buildCard(
                                                    widget!.mode,
                                                    widget!.incomingItem,
                                                    widget!.index!,
                                                    t,
                                                    _model.cardTitleTextController.text,
                                                    null,
                                                    checks,
                                                    opts,
                                                    _allowMultiple,
                                                    _photoRequired,
                                                    args[0],
                                                    args[1],
                                                    args[2],
                                                    args[3],
                                                    args[4],
                                                    args[5],
                                                    args[6],
                                                    [],
                                                    args[7],
                                                    args[8],
                                                    _isRequired,
                                                  );
                                                  await widget.onSave?.call(
                                                    _model.cardOutputOnEdit!,
                                                  );
                                                }

                                                Navigator.pop(context);

                                                safeSetState(() {});
                                              },
                                              text: 'Add',
                                              icon: FaIcon(
                                                FontAwesomeIcons.check,
                                                size: 24.0,
                                              ),
                                              options: FFButtonOptions(
                                                height: 60.0,
                                                padding: EdgeInsetsDirectional
                                                    .fromSTEB(
                                                        16.0, 0.0, 16.0, 0.0),
                                                iconAlignment:
                                                    IconAlignment.end,
                                                iconPadding:
                                                    EdgeInsetsDirectional
                                                        .fromSTEB(
                                                            0.0, 0.0, 0.0, 0.0),
                                                color:
                                                    FlutterFlowTheme.of(context)
                                                        .primary,
                                                textStyle: FlutterFlowTheme.of(
                                                        context)
                                                    .titleSmall
                                                    .override(
                                                      font: GoogleFonts.inter(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                        fontStyle:
                                                            FlutterFlowTheme.of(
                                                                    context)
                                                                .titleSmall
                                                                .fontStyle,
                                                      ),
                                                      color: Colors.white,
                                                      letterSpacing: 0.0,
                                                      fontWeight:
                                                          FontWeight.normal,
                                                      fontStyle:
                                                          FlutterFlowTheme.of(
                                                                  context)
                                                              .titleSmall
                                                              .fontStyle,
                                                    ),
                                                elevation: 0.0,
                                                borderRadius: BorderRadius.only(
                                                  bottomLeft:
                                                      Radius.circular(0.0),
                                                  bottomRight:
                                                      Radius.circular(16.0),
                                                  topLeft: Radius.circular(0.0),
                                                  topRight:
                                                      Radius.circular(0.0),
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
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Type-conditional config section ────────────────────────────────────────

  Widget _buildTypeConfig(BuildContext context) {
    switch (widget.type) {
      case 'multi-check':
        return _buildChecksSection(context);
      case 'multiple-choice':
        return _buildOptionsSection(context);
      case 'single-check':
        return _buildSingleCheckConfig(context);
      case 'numeric':
        return _buildNumericConfig(context);
      case 'comment-box':
        return _buildCommentBoxConfig(context);
      case 'alphanumeric':
        return _buildAlphanumericConfig(context);
      case 'photo':
        return _buildPhotoConfig(context);
      case 'signature':
        return _buildSignatureConfig(context);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Shared field helper ─────────────────────────────────────────────────────

  Widget _configField(
    BuildContext context,
    String label,
    TextEditingController ctrl, {
    String? hint,
    TextInputType? keyboard,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: FlutterFlowTheme.of(context).labelMedium.override(
                  font: GoogleFonts.inter(
                    fontWeight:
                        FlutterFlowTheme.of(context).labelMedium.fontWeight,
                  ),
                  letterSpacing: 0.0,
                ),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            keyboardType: keyboard,
            maxLines: maxLines,
            style: FlutterFlowTheme.of(context).bodyLarge.override(
                  font: GoogleFonts.inter(
                    fontWeight:
                        FlutterFlowTheme.of(context).bodyLarge.fontWeight,
                  ),
                  letterSpacing: 0.0,
                ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: FlutterFlowTheme.of(context).labelMedium.override(
                    font: GoogleFonts.inter(
                      fontWeight:
                          FlutterFlowTheme.of(context).labelMedium.fontWeight,
                    ),
                    letterSpacing: 0.0,
                  ),
              filled: true,
              fillColor: FlutterFlowTheme.of(context).secondaryBackground,
              contentPadding:
                  const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: FlutterFlowTheme.of(context).alternate, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: FlutterFlowTheme.of(context).alternate, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                    color: FlutterFlowTheme.of(context).primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Multi Check ─────────────────────────────────────────────────────────────

  Widget _buildChecksSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
      child: Container(
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: FlutterFlowTheme.of(context).alternate, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
              child: Text(
                'Multi Checks',
                style: FlutterFlowTheme.of(context).titleSmall.override(
                      font: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                      ),
                      letterSpacing: 0.0,
                    ),
              ),
            ),
            Builder(
              builder: (context) {
                final checks = _model.checksList.toList();
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: checks.length,
                  itemBuilder: (context, idx) {
                    final check = checks[idx];
                    final checkId = check['id']?.toString() ?? idx.toString();
                    final checkPhotoReq = check['photoRequired'] == true;
                    final checkMaxPhotos =
                        (check['maxPhotos'] as num?)?.toInt().clamp(1, 5) ?? 5;
                    return Column(
                      key: ValueKey(checkId),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        OptionRowWidget(
                          id: checkId,
                          value: check['label']?.toString() ?? '',
                          mode: widget.mode,
                          onDelete: (id) async {
                            safeSetState(() {
                              _model.checksList
                                  .removeWhere((c) => c['id'] == id);
                            });
                          },
                          onLabelChanged: (newLabel) async {
                            safeSetState(() {
                              final i = _model.checksList
                                  .indexWhere((c) => c['id'] == checkId);
                              if (i >= 0) {
                                _model.checksList[i]['label'] = newLabel;
                              }
                            });
                          },
                        ),
                        // ── Per-check photo config (compact single row) ──
                        Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                              48, 0, 12, 4),
                          child: Row(
                            children: [
                              Icon(Icons.photo_camera_outlined,
                                  size: 14,
                                  color: checkPhotoReq
                                      ? FlutterFlowTheme.of(context).primary
                                      : FlutterFlowTheme.of(context)
                                          .secondaryText),
                              const SizedBox(width: 4),
                              Text(
                                'Photo required',
                                style: FlutterFlowTheme.of(context)
                                    .labelSmall
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              SizedBox(
                                height: 24,
                                width: 40,
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: Switch.adaptive(
                                    value: checkPhotoReq,
                                    activeTrackColor:
                                        FlutterFlowTheme.of(context).primary,
                                    onChanged: (val) => safeSetState(() {
                                      final i = _model.checksList.indexWhere(
                                          (c) => c['id'] == checkId);
                                      if (i >= 0) {
                                        _model.checksList[i]['photoRequired'] =
                                            val;
                                      }
                                    }),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.collections_outlined,
                                  size: 14,
                                  color: FlutterFlowTheme.of(context)
                                      .secondaryText),
                              const SizedBox(width: 4),
                              Text(
                                'Max:',
                                style: FlutterFlowTheme.of(context)
                                    .labelSmall
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              const SizedBox(width: 2),
                              DropdownButton<int>(
                                value: checkMaxPhotos,
                                underline: const SizedBox.shrink(),
                                isDense: true,
                                items: List.generate(5, (i) {
                                  final v = i + 1;
                                  return DropdownMenuItem(
                                    value: v,
                                    child: Text(
                                      '$v',
                                      style: FlutterFlowTheme.of(context)
                                          .bodySmall
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodySmall
                                                      .fontWeight,
                                            ),
                                            letterSpacing: 0.0,
                                          ),
                                    ),
                                  );
                                }),
                                onChanged: (v) => safeSetState(() {
                                  final i = _model.checksList.indexWhere(
                                      (c) => c['id'] == checkId);
                                  if (i >= 0) {
                                    _model.checksList[i]['maxPhotos'] = v ?? 5;
                                  }
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 12, 12),
                child: FFButtonWidget(
                  onPressed: () {
                    safeSetState(() {
                      _model.checksList.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'label': '',
                        'type': 'checkbox',
                        'photoRequired': false,
                        'maxPhotos': 5,
                      });
                    });
                  },
                  text: 'Add More Checks',
                  icon: const Icon(Icons.add, size: 18),
                  options: FFButtonOptions(
                    height: 36,
                    padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
                    color: FlutterFlowTheme.of(context).primary,
                    textStyle: FlutterFlowTheme.of(context).labelMedium.override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                          color: Colors.white,
                          letterSpacing: 0.0,
                        ),
                    elevation: 0,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Multiple Choice ─────────────────────────────────────────────────────────

  Widget _buildOptionsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 0, 0),
      child: Container(
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: FlutterFlowTheme.of(context).alternate, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
              child: Text(
                'Options',
                style: FlutterFlowTheme.of(context).titleSmall.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      letterSpacing: 0.0,
                    ),
              ),
            ),
            Builder(
              builder: (context) {
                final opts = _model.checksList.toList();
                return ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: opts.length,
                  itemBuilder: (context, idx) {
                    final opt = opts[idx];
                    final optId = opt['id']?.toString() ?? idx.toString();
                    return OptionRowWidget(
                      key: ValueKey(optId),
                      id: optId,
                      value: opt['label']?.toString() ?? '',
                      mode: widget.mode,
                      onDelete: (id) async {
                        safeSetState(() {
                          _model.checksList
                              .removeWhere((c) => c['id'] == id);
                        });
                      },
                      onLabelChanged: (newLabel) async {
                        safeSetState(() {
                          final i = _model.checksList
                              .indexWhere((c) => c['id'] == optId);
                          if (i >= 0) _model.checksList[i]['label'] = newLabel;
                        });
                      },
                    );
                  },
                );
              },
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 8, 12, 12),
                child: FFButtonWidget(
                  onPressed: () {
                    safeSetState(() {
                      _model.checksList.add({
                        'id': DateTime.now().millisecondsSinceEpoch.toString(),
                        'label': '',
                        'type': 'checkbox',
                        'photoRequired': false,
                        'maxPhotos': 5,
                      });
                    });
                  },
                  text: 'Add Option',
                  icon: const Icon(Icons.add, size: 18),
                  options: FFButtonOptions(
                    height: 36,
                    padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
                    color: FlutterFlowTheme.of(context).primary,
                    textStyle: FlutterFlowTheme.of(context).labelMedium.override(
                          font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                          color: Colors.white,
                          letterSpacing: 0.0,
                        ),
                    elevation: 0,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            // Allow Multiple toggle
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Allow Multiple Selections',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodyMedium
                                .fontWeight,
                          ),
                          letterSpacing: 0.0,
                        ),
                  ),
                  Switch(
                    value: _allowMultiple,
                    activeThumbColor: FlutterFlowTheme.of(context).primary,
                    onChanged: (v) => safeSetState(() => _allowMultiple = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Single-check photo config ────────────────────────────────────────────

  Widget _buildSingleCheckConfig(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(0, 16, 0, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).primaryBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: FlutterFlowTheme.of(context).alternate,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.camera_alt_outlined,
                size: 16,
                color: FlutterFlowTheme.of(context).secondaryText),
            const SizedBox(width: 6),
            Text(
              'Photo required',
              style: FlutterFlowTheme.of(context).labelSmall.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    letterSpacing: 0.0,
                  ),
            ),
            SizedBox(
              height: 24,
              width: 40,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Switch.adaptive(
                  value: _photoRequired,
                  activeTrackColor: FlutterFlowTheme.of(context).primary,
                  onChanged: (val) => safeSetState(() {
                    _photoRequired = val;
                  }),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.collections_outlined,
                size: 14,
                color: FlutterFlowTheme.of(context).secondaryText),
            const SizedBox(width: 4),
            Text(
              'Max:',
              style: FlutterFlowTheme.of(context).labelSmall.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    letterSpacing: 0.0,
                  ),
            ),
            const SizedBox(width: 2),
            DropdownButton<int>(
              value: int.tryParse(_maxPhotosCtrl.text)?.clamp(1, 5) ?? 5,
              underline: const SizedBox.shrink(),
              isDense: true,
              items: List.generate(5, (i) {
                final v = i + 1;
                return DropdownMenuItem(
                  value: v,
                  child: Text(
                    '$v',
                    style: FlutterFlowTheme.of(context).bodySmall.override(
                          font: GoogleFonts.inter(
                            fontWeight: FlutterFlowTheme.of(context)
                                .bodySmall
                                .fontWeight,
                          ),
                          letterSpacing: 0.0,
                        ),
                  ),
                );
              }),
              onChanged: (v) => safeSetState(() {
                _maxPhotosCtrl.text = (v ?? 5).toString();
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Numeric ─────────────────────────────────────────────────────────────────

  Widget _buildNumericConfig(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: _configField(context, 'Min Value', _minCtrl,
                    hint: 'e.g. 0',
                    keyboard: const TextInputType.numberWithOptions(
                        decimal: true))),
            const SizedBox(width: 12),
            Expanded(
                child: _configField(context, 'Max Value', _maxCtrl,
                    hint: 'e.g. 100',
                    keyboard: const TextInputType.numberWithOptions(
                        decimal: true))),
          ],
        ),
        _configField(context, 'Placeholder', _placeholderCtrl,
            hint: 'e.g. Enter mileage'),
        _configField(context, 'Unit', _unitCtrl, hint: 'e.g. km, hrs'),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.camera_alt_outlined,
                size: 14,
                color: FlutterFlowTheme.of(context).secondaryText),
            const SizedBox(width: 6),
            Text(
              'Enable OCR (camera text read)',
              style: FlutterFlowTheme.of(context).labelSmall.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    letterSpacing: 0.0,
                  ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 24,
              width: 40,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Switch.adaptive(
                  value: _photoRequired,
                  activeTrackColor: FlutterFlowTheme.of(context).primary,
                  onChanged: (val) => safeSetState(() {
                    _photoRequired = val;
                  }),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Comment Box ─────────────────────────────────────────────────────────────

  Widget _buildCommentBoxConfig(BuildContext context) {
    return Column(
      children: [
        _configField(context, 'Placeholder', _placeholderCtrl,
            hint: 'e.g. Add your comments here…', maxLines: 2),
        _configField(context, 'Max Length', _maxLengthCtrl,
            hint: 'e.g. 500',
            keyboard: TextInputType.number),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.camera_alt_outlined,
                size: 14,
                color: FlutterFlowTheme.of(context).secondaryText),
            const SizedBox(width: 6),
            Text(
              'Enable OCR (camera text read)',
              style: FlutterFlowTheme.of(context).labelSmall.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    letterSpacing: 0.0,
                  ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 24,
              width: 40,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Switch.adaptive(
                  value: _photoRequired,
                  activeTrackColor: FlutterFlowTheme.of(context).primary,
                  onChanged: (val) => safeSetState(() {
                    _photoRequired = val;
                  }),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Alphanumeric ────────────────────────────────────────────────────────────

  Widget _buildAlphanumericConfig(BuildContext context) {
    return Column(
      children: [
        _configField(context, 'Placeholder', _placeholderCtrl,
            hint: 'e.g. Enter serial number'),
        _configField(context, 'Max Length', _maxLengthCtrl,
            hint: 'e.g. 50',
            keyboard: TextInputType.number),
        _configField(context, 'Format Pattern (optional)', _regexCtrl,
            hint: 'e.g. ABC 1234 or 123-456-789'),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Letters = A-Z position, Digits = 0-9 position, spaces & dashes kept as-is',
            style: FlutterFlowTheme.of(context).labelSmall.override(
                  font: GoogleFonts.inter(fontWeight: FontWeight.w400),
                  color: const Color(0xFF94A3B8),
                  fontSize: 10,
                  letterSpacing: 0.0,
                ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.camera_alt_outlined,
                size: 14,
                color: FlutterFlowTheme.of(context).secondaryText),
            const SizedBox(width: 6),
            Text(
              'Enable OCR (camera text read)',
              style: FlutterFlowTheme.of(context).labelSmall.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    letterSpacing: 0.0,
                  ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 24,
              width: 40,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Switch.adaptive(
                  value: _photoRequired,
                  activeTrackColor: FlutterFlowTheme.of(context).primary,
                  onChanged: (val) => safeSetState(() {
                    _photoRequired = val;
                  }),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Photo ───────────────────────────────────────────────────────────────────

  Widget _buildPhotoConfig(BuildContext context) {
    return Column(
      children: [
        _configField(context, 'Instruction Note (optional)', _noteCtrl,
            hint: 'e.g. Photograph all four sides', maxLines: 2),
        Row(
          children: [
            Expanded(
                child: _configField(context, 'Min Photos', _minPhotosCtrl,
                    hint: '1', keyboard: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(
                child: _configField(context, 'Max Photos', _maxPhotosCtrl,
                    hint: '5', keyboard: TextInputType.number)),
          ],
        ),
      ],
    );
  }

  // ─── Signature ───────────────────────────────────────────────────────────────

  Widget _buildSignatureConfig(BuildContext context) {
    return _configField(
      context,
      'Instruction Note (optional)',
      _noteCtrl,
      hint: 'e.g. Inspector signature required',
      maxLines: 2,
    );
  }
}
