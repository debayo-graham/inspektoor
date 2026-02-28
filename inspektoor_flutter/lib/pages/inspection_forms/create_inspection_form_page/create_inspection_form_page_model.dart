import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/pages/components/card_editor_sheet/card_editor_sheet_widget.dart';
import '/pages/components/custom_confirm_dialog/custom_confirm_dialog_widget.dart';
import '/pages/components/snackbar/snackbar_widget.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'create_inspection_form_page_widget.dart'
    show CreateInspectionFormPageWidget;
import 'dart:math' as math;
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class CreateInspectionFormPageModel
    extends FlutterFlowModel<CreateInspectionFormPageWidget> {
  ///  Local state fields for this page.

  List<dynamic> inspectionFormItems = [];
  void addToInspectionFormItems(dynamic item) => inspectionFormItems.add(item);
  void removeFromInspectionFormItems(dynamic item) =>
      inspectionFormItems.remove(item);
  void removeAtIndexFromInspectionFormItems(int index) =>
      inspectionFormItems.removeAt(index);
  void insertAtIndexInInspectionFormItems(int index, dynamic item) =>
      inspectionFormItems.insert(index, item);
  void updateInspectionFormItemsAtIndex(
          int index, Function(dynamic) updateFn) =>
      inspectionFormItems[index] = updateFn(inspectionFormItems[index]);

  String? recentlyMovedKey;

  bool fabIsOpen = false;

  dynamic validationResult;

  bool inspectionTemplateNameState = false;

  String? inspectionTemplateNameErrMsg;

  bool cardTypeState = false;

  String? cardTypeErrMsg;

  bool isAddCardDisabled = true;

  ///  State fields for stateful widgets in this page.

  // State field(s) for inspectionTemplateName widget.
  FocusNode? inspectionTemplateNameFocusNode;
  TextEditingController? inspectionTemplateNameTextController;
  String? Function(BuildContext, String?)?
      inspectionTemplateNameTextControllerValidator;
  // State field(s) for cardType widget.
  String? cardTypeValue;
  FormFieldController<String>? cardTypeValueController;
  // Stores action output result for [Custom Action - addOrReplaceByKey] action in CardContainer widget.
  List<dynamic>? editedInspectionFormItems;
  // Stores action output result for [Custom Action - moveCardItem] action in Container widget.
  List<dynamic>? reorderedInspectionFormItemsOnIncrement;
  // Stores action output result for [Custom Action - moveCardItem] action in Container widget.
  List<dynamic>? reorderedInspectionFormItemsOnDecrement;
  // Stores action output result for [Custom Action - deleteCardItemByKey] action in Icon widget.
  List<dynamic>? inspectionFormItemsAfterDelete;
  // Stores action output result for [Backend Call - Insert Row] action in Button1 widget.
  InspectionTemplatesRow? newTemplate;
  // Stores action output result for [Custom Action - wrapSchema] action in Button1 widget.
  dynamic? inspectionFormSchema;
  // State field(s) for MouseRegion widget.
  bool mouseRegionHovered1 = false;
  // State field(s) for MouseRegion widget.
  bool mouseRegionHovered2 = false;
  // State field(s) for MouseRegion widget.
  bool mouseRegionHovered3 = false;
  // State field(s) for MouseRegion widget.
  bool mouseRegionHovered4 = false;
  // State field(s) for MouseRegion widget.
  bool mouseRegionHovered5 = false;
  // Model for snackbar component.
  late SnackbarModel snackbarModel;

  @override
  void initState(BuildContext context) {
    snackbarModel = createModel(context, () => SnackbarModel());
  }

  @override
  void dispose() {
    inspectionTemplateNameFocusNode?.dispose();
    inspectionTemplateNameTextController?.dispose();

    snackbarModel.dispose();
  }
}
