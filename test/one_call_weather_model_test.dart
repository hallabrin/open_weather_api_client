import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_weather_api_client/open_weather_api_client.dart';

void main() {
  late final response1;
  late final response2;
  late final response3;
  setUp(() async {
    response1 =
        jsonDecode(await File("test/one_call_response_1.json").readAsString());
    response2 =
        jsonDecode(await File("test/one_call_response_2.json").readAsString());
    response3 =
        jsonDecode(await File("test/one_call_response_3.json").readAsString());
  });

  test("test json parsing", () {
    final result = OneCallWeather.fromJson(response1, UnitSettings());
    expect(result, isNotNull);
    final result2 = OneCallWeather.fromJson(response2, UnitSettings());
    expect(result2, isNotNull);
    final result3 = OneCallWeather.fromJson(response3, UnitSettings());
    expect(result3, isNotNull);
  });
}
