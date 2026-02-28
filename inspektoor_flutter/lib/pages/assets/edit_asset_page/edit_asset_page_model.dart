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
import 'edit_asset_page_widget.dart' show EditAssetPageWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class EditAssetPageModel extends FlutterFlowModel<EditAssetPageWidget> {
  ///  Local state fields for this page.

  List<String> selectedFormIds = [];
  void addToSelectedFormIds(String item) => selectedFormIds.add(item);
  void removeFromSelectedFormIds(String item) => selectedFormIds.remove(item);
  void removeAtIndexFromSelectedFormIds(int index) =>
      selectedFormIds.removeAt(index);
  void insertAtIndexInSelectedFormIds(int index, String item) =>
      selectedFormIds.insert(index, item);
  void updateSelectedFormIdsAtIndex(int index, Function(String) updateFn) =>
      selectedFormIds[index] = updateFn(selectedFormIds[index]);

  List<dynamic> selectedForms = [];
  void addToSelectedForms(dynamic item) => selectedForms.add(item);
  void removeFromSelectedForms(dynamic item) => selectedForms.remove(item);
  void removeAtIndexFromSelectedForms(int index) =>
      selectedForms.removeAt(index);
  void insertAtIndexInSelectedForms(int index, dynamic item) =>
      selectedForms.insert(index, item);
  void updateSelectedFormsAtIndex(int index, Function(dynamic) updateFn) =>
      selectedForms[index] = updateFn(selectedForms[index]);

  bool actionSuccess = false;

  int errorCode = 0;

  String? errorMsg;

  bool assetNameState = true;

  String? assetNameErrMsg;

  bool modelState = true;

  String? modelErrMsg;

  bool makeState = true;

  String? makeErrMsg;

  bool categoryState = true;

  String? categoryErrMsg;

  dynamic fldValidationResult;

  bool isFormValidationOk = true;

  List<dynamic> formsCurrentlyAdded = [];
  void addToFormsCurrentlyAdded(dynamic item) => formsCurrentlyAdded.add(item);
  void removeFromFormsCurrentlyAdded(dynamic item) =>
      formsCurrentlyAdded.remove(item);
  void removeAtIndexFromFormsCurrentlyAdded(int index) =>
      formsCurrentlyAdded.removeAt(index);
  void insertAtIndexInFormsCurrentlyAdded(int index, dynamic item) =>
      formsCurrentlyAdded.insert(index, item);
  void updateFormsCurrentlyAddedAtIndex(
          int index, Function(dynamic) updateFn) =>
      formsCurrentlyAdded[index] = updateFn(formsCurrentlyAdded[index]);

  int formsCurrentlyDeletedCnt = 0;

  List<String> formIdsToDelete = [];
  void addToFormIdsToDelete(String item) => formIdsToDelete.add(item);
  void removeFromFormIdsToDelete(String item) => formIdsToDelete.remove(item);
  void removeAtIndexFromFormIdsToDelete(int index) =>
      formIdsToDelete.removeAt(index);
  void insertAtIndexInFormIdsToDelete(int index, String item) =>
      formIdsToDelete.insert(index, item);
  void updateFormIdsToDeleteAtIndex(int index, Function(String) updateFn) =>
      formIdsToDelete[index] = updateFn(formIdsToDelete[index]);

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Custom Action - getAssetForms] action in EditAssetPage widget.
  dynamic? inspectionsFormsQuery;
  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ? tabBarController!.previousIndex : 0;

  bool isDataUploading_uploadData5jf = false;
  FFUploadedFile uploadedLocalFile_uploadData5jf =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // State field(s) for assetName widget.
  FocusNode? assetNameFocusNode;
  TextEditingController? assetNameTextController;
  String? Function(BuildContext, String?)? assetNameTextControllerValidator;
  // State field(s) for make widget.
  FocusNode? makeFocusNode;
  TextEditingController? makeTextController;
  String? Function(BuildContext, String?)? makeTextControllerValidator;
  // State field(s) for model widget.
  FocusNode? modelFocusNode;
  TextEditingController? modelTextController;
  String? Function(BuildContext, String?)? modelTextControllerValidator;
  // State field(s) for category widget.
  String? categoryValue;
  FormFieldController<String>? categoryValueController;
  // Stores action output result for [Custom Action - deleteAllFormsFromAsset] action in Row widget.
  dynamic? deleteFormsFromAssetResponse;
  // State field(s) for Checkbox widget.
  Map<dynamic, bool> checkboxValueMap = {};
  List<dynamic> get checkboxCheckedItems =>
      checkboxValueMap.entries.where((e) => e.value).map((e) => e.key).toList();

  // Stores action output result for [Custom Action - deleteAssetForms] action in IconButton widget.
  dynamic? deleteAsstFormsResponse;
  // Stores action output result for [Custom Action - addFormsToAsset] action in Row widget.
  dynamic? addFormsToAssetResponse;
  bool isDataUploading_uploadDataNqy2 = false;
  FFUploadedFile uploadedLocalFile_uploadDataNqy2 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataNqy2 = '';

  // Stores action output result for [Custom Action - upsertAsset] action in Button widget.
  dynamic? updateResponseWithPhoto;
  // Stores action output result for [Custom Action - upsertAsset] action in Button widget.
  dynamic? updateResponse;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tabBarController?.dispose();
    assetNameFocusNode?.dispose();
    assetNameTextController?.dispose();

    makeFocusNode?.dispose();
    makeTextController?.dispose();

    modelFocusNode?.dispose();
    modelTextController?.dispose();
  }
}
