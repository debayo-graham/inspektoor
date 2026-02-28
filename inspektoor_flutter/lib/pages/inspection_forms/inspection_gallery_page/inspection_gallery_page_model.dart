import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/pages/components/app_drawer_content/app_drawer_content_widget.dart';
import '/pages/components/custom_confirm_dialog/custom_confirm_dialog_widget.dart';
import '/pages/components/inspection_gallery_more_options/inspection_gallery_more_options_widget.dart';
import '/pages/components/snackbar/snackbar_widget.dart';
import 'dart:math';
import 'dart:ui';
import '/custom_code/widgets/index.dart' as custom_widgets;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'dart:async';
import 'inspection_gallery_page_widget.dart' show InspectionGalleryPageWidget;
import 'package:aligned_dialog/aligned_dialog.dart';
import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class InspectionGalleryPageModel
    extends FlutterFlowModel<InspectionGalleryPageWidget> {
  ///  Local state fields for this page.

  String fliterTab = 'org_created';

  String? searchText;

  ///  State fields for stateful widgets in this page.

  // State field(s) for searchTextField widget.
  FocusNode? searchTextFieldFocusNode;
  TextEditingController? searchTextFieldTextController;
  String? Function(BuildContext, String?)?
      searchTextFieldTextControllerValidator;
  // State field(s) for InspectionFormTemplateListView widget.

  PagingController<ApiPagingParams, dynamic>?
      inspectionFormTemplateListViewPagingController;
  Function(ApiPagingParams nextPageMarker)?
      inspectionFormTemplateListViewApiCall;

  // Stores action output result for [Backend Call - Delete Row(s)] action in Icon widget.
  List<InspectionTemplatesRow>? isDeletedInspectionFormItem;
  // Model for snackbar component.
  late SnackbarModel snackbarModel;
  // Model for appDrawerContent component.
  late AppDrawerContentModel appDrawerContentModel;

  @override
  void initState(BuildContext context) {
    snackbarModel = createModel(context, () => SnackbarModel());
    appDrawerContentModel = createModel(context, () => AppDrawerContentModel());
  }

  @override
  void dispose() {
    searchTextFieldFocusNode?.dispose();
    searchTextFieldTextController?.dispose();

    inspectionFormTemplateListViewPagingController?.dispose();
    snackbarModel.dispose();
    appDrawerContentModel.dispose();
  }

  /// Additional helper methods.
  Future waitForOnePageForInspectionFormTemplateListView({
    double minWait = 0,
    double maxWait = double.infinity,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (true) {
      await Future.delayed(Duration(milliseconds: 50));
      final timeElapsed = stopwatch.elapsedMilliseconds;
      final requestComplete = (inspectionFormTemplateListViewPagingController
                  ?.nextPageKey?.nextPageNumber ??
              0) >
          0;
      if (timeElapsed > maxWait || (requestComplete && timeElapsed > minWait)) {
        break;
      }
    }
  }

  PagingController<ApiPagingParams, dynamic>
      setInspectionFormTemplateListViewController(
    Function(ApiPagingParams) apiCall,
  ) {
    inspectionFormTemplateListViewApiCall = apiCall;
    return inspectionFormTemplateListViewPagingController ??=
        _createInspectionFormTemplateListViewController(apiCall);
  }

  PagingController<ApiPagingParams, dynamic>
      _createInspectionFormTemplateListViewController(
    Function(ApiPagingParams) query,
  ) {
    final controller = PagingController<ApiPagingParams, dynamic>(
      firstPageKey: ApiPagingParams(
        nextPageNumber: 0,
        numItems: 0,
        lastResponse: null,
      ),
    );
    return controller
      ..addPageRequestListener(
          inspectionFormTemplateListViewSearchInspectionFormTemplatesPage);
  }

  void inspectionFormTemplateListViewSearchInspectionFormTemplatesPage(
          ApiPagingParams nextPageMarker) =>
      inspectionFormTemplateListViewApiCall!(nextPageMarker).then(
          (inspectionFormTemplateListViewSearchInspectionFormTemplatesResponse) {
        final pageItems =
            (inspectionFormTemplateListViewSearchInspectionFormTemplatesResponse
                        .jsonBody ??
                    [])
                .toList() as List;
        final newNumItems = nextPageMarker.numItems + pageItems.length;
        inspectionFormTemplateListViewPagingController?.appendPage(
          pageItems,
          (pageItems.length > 0)
              ? ApiPagingParams(
                  nextPageNumber: nextPageMarker.nextPageNumber + 1,
                  numItems: newNumItems,
                  lastResponse:
                      inspectionFormTemplateListViewSearchInspectionFormTemplatesResponse,
                )
              : null,
        );
      });
}
