//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//
// @dart=2.18

// ignore_for_file: unused_element, unused_import
// ignore_for_file: always_put_required_named_parameters_first
// ignore_for_file: constant_identifier_names
// ignore_for_file: lines_longer_than_80_chars

library openapi.api;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:meta/meta.dart';

part 'api_client.dart';
part 'api_helper.dart';
part 'api_exception.dart';
part 'auth/authentication.dart';
part 'auth/api_key_auth.dart';
part 'auth/oauth.dart';
part 'auth/http_basic_auth.dart';
part 'auth/http_bearer_auth.dart';

part 'api/default_api.dart';

part 'model/app_info.dart';
part 'model/content.dart';
part 'model/content_parts_inner.dart';
part 'model/content_parts_inner_one_of.dart';
part 'model/content_parts_inner_one_of1.dart';
part 'model/content_parts_inner_one_of1_inline_data.dart';
part 'model/content_parts_inner_one_of2.dart';
part 'model/content_parts_inner_one_of2_function_call.dart';
part 'model/content_parts_inner_one_of3.dart';
part 'model/content_parts_inner_one_of3_function_response.dart';
part 'model/create_session_request.dart';
part 'model/event.dart';
part 'model/event_actions.dart';
part 'model/event_actions_function_calls_inner.dart';
part 'model/event_actions_function_responses_inner.dart';
part 'model/get200_response.dart';
part 'model/list_apps_get200_response.dart';
part 'model/list_apps_response.dart';
part 'model/run_agent_request.dart';
part 'model/session.dart';

/// An [ApiClient] instance that uses the default values obtained from
/// the OpenAPI specification file.
var defaultApiClient = ApiClient();

const _delimiters = {'csv': ',', 'ssv': ' ', 'tsv': '\t', 'pipes': '|'};
const _dateEpochMarker = 'epoch';
const _deepEquality = DeepCollectionEquality();
final _dateFormatter = DateFormat('yyyy-MM-dd');
final _regList = RegExp(r'^List<(.*)>$');
final _regSet = RegExp(r'^Set<(.*)>$');
final _regMap = RegExp(r'^Map<String,(.*)>$');

bool _isEpochMarker(String? pattern) =>
    pattern == _dateEpochMarker || pattern == '/$_dateEpochMarker/';
