import '/backend/api_requests/api_calls.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import 'bottom_sheet_add_forms_to_asset_widget.dart'
    show BottomSheetAddFormsToAssetWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class BottomSheetAddFormsToAssetModel
    extends FlutterFlowModel<BottomSheetAddFormsToAssetWidget> {
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

  bool isSelectAll = false;

  bool isClearAll = true;

  int offset = 0;

  int pageLimit = 25;

  bool isLoadingMore = false;

  List<dynamic> tempDecodedList = [];
  void addToTempDecodedList(dynamic item) => tempDecodedList.add(item);
  void removeFromTempDecodedList(dynamic item) => tempDecodedList.remove(item);
  void removeAtIndexFromTempDecodedList(int index) =>
      tempDecodedList.removeAt(index);
  void insertAtIndexInTempDecodedList(int index, dynamic item) =>
      tempDecodedList.insert(index, item);
  void updateTempDecodedListAtIndex(int index, Function(dynamic) updateFn) =>
      tempDecodedList[index] = updateFn(tempDecodedList[index]);

  List<dynamic> selecredFormsForReturn = [];
  void addToSelecredFormsForReturn(dynamic item) =>
      selecredFormsForReturn.add(item);
  void removeFromSelecredFormsForReturn(dynamic item) =>
      selecredFormsForReturn.remove(item);
  void removeAtIndexFromSelecredFormsForReturn(int index) =>
      selecredFormsForReturn.removeAt(index);
  void insertAtIndexInSelecredFormsForReturn(int index, dynamic item) =>
      selecredFormsForReturn.insert(index, item);
  void updateSelecredFormsForReturnAtIndex(
          int index, Function(dynamic) updateFn) =>
      selecredFormsForReturn[index] = updateFn(selecredFormsForReturn[index]);

  ///  State fields for stateful widgets in this component.

  // Stores action output result for [Backend Call - API (Search Inspection Form Templates)] action in bottomSheetAddFormsToAsset widget.
  ApiCallResponse? apiResultgwb;
  // State field(s) for Switch widget.
  bool? switchValue;
  // State field(s) for searchTextField widget.
  FocusNode? searchTextFieldFocusNode;
  TextEditingController? searchTextFieldTextController;
  String? Function(BuildContext, String?)?
      searchTextFieldTextControllerValidator;
  // Stores action output result for [Backend Call - API (Search Inspection Form Templates)] action in searchTextField widget.
  ApiCallResponse? apiResultz3s;
  // Stores action output result for [Backend Call - API (Search Inspection Form Templates)] action in SelectableFormsList widget.
  ApiCallResponse? apiResultLoadMore;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    searchTextFieldFocusNode?.dispose();
    searchTextFieldTextController?.dispose();
  }
}
