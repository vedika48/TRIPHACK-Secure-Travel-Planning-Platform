// services/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_plan.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save trip plan to Firebase
  Future<void> saveTripPlan(TripPlan tripPlan) async {
    try {
      await _firestore
          .collection('trip_plans')
          .doc(tripPlan.id)
          .set(tripPlan.toMap());
    } catch (e) {
      throw Exception('Failed to save trip plan: $e');
    }
  }

  // Get user's trip plans
  Future<List<TripPlan>> getUserTripPlans(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('trip_plans')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => TripPlan.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch trip plans: $e');
    }
  }

  // Update trip plan status
  Future<void> updateTripPlanStatus(String tripId, String status) async {
    try {
      await _firestore
          .collection('trip_plans')
          .doc(tripId)
          .update({'status': status});
    } catch (e) {
      throw Exception('Failed to update trip plan: $e');
    }
  }

  // Delete trip plan
  Future<void> deleteTripPlan(String tripId) async {
    try {
      await _firestore.collection('trip_plans').doc(tripId).delete();
    } catch (e) {
      throw Exception('Failed to delete trip plan: $e');
    }
  }
}