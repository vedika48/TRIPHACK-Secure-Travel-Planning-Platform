import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/trip_plan.dart';
import '../services/firebase_service.dart';

class TripPlanningProvider with ChangeNotifier {
  TripDetails _tripDetails = TripDetails(
    source: '',
    destination: '',
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
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_user';
    return TripPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
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
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Must be logged in to save a trip plan');
      }
      
      setLoading(true);
      final tripPlan = currentTripPlan;
      await _firebaseService.saveTripPlan(tripPlan);
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

  Future<void> toggleFavorite(TripPlan plan) async {
    try {
      final newFavoriteStatus = !plan.isFavorite;
      await _firebaseService.toggleFavorite(plan.id, newFavoriteStatus);
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error toggling favorite: $e');
      }
      rethrow;
    }
  }
}