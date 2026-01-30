///
//  Generated code. Do not modify.
//  source: temperature.proto
//
// @dart = 2.12
// ignore_for_file: annotate_overrides,camel_case_types,constant_identifier_names,directives_ordering,library_prefixes,non_constant_identifier_names,prefer_final_fields,return_of_invalid_type,unnecessary_const,unnecessary_import,unnecessary_this,unused_import,unused_shown_name

import 'dart:async' as $async;

import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'temperature.pb.dart' as $0;
export 'temperature.pb.dart';

class TemperatureConverterClient extends $grpc.Client {
  static final _$convertToCelsius =
      $grpc.ClientMethod<$0.TemperatureRequest, $0.TemperatureResponse>(
          '/temperature.TemperatureConverter/ConvertToCelsius',
          ($0.TemperatureRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.TemperatureResponse.fromBuffer(value));
  static final _$convertToFahrenheit =
      $grpc.ClientMethod<$0.TemperatureRequest, $0.TemperatureResponse>(
          '/temperature.TemperatureConverter/ConvertToFahrenheit',
          ($0.TemperatureRequest value) => value.writeToBuffer(),
          ($core.List<$core.int> value) =>
              $0.TemperatureResponse.fromBuffer(value));

  TemperatureConverterClient($grpc.ClientChannel channel,
      {$grpc.CallOptions? options,
      $core.Iterable<$grpc.ClientInterceptor>? interceptors})
      : super(channel, options: options, interceptors: interceptors);

  $grpc.ResponseFuture<$0.TemperatureResponse> convertToCelsius(
      $0.TemperatureRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$convertToCelsius, request, options: options);
  }

  $grpc.ResponseFuture<$0.TemperatureResponse> convertToFahrenheit(
      $0.TemperatureRequest request,
      {$grpc.CallOptions? options}) {
    return $createUnaryCall(_$convertToFahrenheit, request, options: options);
  }
}

abstract class TemperatureConverterServiceBase extends $grpc.Service {
  $core.String get $name => 'temperature.TemperatureConverter';

  TemperatureConverterServiceBase() {
    $addMethod(
        $grpc.ServiceMethod<$0.TemperatureRequest, $0.TemperatureResponse>(
            'ConvertToCelsius',
            convertToCelsius_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.TemperatureRequest.fromBuffer(value),
            ($0.TemperatureResponse value) => value.writeToBuffer()));
    $addMethod(
        $grpc.ServiceMethod<$0.TemperatureRequest, $0.TemperatureResponse>(
            'ConvertToFahrenheit',
            convertToFahrenheit_Pre,
            false,
            false,
            ($core.List<$core.int> value) =>
                $0.TemperatureRequest.fromBuffer(value),
            ($0.TemperatureResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.TemperatureResponse> convertToCelsius_Pre(
      $grpc.ServiceCall call,
      $async.Future<$0.TemperatureRequest> request) async {
    return convertToCelsius(call, await request);
  }

  $async.Future<$0.TemperatureResponse> convertToFahrenheit_Pre(
      $grpc.ServiceCall call,
      $async.Future<$0.TemperatureRequest> request) async {
    return convertToFahrenheit(call, await request);
  }

  $async.Future<$0.TemperatureResponse> convertToCelsius(
      $grpc.ServiceCall call, $0.TemperatureRequest request);
  $async.Future<$0.TemperatureResponse> convertToFahrenheit(
      $grpc.ServiceCall call, $0.TemperatureRequest request);
}
