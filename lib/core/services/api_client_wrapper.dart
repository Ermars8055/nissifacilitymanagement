import '../network/api_client.dart';

/// Thin wrapper so offline_queue.dart doesn't create a circular dependency
class ApiClientWrapper {
  static Future<dynamic> put(String endpoint, dynamic data) =>
      ApiClient.put(endpoint, data);

  static Future<dynamic> post(String endpoint, dynamic data) =>
      ApiClient.post(endpoint, data);
}
