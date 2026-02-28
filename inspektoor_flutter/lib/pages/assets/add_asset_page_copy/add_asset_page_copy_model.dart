import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import 'add_asset_page_copy_widget.dart' show AddAssetPageCopyWidget;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class AddAssetPageCopyModel extends FlutterFlowModel<AddAssetPageCopyWidget> {
  ///  State fields for stateful widgets in this page.

  bool isDataUploading_uploadDataRgk1 = false;
  FFUploadedFile uploadedLocalFile_uploadDataRgk1 =
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
  bool isDataUploading_uploadDataSa01 = false;
  FFUploadedFile uploadedLocalFile_uploadDataSa01 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataSa01 = '';

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    assetNameFocusNode?.dispose();
    assetNameTextController?.dispose();

    makeFocusNode?.dispose();
    makeTextController?.dispose();

    modelFocusNode?.dispose();
    modelTextController?.dispose();
  }
}
