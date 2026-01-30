///
//  Generated code. Do not modify.
//  source: temperature.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,deprecated_member_use_from_same_package,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:core' as $core;
import 'dart:convert' as $convert;
import 'dart:typed_data' as $typed_data;
@$core.Deprecated('Use temperatureRequestDescriptor instead')
const TemperatureRequest$json = const {
  '1': 'TemperatureRequest',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 1, '10': 'value'},
  ],
};

/// Descriptor for `TemperatureRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List temperatureRequestDescriptor = $convert.base64Decode('ChJUZW1wZXJhdHVyZVJlcXVlc3QSFAoFdmFsdWUYASABKAFSBXZhbHVl');
@$core.Deprecated('Use temperatureResponseDescriptor instead')
const TemperatureResponse$json = const {
  '1': 'TemperatureResponse',
  '2': const [
    const {'1': 'value', '3': 1, '4': 1, '5': 1, '10': 'value'},
    const {'1': 'unit', '3': 2, '4': 1, '5': 9, '10': 'unit'},
  ],
};

/// Descriptor for `TemperatureResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List temperatureResponseDescriptor = $convert.base64Decode('ChNUZW1wZXJhdHVyZVJlc3BvbnNlEhQKBXZhbHVlGAEgASgBUgV2YWx1ZRISCgR1bml0GAIgASgJUgR1bml0');
