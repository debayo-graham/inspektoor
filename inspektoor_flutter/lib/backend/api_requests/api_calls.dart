import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import '/flutter_flow/flutter_flow_util.dart';
import 'api_manager.dart';

export 'api_manager.dart' show ApiCallResponse;

const _kPrivateApiFunctionName = 'ffPrivateApiCall';

class GetCountriesCall {
  static Future<ApiCallResponse> call() async {
    return ApiManager.instance.makeApiCall(
      callName: 'get countries',
      apiUrl: 'https://countriesnow.space/api/v0.1/countries/positions',
      callType: ApiCallType.GET,
      headers: {
        'Content-Type': 'application/json',
      },
      params: {},
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static List<String>? countryName(dynamic response) => (getJsonField(
        response,
        r'''$.data[:].name''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class GetCitiesCall {
  static Future<ApiCallResponse> call({
    String? cityParam = '',
  }) async {
    final ffApiRequestBody = '''
{
  "country": "${escapeStringForJson(cityParam)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'get cities',
      apiUrl: 'https://countriesnow.space/api/v0.1/countries/cities',
      callType: ApiCallType.POST,
      headers: {
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static List<String>? cities(dynamic response) => (getJsonField(
        response,
        r'''$.data''',
        true,
      ) as List?)
          ?.withoutNulls
          .map((x) => castToType<String>(x))
          .withoutNulls
          .toList();
}

class CreateStripeCheckoutSessionCall {
  static Future<ApiCallResponse> call({
    String? planId = '',
    String? orgId = '',
    int? quantity,
  }) async {
    final ffApiRequestBody = '''
{
  "plan_id": "${escapeStringForJson(planId)}",
  "org_id": "${escapeStringForJson(orgId)}",
  "quantity": ${quantity}
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Create Stripe Checkout Session',
      apiUrl:
          'https://euiunuinyrsafjprcnzc.supabase.co/functions/v1/stripe-checkout',
      callType: ApiCallType.POST,
      headers: {
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV1aXVudWlueXJzYWZqcHJjbnpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ4MzQ5MjUsImV4cCI6MjA3MDQxMDkyNX0.YkO3nyt6V99HvdbKsaTsp0lZ7-IulKFqejPUVlEr8rE',
        'Content-Type': 'application/json',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? sripeCheckoutURL(dynamic response) =>
      castToType<String>(getJsonField(
        response,
        r'''$.url''',
      ));
}

class SearchInspectionFormTemplatesCall {
  static Future<ApiCallResponse> call({
    String? pOrg = '',
    String? pScope = '',
    String? pQ = '',
    String? pCategory = '',
    int? pLimit,
    int? pOffset,
    String? pSortBy = '',
    String? pSortDir = '',
    String? userAccessToken = '',
  }) async {
    final ffApiRequestBody = '''
{
  "p_org": "${escapeStringForJson(pOrg)}",
  "p_scope": "${escapeStringForJson(pScope)}",
  "p_q": "${escapeStringForJson(pQ)}",
  "p_category": "${escapeStringForJson(pCategory)}",
  "p_limit": ${pLimit},
  "p_offset": ${pOffset},
  "p_sort_by": "${escapeStringForJson(pSortBy)}",
  "p_sort_dir": "${escapeStringForJson(pSortDir)}"
}''';
    return ApiManager.instance.makeApiCall(
      callName: 'Search Inspection Form Templates',
      apiUrl:
          'https://euiunuinyrsafjprcnzc.supabase.co/rest/v1/rpc/search_inspection_templates',
      callType: ApiCallType.POST,
      headers: {
        'Authorization': 'Bearer ${userAccessToken}',
        'Content-Type': 'application/json',
        'apikey':
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImV1aXVudWlueXJzYWZqcHJjbnpjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ4MzQ5MjUsImV4cCI6MjA3MDQxMDkyNX0.YkO3nyt6V99HvdbKsaTsp0lZ7-IulKFqejPUVlEr8rE',
      },
      params: {},
      body: ffApiRequestBody,
      bodyType: BodyType.JSON,
      returnBody: true,
      encodeBodyUtf8: false,
      decodeUtf8: false,
      cache: false,
      isStreamingApi: false,
      alwaysAllowBody: false,
    );
  }

  static String? id(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].id''',
      ));
  static String? orgId(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].org_id''',
      ));
  static String? name(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].name''',
      ));
  static String? category(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].category''',
      ));
  static int? version(dynamic response) => castToType<int>(getJsonField(
        response,
        r'''$[:].version''',
      ));
  static bool? isActive(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$[:].is_active''',
      ));
  static String? createdAt(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].created_at''',
      ));
  static bool? isPredefiined(dynamic response) => castToType<bool>(getJsonField(
        response,
        r'''$[:].is_predefined''',
      ));
  static String? createdBy(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].created_by''',
      ));
  static String? creatorFN(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].creator_first_name''',
      ));
  static String? creatorLN(dynamic response) => castToType<String>(getJsonField(
        response,
        r'''$[:].creator_last_name''',
      ));
}

class ApiPagingParams {
  int nextPageNumber = 0;
  int numItems = 0;
  dynamic lastResponse;

  ApiPagingParams({
    required this.nextPageNumber,
    required this.numItems,
    required this.lastResponse,
  });

  @override
  String toString() =>
      'PagingParams(nextPageNumber: $nextPageNumber, numItems: $numItems, lastResponse: $lastResponse,)';
}

String _toEncodable(dynamic item) {
  return item;
}

String _serializeList(List? list) {
  list ??= <String>[];
  try {
    return json.encode(list, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("List serialization failed. Returning empty list.");
    }
    return '[]';
  }
}

String _serializeJson(dynamic jsonVar, [bool isList = false]) {
  jsonVar ??= (isList ? [] : {});
  try {
    return json.encode(jsonVar, toEncodable: _toEncodable);
  } catch (_) {
    if (kDebugMode) {
      print("Json serialization failed. Returning empty json.");
    }
    return isList ? '[]' : '{}';
  }
}

String? escapeStringForJson(String? input) {
  if (input == null) {
    return null;
  }
  return input
      .replaceAll('\\', '\\\\')
      .replaceAll('"', '\\"')
      .replaceAll('\n', '\\n')
      .replaceAll('\t', '\\t');
}
