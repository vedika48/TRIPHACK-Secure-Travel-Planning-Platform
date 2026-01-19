import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../models/session.dart';

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

  // Add this method to your ApiService class
  Future<Map<String, dynamic>> searchLocalCabs({
    required String departure,
    required String destination,
  }) async {
    try {
      final response = await _dio.post('/api/services/cabs/search', data: {
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

  // In ApiService
  Future<Map<String, dynamic>> generateItinerary({
    required String departureLocation,
    required String destinationLocation,
    required Map<String, String> travelDates,
    Map<String, dynamic>? userProfile,
  }) async {
    try {
      // Use the chat endpoint with a structured message
      final message = """
Generate a travel itinerary for me:
- From: $departureLocation
- To: $destinationLocation
- Dates: ${travelDates['departure']} to ${travelDates['return']}
- User profile: ${userProfile != null ? jsonEncode(userProfile) : 'Not specified'}
""";

      // You'll need a session key - create one or use an existing one
      // For now, using a placeholder - you might need to adjust this
      final sessionResponse = await createSession('itinerary_user_${DateTime.now().millisecondsSinceEpoch}');
      final sessionKey = sessionResponse['session_key'] ?? 'default_session';

      final response = await sendMessage(message, sessionKey);

      return {
        'itinerary': response['message'],
        'session_key': response['session_key'],
        'status': 'generated',
      };
    } catch (e) {
      throw Exception('Failed to generate itinerary: $e');
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
}