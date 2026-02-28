import '/backend/api_requests/api_calls.dart';
import '/backend/supabase/supabase.dart';
import '/flutter_flow/flutter_flow_animations.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_radio_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/pages/components/bottom_sheet_plan_confirmation/bottom_sheet_plan_confirmation_widget.dart';
import '/pages/components/pin_code/pin_code_widget.dart';
import '/pages/components/snackbar/snackbar_widget.dart';
import 'dart:async';
import 'dart:math';
import 'dart:ui';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/custom_functions.dart' as functions;
import '/index.dart';
import 'onboarding_page_widget.dart' show OnboardingPageWidget;
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:webviewx_plus/webviewx_plus.dart';

class OnboardingPageModel extends FlutterFlowModel<OnboardingPageWidget> {
  ///  Local state fields for this page.

  int currentStep = 1;

  int maxStep = 4;

  bool hasShownFirstStep = false;

  /// This is set once an account is created.
  ///
  /// This flag is used so that an account is not created more than once
  bool isAccountCreated = false;

  String? challengeIdState;

  /// holds the orgId from our onboarding sutom action
  String? orgIdState;

  /// Stage marker: 'profile' | 'account' | 'org' | 'plan' | 'checkout'
  String onboardingStage = 'account';

  /// Used in the Select city dropdown when no city is found for a country
  List<String> emptyCity = ['Cities not found'];
  void addToEmptyCity(String item) => emptyCity.add(item);
  void removeFromEmptyCity(String item) => emptyCity.remove(item);
  void removeAtIndexFromEmptyCity(int index) => emptyCity.removeAt(index);
  void insertAtIndexInEmptyCity(int index, String item) =>
      emptyCity.insert(index, item);
  void updateEmptyCityAtIndex(int index, Function(String) updateFn) =>
      emptyCity[index] = updateFn(emptyCity[index]);

  /// True if account is created successfully but false it it failed
  bool createAccountState = false;

  String? idempotencyKey;

  ///  State fields for stateful widgets in this page.

  // Model for pinCode component.
  late PinCodeModel pinCodeModel;
  // Stores action output result for [Custom Action - cAOtpVerify] action in pinCode widget.
  bool? isVerified;
  // Stores action output result for [Custom Action - cAOtpStart] action in pinCode widget.
  dynamic? otpChallengeData2;
  // State field(s) for emailAddress widget.
  FocusNode? emailAddressFocusNode;
  TextEditingController? emailAddressTextController;
  String? Function(BuildContext, String?)? emailAddressTextControllerValidator;
  // State field(s) for password widget.
  FocusNode? passwordFocusNode;
  TextEditingController? passwordTextController;
  late bool passwordVisibility;
  String? Function(BuildContext, String?)? passwordTextControllerValidator;
  // State field(s) for passwordConfirm widget.
  FocusNode? passwordConfirmFocusNode;
  TextEditingController? passwordConfirmTextController;
  late bool passwordConfirmVisibility;
  String? Function(BuildContext, String?)?
      passwordConfirmTextControllerValidator;
  // State field(s) for FirstName widget.
  FocusNode? firstNameFocusNode;
  TextEditingController? firstNameTextController;
  String? Function(BuildContext, String?)? firstNameTextControllerValidator;
  // State field(s) for middleName widget.
  FocusNode? middleNameFocusNode;
  TextEditingController? middleNameTextController;
  String? Function(BuildContext, String?)? middleNameTextControllerValidator;
  // State field(s) for lastName widget.
  FocusNode? lastNameFocusNode;
  TextEditingController? lastNameTextController;
  String? Function(BuildContext, String?)? lastNameTextControllerValidator;
  // State field(s) for gender widget.
  FormFieldController<String>? genderValueController;
  DateTime? datePicked;
  // State field(s) for orgName widget.
  FocusNode? orgNameFocusNode;
  TextEditingController? orgNameTextController;
  String? Function(BuildContext, String?)? orgNameTextControllerValidator;
  // State field(s) for streetAddress widget.
  FocusNode? streetAddressFocusNode;
  TextEditingController? streetAddressTextController;
  String? Function(BuildContext, String?)? streetAddressTextControllerValidator;
  // State field(s) for country widget.
  String? countryValue;
  FormFieldController<String>? countryValueController;
  // State field(s) for city widget.
  FocusNode? cityFocusNode;
  TextEditingController? cityTextController;
  String? Function(BuildContext, String?)? cityTextControllerValidator;
  // State field(s) for stateProv widget.
  FocusNode? stateProvFocusNode;
  TextEditingController? stateProvTextController;
  String? Function(BuildContext, String?)? stateProvTextControllerValidator;
  // State field(s) for postalCode widget.
  FocusNode? postalCodeFocusNode;
  TextEditingController? postalCodeTextController;
  String? Function(BuildContext, String?)? postalCodeTextControllerValidator;
  // State field(s) for contactFirstName widget.
  FocusNode? contactFirstNameFocusNode;
  TextEditingController? contactFirstNameTextController;
  String? Function(BuildContext, String?)?
      contactFirstNameTextControllerValidator;
  // State field(s) for contactLastName widget.
  FocusNode? contactLastNameFocusNode;
  TextEditingController? contactLastNameTextController;
  String? Function(BuildContext, String?)?
      contactLastNameTextControllerValidator;
  // State field(s) for contactEmail widget.
  FocusNode? contactEmailFocusNode;
  TextEditingController? contactEmailTextController;
  String? Function(BuildContext, String?)? contactEmailTextControllerValidator;
  // State field(s) for contactPhone widget.
  FocusNode? contactPhoneFocusNode;
  TextEditingController? contactPhoneTextController;
  String? Function(BuildContext, String?)? contactPhoneTextControllerValidator;
  // State field(s) for assetLimit widget.
  FocusNode? assetLimitFocusNode;
  TextEditingController? assetLimitTextController;
  String? Function(BuildContext, String?)? assetLimitTextControllerValidator;
  Stream<List<SubscriptionsRow>>? containerSupabaseStream;
  // Stores action output result for [Custom Action - caCreateAccount] action in Button widget.
  dynamic? createAccountResults;
  // Stores action output result for [Custom Action - cAOtpStart] action in Button widget.
  dynamic? otpChallengeData;
  // Stores action output result for [Custom Action - cAUpsertOnboardingV3] action in Button widget.
  String? cAUpsertOnbordingOrgID;
  // Stores action output result for [Custom Action - cAUpsertOnboardingV3] action in Button widget.
  String? cAUpsertOnbordingOrgID2;
  // Stores action output result for [Custom Action - cAUpsertOnboardingV3] action in Button widget.
  String? cAUpsertOnbordingOrgID3;
  // Model for snackbar component.
  late SnackbarModel snackbarModel;

  @override
  void initState(BuildContext context) {
    pinCodeModel = createModel(context, () => PinCodeModel());
    passwordVisibility = false;
    passwordConfirmVisibility = false;
    snackbarModel = createModel(context, () => SnackbarModel());
  }

  @override
  void dispose() {
    pinCodeModel.dispose();
    emailAddressFocusNode?.dispose();
    emailAddressTextController?.dispose();

    passwordFocusNode?.dispose();
    passwordTextController?.dispose();

    passwordConfirmFocusNode?.dispose();
    passwordConfirmTextController?.dispose();

    firstNameFocusNode?.dispose();
    firstNameTextController?.dispose();

    middleNameFocusNode?.dispose();
    middleNameTextController?.dispose();

    lastNameFocusNode?.dispose();
    lastNameTextController?.dispose();

    orgNameFocusNode?.dispose();
    orgNameTextController?.dispose();

    streetAddressFocusNode?.dispose();
    streetAddressTextController?.dispose();

    cityFocusNode?.dispose();
    cityTextController?.dispose();

    stateProvFocusNode?.dispose();
    stateProvTextController?.dispose();

    postalCodeFocusNode?.dispose();
    postalCodeTextController?.dispose();

    contactFirstNameFocusNode?.dispose();
    contactFirstNameTextController?.dispose();

    contactLastNameFocusNode?.dispose();
    contactLastNameTextController?.dispose();

    contactEmailFocusNode?.dispose();
    contactEmailTextController?.dispose();

    contactPhoneFocusNode?.dispose();
    contactPhoneTextController?.dispose();

    assetLimitFocusNode?.dispose();
    assetLimitTextController?.dispose();

    snackbarModel.dispose();
  }

  /// Additional helper methods.
  String? get genderValue => genderValueController?.value;
}
