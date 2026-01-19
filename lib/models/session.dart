import 'dart:convert';

class Session {
  final String sessionKey;
  final String userId;
  final String createdAt;
  final String lastActivity;

  Session({
    required this.sessionKey,
    required this.userId,
    required this.createdAt,
    required this.lastActivity,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      sessionKey: json['session_key'] ?? '',
      userId: json['user_id'] ?? '',
      createdAt: json['created_at'] ?? '',
      lastActivity: json['last_activity'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'session_key': sessionKey,
      'user_id': userId,
      'created_at': createdAt,
      'last_activity': lastActivity,
    };
  }

  String toJsonString() {
    return json.encode(toJson());
  }

  factory Session.fromJsonString(String jsonString) {
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    return Session.fromJson(jsonMap);
  }

  bool? get isNotEmpty => null;

  void operator [](String other) {}
}