import '/auth/supabase_auth/auth_util.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/app_drawer_content/app_drawer_content_widget.dart';
import '/pages/components/custom_navigation_component/custom_navigation_component_widget.dart';
import '/pages/components/dashboard_tile_lg_blue/dashboard_tile_lg_blue_widget.dart';
import '/pages/components/dashboard_tile_lg_green/dashboard_tile_lg_green_widget.dart';
import '/pages/components/dashboard_tile_lg_purple/dashboard_tile_lg_purple_widget.dart';
import '/pages/components/dashboard_tile_lg_red/dashboard_tile_lg_red_widget.dart';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/index.dart';
import 'home_page_widget.dart' show HomePageWidget;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class HomePageModel extends FlutterFlowModel<HomePageWidget> {
  ///  Local state fields for this page.

  int selectedIndex = 0;

  double? pillAlignX = -0.75;

  ///  State fields for stateful widgets in this page.

  // Stores action output result for [Backend Call - Query Rows] action in HomePage widget.
  List<AppUsersVRow>? appUserRow;
  // Model for dashboardTileLgGreen component.
  late DashboardTileLgGreenModel dashboardTileLgGreenModel;
  // Model for dashboardTileLgRed component.
  late DashboardTileLgRedModel dashboardTileLgRedModel;
  // Model for dashboardTileLgBlue component.
  late DashboardTileLgBlueModel dashboardTileLgBlueModel;
  // Model for dashboardTileLgPurple component.
  late DashboardTileLgPurpleModel dashboardTileLgPurpleModel;
  // Model for CustomNavigationComponent component.
  late CustomNavigationComponentModel customNavigationComponentModel;
  // Model for appDrawerContent component.
  late AppDrawerContentModel appDrawerContentModel;

  @override
  void initState(BuildContext context) {
    dashboardTileLgGreenModel =
        createModel(context, () => DashboardTileLgGreenModel());
    dashboardTileLgRedModel =
        createModel(context, () => DashboardTileLgRedModel());
    dashboardTileLgBlueModel =
        createModel(context, () => DashboardTileLgBlueModel());
    dashboardTileLgPurpleModel =
        createModel(context, () => DashboardTileLgPurpleModel());
    customNavigationComponentModel =
        createModel(context, () => CustomNavigationComponentModel());
    appDrawerContentModel = createModel(context, () => AppDrawerContentModel());
  }

  @override
  void dispose() {
    dashboardTileLgGreenModel.dispose();
    dashboardTileLgRedModel.dispose();
    dashboardTileLgBlueModel.dispose();
    dashboardTileLgPurpleModel.dispose();
    customNavigationComponentModel.dispose();
    appDrawerContentModel.dispose();
  }
}
