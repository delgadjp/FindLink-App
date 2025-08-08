import 'package:cloud_firestore/cloud_firestore.dart';

class LocationData {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final DateTime timestamp;
  final String? address;

  LocationData({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    required this.timestamp,
    this.address,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'address': address,
    };
  }

  // Create from Firestore data
  factory LocationData.fromMap(Map<String, dynamic> map) {
    return LocationData(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      accuracy: map['accuracy']?.toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      address: map['address'],
    );
  }

  // Create from Firestore DocumentSnapshot
  factory LocationData.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle timestamp conversion with better error handling
    DateTime timestamp;
    try {
      final timestampField = data['timestamp'];
      if (timestampField is Timestamp) {
        // Firestore Timestamp
        timestamp = timestampField.toDate();
      } else if (timestampField is int) {
        // Milliseconds since epoch
        timestamp = DateTime.fromMillisecondsSinceEpoch(timestampField);
      } else if (timestampField is DateTime) {
        // Direct DateTime object
        timestamp = timestampField;
      } else {
        print('Warning: Unknown timestamp type: ${timestampField.runtimeType}');
        timestamp = DateTime.now(); // Fallback
      }
    } catch (e) {
      print('Error parsing timestamp: $e, using current time');
      timestamp = DateTime.now();
    }
    
    return LocationData(
      id: data['id'] ?? doc.id, // Use document ID if id field is missing
      userId: data['userId'] ?? '',
      latitude: data['latitude']?.toDouble() ?? 0.0,
      longitude: data['longitude']?.toDouble() ?? 0.0,
      accuracy: data['accuracy']?.toDouble(),
      timestamp: timestamp,
      address: data['address'],
    );
  }
}

class TrustedContact {
  final String id;
  final String userId; // The user who added this contact
  final String contactUserId; // The actual contact's user ID
  final String name;
  final String email;
  final String phone;
  final String relationship;
  final bool isVerified;
  final bool canAccessLocation; // Permission for family location sharing
  final DateTime createdAt;

  TrustedContact({
    required this.id,
    required this.userId,
    required this.contactUserId,
    required this.name,
    required this.email,
    required this.phone,
    required this.relationship,
    this.isVerified = false,
    this.canAccessLocation = false, // Default false, user must explicitly grant
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'contactUserId': contactUserId,
      'name': name,
      'email': email,
      'phone': phone,
      'relationship': relationship,
      'isVerified': isVerified,
      'canAccessLocation': canAccessLocation,
      'createdAt': Timestamp.fromDate(createdAt), // Convert to Firestore Timestamp
    };
  }

  factory TrustedContact.fromMap(Map<String, dynamic> map) {
    // Handle different createdAt formats (Firestore Timestamp vs milliseconds)
    DateTime createdAt;
    final createdAtValue = map['createdAt'];
    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    } else if (createdAtValue is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtValue);
    } else if (createdAtValue is Map && createdAtValue['seconds'] != null) {
      // Handle server timestamp format
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtValue['seconds'] * 1000);
    } else {
      createdAt = DateTime.now(); // Fallback
    }
    
    return TrustedContact(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      contactUserId: map['contactUserId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      relationship: map['relationship'] ?? '',
      isVerified: map['isVerified'] ?? false,
      canAccessLocation: map['canAccessLocation'] ?? false,
      createdAt: createdAt,
    );
  }

  factory TrustedContact.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TrustedContact.fromMap(data);
  }

  // copyWith method for updating properties
  TrustedContact copyWith({
    String? id,
    String? userId,
    String? contactUserId,
    String? name,
    String? email,
    String? phone,
    String? relationship,
    bool? isVerified,
    bool? canAccessLocation,
    DateTime? createdAt,
  }) {
    return TrustedContact(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      contactUserId: contactUserId ?? this.contactUserId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      isVerified: isVerified ?? this.isVerified,
      canAccessLocation: canAccessLocation ?? this.canAccessLocation,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
