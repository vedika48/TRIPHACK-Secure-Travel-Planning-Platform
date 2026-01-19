import '../services/api_service.dart';

class Agent {
  final String id;
  final String name;
  final String type;
  final String description;
  final String status;
  final Map<String, dynamic> capabilities;

  Agent({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.status,
    required this.capabilities,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'general',
      description: json['description'] ?? '',
      status: json['status'] ?? 'available',
      capabilities: json['capabilities'] is Map ? Map<String, dynamic>.from(json['capabilities']) : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'description': description,
      'status': status,
      'capabilities': capabilities,
    };
  }
}

// Agent types available in your backend
class AgentTypes {
  static const String general = 'general';
  static const String travelPlanner = 'travel_planner';
  static const String booking = 'booking';
  static const String guide = 'guide';
}

// Agent service to manage agent selection and operations
class AgentService {
  final ApiService apiService;

  AgentService(this.apiService);

  // Get available agents (mock data since your backend doesn't have agent endpoints)
  Future<List<Agent>> getAvailableAgents() async {
    // These are mock agents that correspond to your backend capabilities
    return [
      Agent(
        id: 'travel_planner',
        name: 'Travel Planning Agent',
        type: AgentTypes.travelPlanner,
        description: 'Specializes in creating detailed travel itineraries and trip planning',
        status: 'available',
        capabilities: {
          'itinerary_planning': true,
          'budget_optimization': true,
          'destination_research': true,
        },
      ),
      Agent(
        id: 'booking_agent',
        name: 'Booking Assistant',
        type: AgentTypes.booking,
        description: 'Handles flight, hotel, and transportation searches',
        status: 'available',
        capabilities: {
          'flight_search': true,
          'hotel_search': true,
          'transport_search': true,
          'local_cab_search': true,
        },
      ),
      Agent(
        id: 'travel_guide',
        name: 'Travel Guide',
        type: AgentTypes.guide,
        description: 'Provides destination guides and local information',
        status: 'available',
        capabilities: {
          'destination_guides': true,
          'local_attractions': true,
          'cultural_info': true,
        },
      ),
      Agent(
        id: 'general_assistant',
        name: 'General Travel Assistant',
        type: AgentTypes.general,
        description: 'General travel assistance and conversation',
        status: 'available',
        capabilities: {
          'conversation': true,
          'basic_info': true,
          'qna': true,
        },
      ),
    ];
  }

  // Select an agent based on user query
  Future<Agent> selectAgentForQuery(String query) async {
    final agents = await getAvailableAgents();
    final queryLower = query.toLowerCase();

    // Simple agent selection logic based on query content
    if (queryLower.contains('itinerary') ||
        queryLower.contains('plan') ||
        queryLower.contains('trip') ||
        queryLower.contains('schedule')) {
      return agents.firstWhere((agent) => agent.type == AgentTypes.travelPlanner);
    } else if (queryLower.contains('flight') ||
        queryLower.contains('hotel') ||
        queryLower.contains('book') ||
        queryLower.contains('cab') ||
        queryLower.contains('bus') ||
        queryLower.contains('train')) {
      return agents.firstWhere((agent) => agent.type == AgentTypes.booking);
    } else if (queryLower.contains('guide') ||
        queryLower.contains('attraction') ||
        queryLower.contains('place to visit') ||
        queryLower.contains('things to do')) {
      return agents.firstWhere((agent) => agent.type == AgentTypes.guide);
    } else {
      return agents.firstWhere((agent) => agent.type == AgentTypes.general);
    }
  }

  // Process query with selected agent
  Future<Object> processWithAgent({
    required Agent agent,
    required String query,
    required String sessionKey,
    Map<String, dynamic>? additionalData,
  }) async {
    switch (agent.type) {
      case AgentTypes.travelPlanner:
      // Extract travel parameters from query or use additionalData
        final travelData = additionalData ?? _extractTravelDataFromQuery(query);
        return await apiService.generateItinerary(
          departureLocation: travelData['departure'] ?? '',
          destinationLocation: travelData['destination'] ?? '',
          travelDates: travelData['dates'] ?? {'departure': '', 'return': ''},
          userProfile: travelData['profile'],
        );

      case AgentTypes.booking:
        if (query.toLowerCase().contains('flight')) {
          final searchData = _extractSearchData(query);
          return await apiService.searchFlights(
            departure: searchData['departure'] ?? '',
            destination: searchData['destination'] ?? '',
            date: searchData['date'],
          );
        } else if (query.toLowerCase().contains('hotel')) {
          final searchData = _extractSearchData(query);
          return await apiService.searchHotels(
            destination: searchData['destination'] ?? '',
            checkin: searchData['checkin'],
            checkout: searchData['checkout'],
          );
        } else if (query.toLowerCase().contains('cab') && query.toLowerCase().contains('local')) {
          final searchData = _extractSearchData(query);
          return await apiService.searchLocalCabs(
            departure: searchData['departure'] ?? '',
            destination: searchData['destination'] ?? '',
          );
        } else {
          final searchData = _extractSearchData(query);
          return await apiService.searchTransportation(
            departure: searchData['departure'] ?? '',
            destination: searchData['destination'] ?? '',
            date: searchData['date'],
          );
        }

      case AgentTypes.guide:
        final destination = _extractDestinationFromQuery(query);
        return await apiService.getTravelGuide(destination);

      default:
      // For general queries, use the chat endpoint
        return await apiService.sendMessage(query, sessionKey);
    }
  }

  // Helper methods to extract data from queries
  Map<String, dynamic> _extractTravelDataFromQuery(String query) {
    // Simple extraction logic - you might want to enhance this with NLP
    final words = query.toLowerCase().split(' ');
    final data = <String, dynamic>{};

    // Very basic extraction - consider using a more sophisticated approach
    if (words.contains('from') && words.contains('to')) {
      final fromIndex = words.indexOf('from');
      final toIndex = words.indexOf('to');
      if (fromIndex < toIndex && toIndex < words.length - 1) {
        data['departure'] = words[fromIndex + 1];
        data['destination'] = words[toIndex + 1];
      }
    }

    return data;
  }

  Map<String, dynamic> _extractSearchData(String query) {
    final words = query.toLowerCase().split(' ');
    final data = <String, dynamic>{};

    if (words.contains('from') && words.contains('to')) {
      final fromIndex = words.indexOf('from');
      final toIndex = words.indexOf('to');
      if (fromIndex < toIndex && toIndex < words.length - 1) {
        data['departure'] = words[fromIndex + 1];
        data['destination'] = words[toIndex + 1];
      }
    }

    // Extract date if mentioned
    final datePattern = RegExp(r'\d{1,2}/\d{1,2}/\d{4}');
    final match = datePattern.firstMatch(query);
    if (match != null) {
      data['date'] = match.group(0);
    }

    return data;
  }

  String _extractDestinationFromQuery(String query) {
    final words = query.toLowerCase().split(' ');

    if (words.contains('in') && words.indexOf('in') < words.length - 1) {
      return words[words.indexOf('in') + 1];
    }

    if (words.contains('for') && words.indexOf('for') < words.length - 1) {
      return words[words.indexOf('for') + 1];
    }

    // Return the last word as a fallback (usually the destination)
    return words.isNotEmpty ? words.last : 'destination';
  }
}