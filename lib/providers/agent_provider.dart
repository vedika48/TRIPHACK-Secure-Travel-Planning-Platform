import 'package:flutter/foundation.dart';
import '../models/agent.dart';
import '../services/api_service.dart';

class AgentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  late final AgentService _agentService = AgentService(_apiService);

  List<Agent> _agents = [];
  Agent? _selectedAgent;
  bool _isLoading = false;
  String? _currentSessionKey;
  Map<String, dynamic>? _lastResponse;

  List<Agent> get agents => _agents;
  Agent? get selectedAgent => _selectedAgent;
  bool get isLoading => _isLoading;
  String? get currentSessionKey => _currentSessionKey;
  Map<String, dynamic>? get lastResponse => _lastResponse;

  // Initialize with session
  void initialize(String sessionKey) {
    _currentSessionKey = sessionKey;
  }

  // Load available agents
  Future<void> loadAvailableAgents() async {
    _isLoading = true;
    notifyListeners();

    try {
      _agents = await _agentService.getAvailableAgents();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading agents: $e');
      }
      _agents = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Process user query with automatic agent selection
  Future<Object> processQuery(String query, {Map<String, dynamic>? additionalData}) async {
    if (_currentSessionKey == null) {
      throw Exception('Session not initialized. Call initialize() first.');
    }

    _isLoading = true;
    notifyListeners();

    try {
      // Select appropriate agent based on query
      final agent = await _agentService.selectAgentForQuery(query);
      _selectedAgent = agent;

      // Process with selected agent
      final response = await _agentService.processWithAgent(
        agent: agent,
        query: query,
        sessionKey: _currentSessionKey!,
        additionalData: additionalData,
      );

      _lastResponse = response as Map<String, dynamic>?;
      return response;
    } catch (e) {
      _lastResponse = {'error': 'Processing failed: $e'};
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Direct API calls for specific functionalities
  Future<Map<String, dynamic>> generateItinerary({
    required String departureLocation,
    required String destinationLocation,
    required Map<String, String> travelDates,
    Map<String, dynamic>? userProfile,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.generateItinerary(
        departureLocation: departureLocation,
        destinationLocation: destinationLocation,
        travelDates: travelDates,
        userProfile: userProfile,
      );

      _lastResponse = response; // response is already a Map, no need for toMap()
      return response;
    } catch (e) {
      _lastResponse = {'error': 'Itinerary generation failed: $e'};
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> searchFlights({
    required String departure,
    required String destination,
    String? date,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.searchFlights(
        departure: departure,
        destination: destination,
        date: date,
      );

      _lastResponse = response;
      return response;
    } catch (e) {
      _lastResponse = {'error': 'Flight search failed: $e'};
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> searchHotels({
    required String destination,
    String? checkin,
    String? checkout,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.searchHotels(
        destination: destination,
        checkin: checkin,
        checkout: checkout,
      );

      _lastResponse = response;
      return response;
    } catch (e) {
      _lastResponse = {'error': 'Hotel search failed: $e'};
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> searchTransportation({
    required String departure,
    required String destination,
    String? date,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.searchTransportation(
        departure: departure,
        destination: destination,
        date: date,
      );

      _lastResponse = response;
      return response;
    } catch (e) {
      _lastResponse = {'error': 'Transportation search failed: $e'};
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> searchLocalCabs({
    required String departure,
    required String destination,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.searchLocalCabs(
        departure: departure,
        destination: destination,
      );

      _lastResponse = response;
      return response;
    } catch (e) {
      _lastResponse = {'error': 'Local cab search failed: $e'};
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> getTravelGuide(String destination) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getTravelGuide(destination);

      _lastResponse = response;
      return response;
    } catch (e) {
      _lastResponse = {'error': 'Travel guide failed: $e'};
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> sendChatMessage(String message) async {
    if (_currentSessionKey == null) {
      throw Exception('Session not initialized');
    }

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.sendMessage(message, _currentSessionKey!);

      _lastResponse = response;
      return response;
    } catch (e) {
      _lastResponse = {'error': 'Chat failed: $e'};
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Utility methods
  void clearResponse() {
    _lastResponse = null;
    notifyListeners();
  }

  void selectAgent(Agent agent) {
    _selectedAgent = agent;
    notifyListeners();
  }

}