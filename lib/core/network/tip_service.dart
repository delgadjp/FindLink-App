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

  /// Submit a new tip to Firestore
  /// Requires authenticated user (userId)
  Future<void> submitTip({
    required String name,
    required String phone,
    required DateTime dateLastSeen,
    required String timeLastSeen,
    required String gender,
    required int age,
    required String height,
    required String hairColor,
    required String eyeColor,
    required String clothing,
    required String features,
    required String description,
    File? imageFile, // Already optional with '?'
    Uint8List? imageBytes, // Already optional with '?'
    required double longitude,
    required double latitude,
    required String userId,
  }) async {
    try {
      // Generate unique IDs for the document and image
      final String tipId = _uuid.v4();
      String? imageFileName;
      String? imageUrl;

      // Only upload image if one is provided
      if ((kIsWeb && imageBytes != null) || (!kIsWeb && imageFile != null)) {
        // Create imageFileName only if an image is provided
        imageFileName = 'tips-app/$tipId.jpg';
        
        // Upload image to Firebase Storage if available
        if (kIsWeb && imageBytes != null) {
          // Web platform - upload bytes
          await _storage.ref(imageFileName).putData(imageBytes);
          imageUrl = await _storage.ref(imageFileName).getDownloadURL();
        } else if (imageFile != null) {
          // Mobile platforms - upload file
          await _storage.ref(imageFileName).putFile(imageFile);
          imageUrl = await _storage.ref(imageFileName).getDownloadURL();
        }
      }

      // Debug: Print user ID before submission
      print("Submitting tip with userId: $userId");

      // Create the tip document in Firestore
      await _firestore.collection('tips-app').doc(tipId).set({
        'name': name,
        'submitterPhone': phone,
        'dateLastSeen': Timestamp.fromDate(dateLastSeen),
        'timeLastSeen': timeLastSeen,
        'gender': gender,
        'age': age,
        'height': height,
        'hairColor': hairColor,
        'eyeColor': eyeColor,
        'clothing': clothing,
        'features': features,
        'description': description,
        'imageRef': imageFileName, // This can be null if no image
        'imageUrl': imageUrl, // This can be null if no image
        'location': GeoPoint(latitude, longitude),
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': FieldValue.serverTimestamp(),
        'userId': userId,
      }).catchError((e) {
        print("Firestore write error: ${e.toString()}");
        throw e;
      });
    } catch (e) {
      print('Error submitting tip: $e');
      if (e is FirebaseException) {
        print('Firebase error code: ${e.code}');
        print('Firebase error message: ${e.message}');
      }
      throw e;
    }
  }

  /// Get all tips from Firestore
  Future<List<Map<String, dynamic>>> getAllTips() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection('tips-app')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting tips: $e');
      throw e;
    }
  }
}