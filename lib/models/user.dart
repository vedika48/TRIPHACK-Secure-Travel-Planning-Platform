import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final int age;
  final String address;
  final double latitude;
  final double longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.age,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      age: map['age'] ?? 0,
      address: map['address'] ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return UserModel.fromMap({...map, 'uid': doc.id});
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'age': age,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}