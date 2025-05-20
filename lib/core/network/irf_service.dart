import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/irf_model.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';

class IRFService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Google Vision API key - use the same one as in TipService
  final String _visionApiKey = 'AIzaSyBpeXXTgrLeT9PuUT-8H-AXPTW6sWlnys0';

  // Add helper method to upload image to Firebase Storage
  Future<String?> uploadImage(dynamic imageData, String irfId) async {
    try {
      // Create reference to the file path in storage
      final Reference storageRef = _storage
          .ref()
          .child('irf-app-images')
          .child('$irfId.jpg');
      
      late UploadTask uploadTask;
      
      // Handle different types of image data (File for mobile, Uint8List for web)
      if (kIsWeb) {
        if (imageData is String) {
          final Uint8List bytes = Uri.parse(imageData).data!.contentAsBytes();
          uploadTask = storageRef.putData(bytes);
        } else if (imageData is Uint8List) {
          uploadTask = storageRef.putData(imageData);
        } else {
          throw Exception('Unsupported image data type for web');
        }
      } else {
        if (imageData is File) {
          uploadTask = storageRef.putFile(imageData);
        } else if (imageData is String && imageData.isNotEmpty) {
          final File file = File(imageData);
          if (await file.exists()) {
            uploadTask = storageRef.putFile(file);
          } else {
            throw Exception('File does not exist at path: $imageData');
          }
        } else {
          throw Exception('Unsupported image data type for mobile');
        }
      }
      
      await uploadTask.whenComplete(() => null);
      final String downloadUrl = await storageRef.getDownloadURL();
      
      print('Image uploaded successfully. URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Add method to validate image using Google Vision API
  Future<Map<String, dynamic>> validateImageWithGoogleVision(dynamic imageData) async {
    try {
      Map<String, dynamic> result = {
        'isValid': false,
        'containsHuman': false,
        'confidence': 0.0,
        'message': 'Image validation failed'
      };
      
      String base64Image;
      
      if (kIsWeb) {
        if (imageData is Uint8List) {
          base64Image = base64Encode(imageData);
        } else if (imageData is String) {
          if (imageData.startsWith('data:image')) {
            base64Image = imageData.split(',')[1];
          } else {
            final Uint8List bytes = Uri.parse(imageData).data!.contentAsBytes();
            base64Image = base64Encode(bytes);
          }
        } else {
          throw Exception('Unsupported image data type for web validation');
        }
      } else {
        if (imageData is File) {
          final bytes = await imageData.readAsBytes();
          base64Image = base64Encode(bytes);
        } else if (imageData is String && imageData.isNotEmpty) {
          final File file = File(imageData);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            base64Image = base64Encode(bytes);
          } else {
            throw Exception('File does not exist at path: $imageData');
          }
        } else if (imageData is Uint8List) {
          base64Image = base64Encode(imageData);
        } else {
          throw Exception('Unsupported image data type for mobile validation');
        }
      }
      
      final response = await http.post(
        Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$_visionApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'requests': [{
            'image': {
              'content': base64Image
            },
            'features': [
              {'type': 'LABEL_DETECTION', 'maxResults': 10},
              {'type': 'FACE_DETECTION', 'maxResults': 5},
              {'type': 'OBJECT_LOCALIZATION', 'maxResults': 10}
            ]
          }]
        })
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        bool containsHuman = false;
        double confidence = 0.0;
        
        final annotations = jsonResponse['responses'][0];
        
        if (annotations.containsKey('faceAnnotations')) {
          containsHuman = true;
          confidence = annotations['faceAnnotations'][0]['detectionConfidence'] * 100;
        }
        
        if (!containsHuman && annotations.containsKey('labelAnnotations')) {
          for (var label in annotations['labelAnnotations']) {
            String description = label['description'].toString().toLowerCase();
            if (description.contains('person') || description.contains('human') || 
                description.contains('face') || description.contains('people')) {
              containsHuman = true;
              confidence = label['score'] * 100;
              break;
            }
          }
        }
        
        result = {
          'isValid': true,
          'containsHuman': containsHuman,
          'confidence': confidence.round() / 100,
          'message': containsHuman 
              ? 'Image validated successfully. Human detected with ${confidence.toStringAsFixed(1)}% confidence.'
              : 'No human detected in the image.'
        };
      }
      
      return result;
    } catch (e) {
      print('Exception in validateImageWithGoogleVision: $e');
      return {
        'isValid': false,
        'containsHuman': false,
        'confidence': 0.0,
        'message': 'Error validating image: $e'
      };
    }
  }
  // Collection reference - Uses only incidents collection now
  CollectionReference get irfCollection => _firestore.collection('incidents');
  
  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;  // Generate a formal document ID format: IRF-YYYYMMDD-XXXX (where XXXX is sequential starting at 0001)
  Future<String> generateFormalDocumentId() async {
    final today = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(today);
    final idPrefix = 'IRF-$dateStr-';

    try {
      // Get all documents with today's date prefix by document ID
      final QuerySnapshot querySnapshot = await _firestore
          .collection('irf-test')
          .get();

      // Debug info
      print('Found ${querySnapshot.docs.length} documents for today (${dateStr})');
      
      // Find the highest sequential number by checking doc.id
      int highestNumber = 0;
      for (final doc in querySnapshot.docs) {
        final String docId = doc.id;
        if (docId.startsWith(idPrefix) && docId.length > idPrefix.length) {
          final String seqPart = docId.substring(idPrefix.length);
          final int? seqNum = int.tryParse(seqPart);
          if (seqNum != null && seqNum > highestNumber) {
            highestNumber = seqNum;
            print('Found higher sequence: $highestNumber from $docId');
          }
        }
      }
      // Increment for next document
      final int nextNumber = highestNumber + 1;
      final String paddedNumber = nextNumber.toString().padLeft(4, '0');
      final String newDocId = '$idPrefix$paddedNumber';
      print('Generated next document ID: $newDocId');
      return newDocId;
    } catch (e) {
      print('Error generating document ID: $e');      // Fallback ID using more reliable method - but ensure it's still sequential
      final String paddedNumber = '0001'; // Start with 0001 if there's an error
      final String fallbackId = '$idPrefix$paddedNumber';
      print('Using fallback ID: $fallbackId');
      return fallbackId;
    }
  }
  // Submit new IRF with formal document ID
  Future<DocumentReference> submitIRF(IRFModel irfData) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      // Generate formal document ID with sequential numbering
      final String formalId = await generateFormalDocumentId();
      print('Generated formal document ID for submission: $formalId');
      
      // Prepare the data map
      final dataMap = irfData.toMap();
      // Move createdAt and incidentId inside incidentDetails
      dataMap['incidentDetails'] ??= {};
      dataMap['incidentDetails']['createdAt'] = FieldValue.serverTimestamp();
      dataMap['incidentDetails']['incidentId'] = formalId;
      // Remove root createdAt and incidentId if present
      dataMap.remove('createdAt');
      dataMap.remove('incidentId');
      // Add other root-level fields
      dataMap['userId'] = currentUserId;
      dataMap['updatedAt'] = FieldValue.serverTimestamp();
      dataMap['status'] = 'Reported';
      // dataMap['type'] = 'report'; // Removed as per request
      
      // Use the formal ID as the document ID for the document itself
      final docRef = irfCollection.doc(formalId);
      await docRef.set(dataMap);
      print('Successfully submitted IRF with ID: $formalId');
      return docRef;
    } catch (e) {
      print('Error submitting IRF: $e');
      rethrow; // Rethrow to handle in UI
    }
  }
    // Update existing IRF
  Future<void> updateIRF(String irfId, IRFModel irfData) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    // Prepare the data map
    final dataMap = irfData.toMap();
    dataMap['incidentDetails'] ??= {};
    dataMap['incidentDetails']['incidentId'] = irfId;
    dataMap['updatedAt'] = FieldValue.serverTimestamp();
    dataMap['status'] = 'Reported';
    dataMap.remove('incidentId');
    // dataMap['type'] = 'report'; // Removed as per request
    return await irfCollection.doc(irfId).update(dataMap);
  }
  
  // Get IRF by ID from Firebase
  Future<dynamic> getIRF(String irfId) async {
    return await irfCollection.doc(irfId).get();
  }
  
  // Get user's IRFs
  Stream<QuerySnapshot> getUserIRFs() {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    return irfCollection
        .where('userId', isEqualTo: currentUserId)
        .where('type', isEqualTo: 'report') // Only get reports, not counters
        .orderBy('updatedAt', descending: true)
        .snapshots();
  }
  
  // Delete IRF
  Future<void> deleteIRF(String irfId) async {
    return await irfCollection.doc(irfId).delete();
  }

  // Get user's selected ID type
  Future<String?> getUserSelectedIDType() async {
    try {
      if (currentUserId == null) return null;
      
      final userQuery = await _firestore
          .collection('users-app')
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get();
          
      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        return userData['selectedIDType'] as String?;
      }
      return null;
    } catch (e) {
      print('Error fetching user ID type: $e');
      return null;
    }
  }
}
