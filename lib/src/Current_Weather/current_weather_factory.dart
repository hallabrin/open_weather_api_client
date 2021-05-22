import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_weather_api_client/src/Utilities/languages.dart';
import 'package:open_weather_api_client/src/Utilities/location_coords.dart';
import 'package:open_weather_api_client/src/Utilities/units_settings.dart';
import 'package:retry/retry.dart';
import 'package:tuple/tuple.dart';

import '../Utilities/general_enums.dart';
import '../Utilities/weather_factory_utilities.dart';
import 'current_weather_model.dart';

/// This class queries the Current Weather API endpoint, the docs to which can be found here [https://openweathermap.org/current]
class CurrentWeatherFactory {
  String apiKey;

  /// The language defaults to English
  Language language;

  /// The unit settings determine the data from the server is converted to
  UnitSettings settings;

  /// The instance of [LocationCoords] that must be provided if you want to obtain
  /// the weather using longitude and latitude
  LocationCoords? locationCoords;

  /// Used when you want to obtain the weather using a city name instead of longitude and latitude
  /// IMPORTANT: In some rare cases, two different cities from different parts of the world
  /// may have the same name. In this case, it is unpredictable which city's forecast you may
  /// receive.
  /// If you happen to successfully receive results but find on checking them that they are wildly
  /// different from what they should be (and have through sheer frustration have reached all the way here,
  /// in which case, Hi!) consider doing the same query with equivalent longitude and latitude values and
  /// see if the problem persists.
  String? cityName;

  CurrentWeatherFactory({
    required this.apiKey,
    this.language = Language.ENGLISH,
    required this.settings,
    this.locationCoords,
    this.cityName,
  }) : assert(
          cityName != null || locationCoords != null,
          "A city name or an instance of LocationCoords must be provided",
        );

  /// Public function to get the weather for a given saved city
  Future<Tuple2<RequestStatus, CurrentWeather?>> getWeather() async {
    /// Initializing the utilities
    WeatherFactoryUtilities utilities = WeatherFactoryUtilities(
      apiKey: apiKey,
      language: language,
    );

    /// Checking whether connected to the internet
    InternetStatus status = await utilities.connectionCheck();
    if (status == InternetStatus.Connected) {
      if (locationCoords != null) {
        /// Handing info to be requested and returning the info
        return _geoRequest(
          coords: LocationCoords(
            latitude: locationCoords!.latitude,
            longitude: locationCoords!.longitude,
          ),
        );
      } else {
        if (cityName!.isEmpty == true) {
          /// Checking for empty text (This is not usually an issue if the text is provided programmatically,
          /// but if the factory is hooked up directly to a TextField widget, and the user accidentally presses
          /// send on an empty widget, an empty String may be passed here
          return Tuple2(RequestStatus.EmptyError, null);
        } else {
          /// Handing info to be requested and returning the info
          _sanitizeInput(cityName: cityName!);
          return _namedRequest(cityName: cityName!);
        }
      }
    } else {
      /// There is a connection error as connectionCheck() returned InternetStatus.Disconnected
      return Tuple2(RequestStatus.ConnectionError, null);
    }
  }

  /// Helper function for named queries
  Future<Tuple2<RequestStatus, CurrentWeather?>> _namedRequest(
      {required String cityName}) async {
    WeatherFactoryUtilities utilities =
        WeatherFactoryUtilities(apiKey: apiKey, language: language);
    Uri request = utilities.buildURL(
        requestType: RequestType.CurrentWeather, cityName: cityName);

    /// Handling timeout error
    RetryOptions r = RetryOptions(
        delayFactor: Duration(
          milliseconds: 150,
        ),
        maxAttempts: 4,
        maxDelay: Duration(seconds: 2),
        randomizationFactor: 0.2);

    dynamic response;
    try {
      response = await r.retry(
        () {
          return http.get(request).timeout(
                Duration(seconds: 3),
              );
        },
        retryIf: (e) => e is SocketException || e is TimeoutException,
      );
    } on SocketException {
      return Tuple2(RequestStatus.UnknownError, null);
    } on TimeoutException {
      return Tuple2(RequestStatus.TimeoutError, null);
    } catch (e) {
      return Tuple2(RequestStatus.UnknownError, null);
    }
    final payLoad = json.decode(response.body) as Map<String, dynamic>;

    /// Checking for error status codes from server response
    return _checkForErrors(payLoad: payLoad);
  }

  /// Helper function for formatting the cityName for named queries
  String _sanitizeInput({required String cityName}) {
    cityName.toLowerCase();
    cityName.trim();
    return cityName;
  }

  /// Helper function for location queries
  Future<Tuple2<RequestStatus, CurrentWeather?>> _geoRequest(
      {required LocationCoords coords}) async {
    WeatherFactoryUtilities utilities = WeatherFactoryUtilities(
      apiKey: apiKey,
      language: language,
    );
    Uri request = utilities.buildURL(
      requestType: RequestType.CurrentWeather,
      location: coords,
    );

    /// Handling timeout error
    RetryOptions r = RetryOptions(
        delayFactor: Duration(
          milliseconds: 150,
        ),
        maxAttempts: 4,
        maxDelay: Duration(seconds: 2),
        randomizationFactor: 0.2);

    dynamic response;
    try {
      response = await r.retry(
        () {
          return http.get(request).timeout(
                Duration(seconds: 3),
              );
        },
        retryIf: (e) => e is SocketException || e is TimeoutException,
      );
    } on SocketException {
      return Tuple2(RequestStatus.UnknownError, null);
    } on TimeoutException {
      return Tuple2(RequestStatus.TimeoutError, null);
    } catch (e) {
      return Tuple2(RequestStatus.UnknownError, null);
    }

    /// Decoding the json response
    final payLoad = json.decode(response.body) as Map<String, dynamic>;

    /// Checking for error status codes from server response
    return _checkForErrors(payLoad: payLoad);
  }

  /// Error checking function for queries
  Future<Tuple2<RequestStatus, CurrentWeather?>> _checkForErrors(
      {required Map<String, dynamic> payLoad}) async {
    if (payLoad.containsValue("404")) {
      /// This error is for when a city name with a typo or a impossible value for the longitude
      /// and latitude is sent to the server, or when (rarely) the server may not support
      /// weather queries for that location
      return Tuple2(RequestStatus.NonExistentError, null);
    } else if (payLoad.containsValue("429")) {
      /// This error is for when the API Key provided has exceeded its quota
      return Tuple2(RequestStatus.OverloadError, null);
    } else {
      CurrentWeather weather = CurrentWeather.fromJson(payLoad, settings);

      /// The request is successful
      return Tuple2(RequestStatus.Successful, weather);
    }
  }
}
