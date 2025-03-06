import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
export 'dart:typed_data';
import '/core/app_export.dart';

class TipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid();

  Future<void> submitTip({
    required String name,
    required String phone,
    required String dateLastSeen,
    required String timeLastSeen,
    required String gender,
    required String age,
    required String height,
    required String hairColor,
    required String eyeColor,
    required String clothing,
    required String features,
    required String description,
    required String location,
    required double lat,
    required double lng,
    required String userId,
  }) async {
    try {
      // Generate unique ID for the document
      final String reportId = _uuid.v4();

      // Create the report document in Firestore with the exact field structure
      await _firestore.collection('reports').doc(reportId).set({
        'age': age,
        'clothing': clothing,
        'coordinates': {
          'lat': lat,
          'lng': lng
        },
        'dateLastSeen': dateLastSeen,
        'description': description,
        'eyeColor': eyeColor,
        'features': features,
        'gender': gender,
        'hairColor': hairColor,
        'height': height,
        'location': location,
        'name': name,
        'phone': phone,
        'timeLastSeen': timeLastSeen,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
      }).catchError((e) {
        print("Firestore write error: ${e.toString()}");
        throw e;
      });
    } catch (e) {
      print('Error submitting report: $e');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
      }
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getAllReports() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('reports')
          .orderBy('timestamp', descending: true)
          .get();
          

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting reports: $e');
      throw e;
    }
  }
}