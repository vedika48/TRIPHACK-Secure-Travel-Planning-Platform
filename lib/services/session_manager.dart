import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/session.dart';
import 'api_service.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();
  Session? _currentSession;

  Session? get currentSession => _currentSession;

  Future<void> saveSessionKey(String sessionKey) async {
    await _storage.write(key: 'session_key', value: sessionKey);
  }

  Future<void> initializeSession([String? userId]) async {
    try {
      // Try to load existing session first
      await loadSession();

      if (_currentSession != null) {
        if (kDebugMode) {
          print('Loaded existing session: ${_currentSession!.sessionKey}');
        }
        return;
      }

      // Create new session if no existing valid session
      final newUserId = userId ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
      final sessionData = await _apiService.createSession(newUserId);

      // Convert API response to Session object
      _currentSession = Session(
        sessionKey: sessionData['session_key'] ?? '',
        userId: sessionData['user_id'] ?? newUserId,
        createdAt: sessionData['created_at'] ?? DateTime.now().toIso8601String(),
        lastActivity: sessionData['last_activity'] ?? DateTime.now().toIso8601String(),
      );

      await _saveSessionToStorage();
      if (kDebugMode) {
        print('Created new session: ${_currentSession!.sessionKey}');
      }
    } catch (e) {
      print('Failed to initialize session: $e');
      throw Exception('Failed to initialize session: $e');
    }
  }

  Future<void> loadSession() async {
    try {
      final sessionData = await _storage.read(key: 'session_data');
      if (sessionData != null) {
        final sessionMap = json.decode(sessionData);
        _currentSession = Session.fromJson(sessionMap);

        // Verify session is still valid with backend
        try {
          final verifiedSession = await _apiService.getCurrentSession(_currentSession!.sessionKey);
          _currentSession = verifiedSession; // This should be a Session object, not Map
          if (kDebugMode) {
            print('Session loaded and verified: ${_currentSession!.sessionKey}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Session verification failed: $e');
          }
          // Session might be expired, clear it
          await clearSession();
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading session: $e');
      }
      await clearSession();
    }
  }

  Future<String?> getSessionKey() async {
    if (_currentSession != null) {
      return _currentSession!.sessionKey;
    }

    // Try to load from storage if not in memory
    await loadSession();
    return _currentSession?.sessionKey;
  }

  Future<String?> getUserId() async {
    if (_currentSession != null) {
      return _currentSession!.userId;
    }

    // Try to load from storage if not in memory
    await loadSession();
    return _currentSession?.userId;
  }

  Future<void> updateSessionActivity() async {
    if (_currentSession != null) {
      // Update last activity timestamp
      final updatedSession = Session(
        sessionKey: _currentSession!.sessionKey,
        userId: _currentSession!.userId,
        createdAt: _currentSession!.createdAt,
        lastActivity: DateTime.now().toIso8601String(),
      );

      _currentSession = updatedSession;
      await _saveSessionToStorage();

      if (kDebugMode) {
        print('Session activity updated: ${DateTime.now()}');
      }
    }
  }

  Future<void> clearSession() async {
    _currentSession = null;
    await _storage.delete(key: 'session_key');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'session_data');
    if (kDebugMode) {
      print('Session cleared');
    }
  }

  Future<bool> validateSession() async {
    if (_currentSession == null) {
      await loadSession();
      if (_currentSession == null) return false;
    }

    try {
      final verifiedSession = await _apiService.getCurrentSession(_currentSession!.sessionKey);
      return verifiedSession != null; // Check if session object is not null
    } catch (e) {
      if (kDebugMode) {
        print('Session validation failed: $e');
      }
      return false;
    }
  }

  // Health check for session and API connectivity
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final health = await _apiService.healthCheck();
      final sessionValid = await validateSession();

      return {
        'api_healthy': health['status'] == 'healthy',
        'session_valid': sessionValid,
        'session_key': _currentSession?.sessionKey.substring(0, 8) ?? 'None',
        'user_id': _currentSession?.userId ?? 'None',
        'session_loaded': _currentSession != null,
      };
    } catch (e) {
      return {
        'api_healthy': false,
        'session_valid': false,
        'session_loaded': _currentSession != null,
        'error': e.toString(),
      };
    }
  }

  // Helper method to save session to secure storage
  Future<void> _saveSessionToStorage() async {
    if (_currentSession != null) {
      await _storage.write(key: 'session_key', value: _currentSession!.sessionKey);
      await _storage.write(key: 'user_id', value: _currentSession!.userId);
      await _storage.write(key: 'session_data', value: json.encode(_currentSession!.toJson()));
    }
  }

  void dispose() {
    // Cleanup resources if needed
  }
}