import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_checkbox_group.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import 'bottom_sheet_add_forms_to_asset_copy_widget.dart'
    show BottomSheetAddFormsToAssetCopyWidget;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class BottomSheetAddFormsToAssetCopyModel
    extends FlutterFlowModel<BottomSheetAddFormsToAssetCopyWidget> {
  ///  Local state fields for this component.

  String? searchText;

  String flitterTab = 'all';

  List<String> tempSelectedIds = [];
  void addToTempSelectedIds(String item) => tempSelectedIds.add(item);
  void removeFromTempSelectedIds(String item) => tempSelectedIds.remove(item);
  void removeAtIndexFromTempSelectedIds(int index) =>
      tempSelectedIds.removeAt(index);
  void insertAtIndexInTempSelectedIds(int index, String item) =>
      tempSelectedIds.insert(index, item);
  void updateTempSelectedIdsAtIndex(int index, Function(String) updateFn) =>
      tempSelectedIds[index] = updateFn(tempSelectedIds[index]);

  bool selectAllForms = false;

  List<dynamic> formsList = [];
  void addToFormsList(dynamic item) => formsList.add(item);
  void removeFromFormsList(dynamic item) => formsList.remove(item);
  void removeAtIndexFromFormsList(int index) => formsList.removeAt(index);
  void insertAtIndexInFormsList(int index, dynamic item) =>
      formsList.insert(index, item);
  void updateFormsListAtIndex(int index, Function(dynamic) updateFn) =>
      formsList[index] = updateFn(formsList[index]);

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - API (Search Inspection Form Templates)] action in bottomSheetAddFormsToAssetCopy widget.
  ApiCallResponse? apiResultgwb;
  // State field(s) for Switch widget.
  bool? switchValue;
  // State field(s) for searchTextField widget.
  FocusNode? searchTextFieldFocusNode;
  TextEditingController? searchTextFieldTextController;
  String? Function(BuildContext, String?)?
      searchTextFieldTextControllerValidator;
  // State field(s) for CheckboxGroup widget.
  FormFieldController<List<String>>? checkboxGroupValueController;
  List<String>? get checkboxGroupValues => checkboxGroupValueController?.value;
  set checkboxGroupValues(List<String>? v) =>
      checkboxGroupValueController?.value = v;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    searchTextFieldFocusNode?.dispose();
    searchTextFieldTextController?.dispose();
  }
}
