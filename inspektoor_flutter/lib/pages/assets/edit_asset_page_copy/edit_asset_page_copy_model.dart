import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/flutter_flow/upload_data.dart';
import 'dart:ui';
import 'edit_asset_page_copy_widget.dart' show EditAssetPageCopyWidget;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class EditAssetPageCopyModel extends FlutterFlowModel<EditAssetPageCopyWidget> {
  ///  State fields for stateful widgets in this page.

  bool isDataUploading_uploadData5jf1 = false;
  FFUploadedFile uploadedLocalFile_uploadData5jf1 =
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
  bool isDataUploading_uploadDataNqy1 = false;
  FFUploadedFile uploadedLocalFile_uploadDataNqy1 =
      FFUploadedFile(bytes: Uint8List.fromList([]), originalFilename: '');
  String uploadedFileUrl_uploadDataNqy1 = '';

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
