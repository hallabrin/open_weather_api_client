import '../../Utilities/general_enums.dart';
import '../../Utilities/unit_conversions.dart';
import '../../Utilities/units_settings.dart';

class OneCallCurrentWeather {
  WeatherType? weatherType;
  String? mainDescription;
  String? secondaryDescription;

  num? temp;
  num? feelsLikeTemp;
  num? dewPoint;

  num? humidity;
  num? cloudiness;

  num? uvi;
  num? visibility;
  num? pressure;

  num? windSpeed;
  int? windDegree;
  num? windGustSpeed;

  num? rainAmountLast1h;

  num? snowAmountLast1h;

  DateTime? sunrise;
  DateTime? sunset;
  DateTime? timeStamp;

  OneCallCurrentWeather({
    this.weatherType,
    this.mainDescription,
    this.secondaryDescription,
    this.temp,
    this.feelsLikeTemp,
    this.dewPoint,
    this.humidity,
    this.cloudiness,
    this.uvi,
    this.visibility,
    this.pressure,
    this.windSpeed,
    this.windDegree,
    this.windGustSpeed,
    this.rainAmountLast1h,
    this.snowAmountLast1h,
    this.sunrise,
    this.sunset,
    this.timeStamp,
  });

  /// JSON deserialization constructor
  factory OneCallCurrentWeather.fromJson(
    Map<String, dynamic> json,
    UnitSettings settings,
  ) {
    // Mapping the iconId and ID to a WeatherType enum
    WeatherType weatherType = infoToWeatherType(
      id: json['weather'][0]['id'],
      iconId: json['weather'][0]['icon'],
    );

    // Formatting temperature
    num? temp = temperatureToSelectedUnit(
      temp: json['temp'],
      unit: settings.temperatureUnit,
    );

    // Formatting feels like temperature
    num? feelsLikeTemp = temperatureToSelectedUnit(
      temp: json['feels_like'],
      unit: settings.temperatureUnit,
    );

    // Formatting feels like temperature
    num? dewPoint = temperatureToSelectedUnit(
      temp: json['dew_point'],
      unit: settings.temperatureUnit,
    );

    // Formatting the pressure
    num pressure = pressureToSelectedUnit(
      pressure: json['pressure'],
      unit: settings.pressureUnit,
    );

    // Formatting the wind speed
    num? windSpeed = windSpeedToSelectedUnit(
      windSpeed: json['wind_speed'],
      unit: settings.windSpeedUnit,
    );

    // Formatting the gust speed
    num? windGustSpeed = windSpeedToSelectedUnit(
      windSpeed: json['wind_gust'],
      unit: settings.windSpeedUnit,
    );

    // Formatting the amount of rain
    num? rainAmountLast1h = precipitationToSelectedUnit(
      amount: json['rain']['1h'],
      unit: settings.precipitationUnit,
    );
    // Formatting the amount of snow
    num? snowAmountLast1h = precipitationToSelectedUnit(
      amount: json['snow']['1h'],
      unit: settings.precipitationUnit,
    );

    return OneCallCurrentWeather(
      weatherType: weatherType,
      mainDescription: json['weather'][0]['main'],
      secondaryDescription: json['weather'][0]['description'],
      temp: temp,
      feelsLikeTemp: feelsLikeTemp,
      dewPoint: dewPoint,
      humidity: json['humidity'],
      cloudiness: json['clouds'],
      uvi: json['uvi'],
      visibility: json['visibility'],
      pressure: pressure,
      windSpeed: windSpeed,
      windDegree: json['wind_deg'],
      windGustSpeed: windGustSpeed,
      rainAmountLast1h: rainAmountLast1h,
      snowAmountLast1h: snowAmountLast1h,
      sunrise: DateTime.fromMillisecondsSinceEpoch(
        (json['sunrise']) * 1000,
        isUtc: true,
      ),
      sunset: DateTime.fromMillisecondsSinceEpoch(
        (json['sunset']) * 1000,
        isUtc: true,
      ),
      timeStamp: DateTime.fromMillisecondsSinceEpoch(
        (json['dt']) * 1000,
        isUtc: true,
      ),
    );
  }
}
