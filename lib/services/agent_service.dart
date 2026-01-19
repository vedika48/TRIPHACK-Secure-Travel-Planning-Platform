import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/session.dart';
import '../models/trip_plan.dart';

class ApiService {
  static const String baseUrl = 'https://travel-agent-2.onrender.com';
  final Dio _dio = Dio();

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.headers['Content-Type'] = 'application/json';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);

    // Add interceptors for better debugging
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (object) => debugPrint(object.toString()),
    ));
  }

  // Session Management
  Future<Map<String, dynamic>> createSession(String userId) async {
    try {
      final response = await _dio.post('/api/travel/sessions/create', data: {
        'user_id': userId,
      });
      return response.data;
    } catch (e) {
      throw Exception('Session creation failed: $e');
    }
  }

  Future<Session> getCurrentSession(String sessionKey) async {
    try {
      final response = await _dio.get('/api/travel/sessions/current/$sessionKey');
      return Session.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get current session: $e');
    }
  }

  // Trip Planning APIs
  Future<TripPlan> generateItinerary({
    required String departureLocation,
    required String destinationLocation,
    required Map<String, String> travelDates,
    Map<String, dynamic>? userProfile,
  }) async {
    try {
      final response = await _dio.post('/api/travel/itinerary/generate', data: {
        'departure_location': departureLocation,
        'destination_location': destinationLocation,
        'travel_dates': travelDates,
        'user_profile': userProfile ?? {},
      });
      return TripPlan.fromMap(response.data);
    } catch (e) {
      throw Exception('Failed to generate itinerary: $e');
    }
  }

  // Flight Search with enhanced error handling
  Future<Map<String, dynamic>> searchFlights({
    required String departure,
    required String destination,
    String? date,
  }) async {
    try {
      final response = await _dio.post('/api/services/flights/search', data: {
        'departure': departure,
        'destination': destination,
        'date': date,
      });
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception('Server is taking too long to respond. Please try again.');
      } else if (e.response != null) {
        throw Exception('Server error: ${e.response?.statusCode}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to search flights: $e');
    }
  }

  // Hotel Search
  Future<Map<String, dynamic>> searchHotels({
    required String destination,
    String? checkin,
    String? checkout,
  }) async {
    try {
      final response = await _dio.post('/api/services/hotels/search', data: {
        'destination': destination,
        'checkin': checkin,
        'checkout': checkout,
      });
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.response != null) {
        throw Exception('Server error: ${e.response?.statusCode}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to search hotels: $e');
    }
  }

  // Transportation Search
  Future<Map<String, dynamic>> searchTransportation({
    required String departure,
    required String destination,
    String? date,
  }) async {
    try {
      final response = await _dio.post('/api/services/transport/search', data: {
        'departure': departure,
        'destination': destination,
        'date': date,
      });
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.response != null) {
        throw Exception('Server error: ${e.response?.statusCode}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to search transportation: $e');
    }
  }

  // Local Cab Search
  Future<Map<String, dynamic>> searchLocalCabs({
    required String departure,
    required String destination,
  }) async {
    try {
      final response = await _dio.post('/api/services/cabs/local', data: {
        'departure': departure,
        'destination': destination,
      });
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.response != null) {
        throw Exception('Server error: ${e.response?.statusCode}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to search local cabs: $e');
    }
  }

  // Travel Guide
  Future<Map<String, dynamic>> getTravelGuide(String destination) async {
    try {
      final response = await _dio.post('/api/travel/guide', data: {
        'destination': destination,
      });
      return response.data;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Connection timeout. Please check your internet connection.');
      } else if (e.response != null) {
        throw Exception('Server error: ${e.response?.statusCode}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to get travel guide: $e');
    }
  }

  // Chat API
  Future<Map<String, dynamic>> sendMessage(String message, String sessionKey) async {
    try {
      final response = await _dio.post('/api/chat/message', data: {
        'message': message,
        'session_key': sessionKey,
      });

      return {
        'message': response.data['response'] ?? 'No response received',
        'session_key': response.data['session_key'] ?? sessionKey,
        'timestamp': response.data['timestamp'] ?? DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Health Check
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.data;
    } catch (e) {
      throw Exception('Health check failed: $e');
    }
  }

  // Additional utility methods that might be needed
  Future<Map<String, dynamic>> getDestinationInfo(String destination) async {
    try {
      final response = await _dio.get('/api/travel/destination/$destination');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get destination info: $e');
    }
  }

  Future<Map<String, dynamic>> getWeatherForecast({
    required String destination,
    required String date,
  }) async {
    try {
      final response = await _dio.post('/api/services/weather', data: {
        'destination': destination,
        'date': date,
      });
      return response.data;
    } catch (e) {
      throw Exception('Failed to get weather forecast: $e');
    }
  }

  Future<Map<String, dynamic>> getExchangeRates() async {
    try {
      final response = await _dio.get('/api/services/currency');
      return response.data;
    } catch (e) {
      throw Exception('Failed to get exchange rates: $e');
    }
  }
}