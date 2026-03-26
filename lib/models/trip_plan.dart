class TripDetails {
  final String source;
  String destination;
  String purpose;
  DateTime startDate;
  DateTime endDate;
  int travelers;
  String tripType;
  List<String> preferences;
  String specialRequirements;

  TripDetails({
    this.source = '',
    this.destination = '',
    this.purpose = '',
    required this.startDate,
    required this.endDate,
    this.travelers = 1,
    this.tripType = 'leisure',
    this.preferences = const [],
    this.specialRequirements = '',
  });

  int get duration => endDate.difference(startDate).inDays;

  Map<String, dynamic> toMap() {
    return {
      'source': source,
      'destination': destination,
      'purpose': purpose,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'travelers': travelers,
      'tripType': tripType,
      'preferences': preferences,
      'specialRequirements': specialRequirements,
      'duration': duration,
    };
  }
}

class TripService {
  final String id;
  final String type;
  final String name;
  final double price;
  final Map<String, dynamic> details;

  TripService({
    required this.id,
    required this.type,
    required this.name,
    required this.price,
    required this.details,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'name': name,
      'price': price,
      'details': details,
    };
  }

  factory TripService.fromMap(Map<String, dynamic> map) {
    return TripService(
      id: map['id'] ?? '',
      type: map['type'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      details: Map<String, dynamic>.from(map['details'] ?? {}),
    );
  }
}

class TripPlan {
  final String id;
  final String userId;
  final TripDetails details;
  final TripService? flight;
  final TripService? hotel;
  final TripService? transport;
  final List<TripService> localServices;
  final DateTime createdAt;
  final String status;
  final bool isFavorite;

  TripPlan({
    required this.id,
    required this.userId,
    required this.details,
    this.flight,
    this.hotel,
    this.transport,
    this.localServices = const [],
    required this.createdAt,
    this.status = 'planned',
    this.isFavorite = false,
  });

  double get totalCost {
    double cost = 0;
    if (flight != null) cost += flight!.price;
    if (hotel != null) cost += hotel!.price * details.duration;
    if (transport != null) cost += transport!.price;
    cost += localServices.fold(0, (sum, service) => sum + service.price);
    return cost;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'details': details.toMap(),
      'flight': flight?.toMap(),
      'hotel': hotel?.toMap(),
      'transport': transport?.toMap(),
      'localServices': localServices.map((service) => service.toMap()).toList(),
      'totalCost': totalCost,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
      'isFavorite': isFavorite,
    };
  }

  factory TripPlan.fromMap(Map<String, dynamic> map) {
    return TripPlan(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      details: TripDetails(
        source: map['details']['source'] ?? '',
        destination: map['details']['destination'] ?? '',
        purpose: map['details']['purpose'] ?? '',
        startDate: DateTime.parse(map['details']['startDate']),
        endDate: DateTime.parse(map['details']['endDate']),
        travelers: map['details']['travelers'] ?? 1,
        tripType: map['details']['tripType'] ?? 'leisure',
        preferences: List<String>.from(map['details']['preferences'] ?? []),
        specialRequirements: map['details']['specialRequirements'] ?? '',
      ),
      flight: map['flight'] != null ? TripService.fromMap(Map<String, dynamic>.from(map['flight'])) : null,
      hotel: map['hotel'] != null ? TripService.fromMap(Map<String, dynamic>.from(map['hotel'])) : null,
      transport: map['transport'] != null ? TripService.fromMap(Map<String, dynamic>.from(map['transport'])) : null,
      localServices: List<TripService>.from((map['localServices'] ?? []).map((service) => TripService.fromMap(service))),
      createdAt: DateTime.parse(map['createdAt']),
      status: map['status'] ?? 'planned',
      isFavorite: map['isFavorite'] ?? false,
    );
  }
}