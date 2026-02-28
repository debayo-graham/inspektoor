import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/app_drawer_content/app_drawer_content_widget.dart';
import '/pages/components/custom_navigation_component/custom_navigation_component_widget.dart';
import 'dart:math';
import 'dart:ui';
import 'asset_list_page_widget.dart' show AssetListPageWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class AssetListPageModel extends FlutterFlowModel<AssetListPageWidget> {
  ///  State fields for stateful widgets in this page.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;
  // Model for CustomNavigationComponent component.
  late CustomNavigationComponentModel customNavigationComponentModel;
  // Model for appDrawerContent component.
  late AppDrawerContentModel appDrawerContentModel;

  @override
  void initState(BuildContext context) {
    customNavigationComponentModel =
        createModel(context, () => CustomNavigationComponentModel());
    appDrawerContentModel = createModel(context, () => AppDrawerContentModel());
  }

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();

    customNavigationComponentModel.dispose();
    appDrawerContentModel.dispose();
  }
}
