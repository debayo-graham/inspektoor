import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/option_row/option_row_widget.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import 'card_editor_sheet_widget.dart' show CardEditorSheetWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class CardEditorSheetModel extends FlutterFlowModel<CardEditorSheetWidget> {
  ///  Local state fields for this component.

  List<dynamic> checksList = [];
  void addToChecksList(dynamic item) => checksList.add(item);
  void removeFromChecksList(dynamic item) => checksList.remove(item);
  void removeAtIndexFromChecksList(int index) => checksList.removeAt(index);
  void insertAtIndexInChecksList(int index, dynamic item) =>
      checksList.insert(index, item);
  void updateChecksListAtIndex(int index, Function(dynamic) updateFn) =>
      checksList[index] = updateFn(checksList[index]);

  dynamic rowId;

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Custom Action - generateUuidAction] action in CardEditorSheet widget.
  String? initUuid;
  // State field(s) for cardTitle widget.
  FocusNode? cardTitleFocusNode;
  TextEditingController? cardTitleTextController;
  String? Function(BuildContext, String?)? cardTitleTextControllerValidator;
  // Models for optionRow dynamic component.
  late FlutterFlowDynamicModels<OptionRowModel> optionRowModels;
  // Stores action output result for [Custom Action - generateUuidAction] action in Button widget.
  String? uuid;
  // Stores action output result for [Custom Action - buildCard] action in Button widget.
  dynamic? cardOutputOnCreate;
  // Stores action output result for [Custom Action - buildCard] action in Button widget.
  dynamic? cardOutputOnEdit;

  @override
  void initState(BuildContext context) {
    optionRowModels = FlutterFlowDynamicModels(() => OptionRowModel());
  }

  @override
  void dispose() {
    cardTitleFocusNode?.dispose();
    cardTitleTextController?.dispose();

    optionRowModels.dispose();
  }
}
