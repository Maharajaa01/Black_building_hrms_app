import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Strongly-typed access to environment variables loaded from `.env`.
class Env {
  Env._();

  static late final String apiBaseUrl;
  static late final String apiKey;
  static late final String apiSecret;
  static late final String appEnv;
  static late final double officeLatitude;
  static late final double officeLongitude;
  static late final double officeRadiusMeters;

  static void init() {
    apiBaseUrl = _required('API_BASE_URL');
    apiKey = dotenv.maybeGet('API_KEY') ?? '';
    apiSecret = dotenv.maybeGet('API_SECRET') ?? '';
    appEnv = dotenv.maybeGet('APP_ENV') ?? 'dev';
    officeLatitude = double.tryParse(dotenv.maybeGet('OFFICE_LATITUDE') ?? '') ?? 0;
    officeLongitude = double.tryParse(dotenv.maybeGet('OFFICE_LONGITUDE') ?? '') ?? 0;
    officeRadiusMeters =
        double.tryParse(dotenv.maybeGet('OFFICE_RADIUS_METERS') ?? '') ?? 200;
  }

  static bool get isProd => appEnv == 'prod';
  static bool get hasGeofence => officeLatitude != 0 && officeLongitude != 0;

  static String _required(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw StateError('Missing required env var: $key. Check your .env file.');
    }
    return value;
  }
}
