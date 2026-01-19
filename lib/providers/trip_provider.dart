// providers/trip_planning_provider.dart
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_plan.dart';
import '../services/firebase_service.dart';

class TripPlanningProvider with ChangeNotifier {
  TripDetails _tripDetails = TripDetails(
    startDate: DateTime.now(),
    endDate: DateTime.now().add(const Duration(days: 1)),
  );
  TripService? _selectedFlight;
  TripService? _selectedHotel;
  TripService? _selectedTransport;
  final List<TripService> _selectedLocalServices = [];
  bool _isLoading = false;
  final FirebaseService _firebaseService = FirebaseService();

  // Getters
  TripDetails get tripDetails => _tripDetails;
  TripService? get selectedFlight => _selectedFlight;
  TripService? get selectedHotel => _selectedHotel;
  TripService? get selectedTransport => _selectedTransport;
  List<TripService> get selectedLocalServices => _selectedLocalServices;
  bool get isLoading => _isLoading;

  TripPlan get currentTripPlan {
    return TripPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'current_user_id', // This should come from auth provider
      details: _tripDetails,
      flight: _selectedFlight,
      hotel: _selectedHotel,
      transport: _selectedTransport,
      localServices: _selectedLocalServices,
      createdAt: DateTime.now(),
    );
  }

  // Setters
  void updateTripDetails(TripDetails details) {
    _tripDetails = details;
    notifyListeners();
  }

  void selectFlight(TripService flight) {
    _selectedFlight = flight;
    notifyListeners();
  }

  void selectHotel(TripService hotel) {
    _selectedHotel = hotel;
    notifyListeners();
  }

  void selectTransport(TripService transport) {
    _selectedTransport = transport;
    notifyListeners();
  }

  void toggleLocalService(TripService service) {
    if (_selectedLocalServices.any((s) => s.id == service.id)) {
      _selectedLocalServices.removeWhere((s) => s.id == service.id);
    } else {
      _selectedLocalServices.add(service);
    }
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearSelections() {
    _selectedFlight = null;
    _selectedHotel = null;
    _selectedTransport = null;
    _selectedLocalServices.clear();
    notifyListeners();
  }

  // Firebase operations
  Future<void> saveTripPlan() async {
    try {
      setLoading(true);
      final tripPlan = currentTripPlan;
      await _firebaseService.saveTripPlan(tripPlan);
      // Clear selections after saving
      clearSelections();
    } catch (e) {
      rethrow;
    } finally {
      setLoading(false);
    }
  }

  Future<List<TripPlan>> getUserTripPlans(String userId) async {
    try {
      setLoading(true);
      return await _firebaseService.getUserTripPlans(userId);
    } catch (e) {
      rethrow;
    } finally {
      setLoading(false);
    }
  }
}