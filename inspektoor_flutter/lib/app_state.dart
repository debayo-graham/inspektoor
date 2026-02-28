import 'package:flutter/material.dart';
import 'flutter_flow/request_manager.dart';
import '/backend/api_requests/api_manager.dart';
import 'backend/supabase/supabase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'dart:convert';

class FFAppState extends ChangeNotifier {
  static FFAppState _instance = FFAppState._internal();

  factory FFAppState() {
    return _instance;
  }

  FFAppState._internal();

  static void reset() {
    _instance = FFAppState._internal();
  }

  Future initializePersistedState() async {}

  void update(VoidCallback callback) {
    callback();
    notifyListeners();
  }

  String _displayName = '';
  String get displayName => _displayName;
  set displayName(String value) {
    _displayName = value;
  }

  String _selectedMenuKey = 'homePage';
  String get selectedMenuKey => _selectedMenuKey;
  set selectedMenuKey(String value) {
    _selectedMenuKey = value;
  }

  String _expandedMenuKey = '';
  String get expandedMenuKey => _expandedMenuKey;
  set expandedMenuKey(String value) {
    _expandedMenuKey = value;
  }

  String _snackbarMsg = '';
  String get snackbarMsg => _snackbarMsg;
  set snackbarMsg(String value) {
    _snackbarMsg = value;
  }

  Color _snackbarColor = Colors.transparent;
  Color get snackbarColor => _snackbarColor;
  set snackbarColor(Color value) {
    _snackbarColor = value;
  }

  bool _showSnackbar = false;
  bool get showSnackbar => _showSnackbar;
  set showSnackbar(bool value) {
    _showSnackbar = value;
  }

  String _currentOrgId = '';
  String get currentOrgId => _currentOrgId;
  set currentOrgId(String value) {
    _currentOrgId = value;
  }

  String _entitlementStatus = '';
  String get entitlementStatus => _entitlementStatus;
  set entitlementStatus(String value) {
    _entitlementStatus = value;
  }

  int _assetLimit = 0;
  int get assetLimit => _assetLimit;
  set assetLimit(int value) {
    _assetLimit = value;
  }

  dynamic _features;
  dynamic get features => _features;
  set features(dynamic value) {
    _features = value;
  }

  String _planId = '';
  String get planId => _planId;
  set planId(String value) {
    _planId = value;
  }

  String _stripeSubId = '';
  String get stripeSubId => _stripeSubId;
  set stripeSubId(String value) {
    _stripeSubId = value;
  }

  int _periodIndex = 0;
  int get periodIndex => _periodIndex;
  set periodIndex(int value) {
    _periodIndex = value;
  }

  DateTime? _rangeStart;
  DateTime? get rangeStart => _rangeStart;
  set rangeStart(DateTime? value) {
    _rangeStart = value;
  }

  DateTime? _rangeEnd;
  DateTime? get rangeEnd => _rangeEnd;
  set rangeEnd(DateTime? value) {
    _rangeEnd = value;
  }

  String _periodKey = 'today';
  String get periodKey => _periodKey;
  set periodKey(String value) {
    _periodKey = value;
  }

  String _userAccessToken = '';
  String get userAccessToken => _userAccessToken;
  set userAccessToken(String value) {
    _userAccessToken = value;
  }

  String _inspectionDraftJson = '';
  String get inspectionDraftJson => _inspectionDraftJson;
  set inspectionDraftJson(String value) {
    _inspectionDraftJson = value;
  }

  String _templateJson = '';
  String get templateJson => _templateJson;
  set templateJson(String value) {
    _templateJson = value;
  }

  int _currentInspectionIndex = 0;
  int get currentInspectionIndex => _currentInspectionIndex;
  set currentInspectionIndex(int value) {
    _currentInspectionIndex = value;
  }

  String _snackbarMessage = '';
  String get snackbarMessage => _snackbarMessage;
  set snackbarMessage(String value) {
    _snackbarMessage = value;
  }

  Color _snackbarBg = Color(4285971859);
  Color get snackbarBg => _snackbarBg;
  set snackbarBg(Color value) {
    _snackbarBg = value;
  }

  Color _snackbarText = Color(4294967295);
  Color get snackbarText => _snackbarText;
  set snackbarText(Color value) {
    _snackbarText = value;
  }

  int _snackbarDurationMs = 2500;
  int get snackbarDurationMs => _snackbarDurationMs;
  set snackbarDurationMs(int value) {
    _snackbarDurationMs = value;
  }

  int _snackbarTrigger = 0;
  int get snackbarTrigger => _snackbarTrigger;
  set snackbarTrigger(int value) {
    _snackbarTrigger = value;
  }

  final _listOfCountryCacheManager = FutureRequestManager<ApiCallResponse>();
  Future<ApiCallResponse> listOfCountryCache({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<ApiCallResponse> Function() requestFn,
  }) =>
      _listOfCountryCacheManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearListOfCountryCacheCache() => _listOfCountryCacheManager.clear();
  void clearListOfCountryCacheCacheKey(String? uniqueKey) =>
      _listOfCountryCacheManager.clearRequest(uniqueKey);

  final _assetDahbosrdCacheManager = FutureRequestManager<List<AssetsRow>>();
  Future<List<AssetsRow>> assetDahbosrdCache({
    String? uniqueQueryKey,
    bool? overrideCache,
    required Future<List<AssetsRow>> Function() requestFn,
  }) =>
      _assetDahbosrdCacheManager.performRequest(
        uniqueQueryKey: uniqueQueryKey,
        overrideCache: overrideCache,
        requestFn: requestFn,
      );
  void clearAssetDahbosrdCacheCache() => _assetDahbosrdCacheManager.clear();
  void clearAssetDahbosrdCacheCacheKey(String? uniqueKey) =>
      _assetDahbosrdCacheManager.clearRequest(uniqueKey);
}

Color? _colorFromIntValue(int? val) {
  if (val == null) {
    return null;
  }
  return Color(val);
}
