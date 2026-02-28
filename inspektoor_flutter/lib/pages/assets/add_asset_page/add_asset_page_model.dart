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
import '/pages/components/custom_message_dialog/custom_message_dialog_widget.dart';
import '/pages/components/empty_list/empty_list_widget.dart';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import 'add_asset_page_widget.dart' show AddAssetPageWidget;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class AddAssetPageModel extends FlutterFlowModel<AddAssetPageWidget> {
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

  bool isInserted = false;

  int insertErrorCode = 0;

  String? insertErrorMsg;

  bool assetNameState = false;

  String? assetNameErrMsg;

  bool modelState = false;

  String? modelErrMsg;

  bool makeState = false;

  String? makeErrMsg;

  bool categoryState = false;

  String? categoryErrMsg;

  dynamic fldValidationResult;

  bool isFormValidationOk = false;

  List<String> formsIdToDelete = [];
  void addToFormsIdToDelete(String item) => formsIdToDelete.add(item);
  void removeFromFormsIdToDelete(String item) => formsIdToDelete.remove(item);
  void removeAtIndexFromFormsIdToDelete(int index) =>
      formsIdToDelete.removeAt(index);
  void insertAtIndexInFormsIdToDelete(int index, String item) =>
      formsIdToDelete.insert(index, item);
  void updateFormsIdToDeleteAtIndex(int index, Function(String) updateFn) =>
      formsIdToDelete[index] = updateFn(formsIdToDelete[index]);

  ///  State fields for stateful widgets in this page.

  // State field(s) for TabBar widget.
  TabController? tabBarController;
  int get tabBarCurrentIndex =>
      tabBarController != null ? tabBarController!.index : 0;
  int get tabBarPreviousIndex =>
      tabBarController != null ? tabBarController!.previousIndex : 0;

  bool isDataUploading_uploadDataRgk = false;
  FFUploadedFile uploadedLocalFile_uploadDataRgk =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');

  // State field(s) for assetName widget.
  FocusNode? assetNameFocusNode;
  TextEditingController? assetNameTextController;
  String? Function(BuildContext, String?)? assetNameTextControllerValidator;
  // State field(s) for year widget.
  FocusNode? yearFocusNode;
  TextEditingController? yearTextController;
  late MaskTextInputFormatter yearMask;
  String? Function(BuildContext, String?)? yearTextControllerValidator;
  // State field(s) for vin widget.
  FocusNode? vinFocusNode;
  TextEditingController? vinTextController;
  late MaskTextInputFormatter vinMask;
  String? Function(BuildContext, String?)? vinTextControllerValidator;
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
  // State field(s) for Checkbox widget.
  Map<dynamic, bool> checkboxValueMap = {};
  List<dynamic> get checkboxCheckedItems =>
      checkboxValueMap.entries.where((e) => e.value).map((e) => e.key).toList();

  bool isDataUploading_uploadDataSa023 = false;
  FFUploadedFile uploadedLocalFile_uploadDataSa023 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataSa023 = '';

  // Stores action output result for [Custom Action - upsertAsset] action in Button widget.
  dynamic? insertResponseWithPhoto;
  // Stores action output result for [Custom Action - upsertAsset] action in Button widget.
  dynamic? insertResponse;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    tabBarController?.dispose();
    assetNameFocusNode?.dispose();
    assetNameTextController?.dispose();

    yearFocusNode?.dispose();
    yearTextController?.dispose();

    vinFocusNode?.dispose();
    vinTextController?.dispose();

    makeFocusNode?.dispose();
    makeTextController?.dispose();

    modelFocusNode?.dispose();
    modelTextController?.dispose();
  }
}
