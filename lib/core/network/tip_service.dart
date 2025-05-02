import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
export 'dart:typed_data';
import '/core/app_export.dart';
import 'dart:typed_data';  // Add this for web support
import 'package:http/http.dart' as http;
import 'dart:convert';

class TipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Uuid _uuid = Uuid();
  
  // Google Vision API key
  final String _visionApiKey = 'AIzaSyBpeXXTgrLeT9PuUT-8H-AXPTW6sWlnys0';

  // Helper method to generate custom document ID for reports
  String _generateCustomReportId() {
    final now = DateTime.now();
    final datePart = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    
    // Create a unique suffix based on timestamp
    final uniqueSuffix = now.millisecondsSinceEpoch.toString().substring(7);
    
    // Format: REPORT_YYYYMMDD_XXXXX
    return "REPORT_${datePart}_$uniqueSuffix";
  }

  // Helper method to upload image to Firebase Storage
  Future<String?> _uploadImage(dynamic imageData, String reportId) async {
    try {
      // Create reference to the file path in storage
      final Reference storageRef = _storage
          .ref()
          .child('reports-app')
          .child('$reportId.jpg');
      
      late UploadTask uploadTask;
      
      // Handle different types of image data (File for mobile, Uint8List for web)
      if (kIsWeb) {
        // For web, imageData should be Uint8List (from base64 decode)
        if (imageData is String) {
          // If it's base64 string, decode it
          final Uint8List bytes = Uri.parse(imageData).data!.contentAsBytes();
          uploadTask = storageRef.putData(bytes);
        } else if (imageData is Uint8List) {
          // If it's already bytes
          uploadTask = storageRef.putData(imageData);
        } else {
          throw Exception('Unsupported image data type for web');
        }
      } else {
        // For mobile platforms, imageData should be a File
        if (imageData is File) {
          uploadTask = storageRef.putFile(imageData);
        } else if (imageData is String && imageData.isNotEmpty) {
          // Assume it's a file path
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
      
      // Wait for the upload to complete and get download URL
      await uploadTask.whenComplete(() => null);
      final String downloadUrl = await storageRef.getDownloadURL();
      
      print('Image uploaded successfully. URL: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      // Return null if upload fails, but don't fail the entire submission
      return null;
    }
  }

  // New method to validate image using Google Vision API
  Future<Map<String, dynamic>> validateImageWithGoogleVision(dynamic imageData) async {
    try {
      // Default response
      Map<String, dynamic> result = {
        'isValid': false,
        'containsHuman': false,
        'confidence': 0.0,
        'message': 'Image validation failed'
      };
      
      // Convert image data to base64 format needed for Vision API
      String base64Image;
      
      if (kIsWeb) {
        if (imageData is Uint8List) {
          base64Image = base64Encode(imageData);
        } else if (imageData is String) {
          // If it's already a base64 string from web
          if (imageData.startsWith('data:image')) {
            base64Image = imageData.split(',')[1];
          } else {
            // Try to decode the string as bytes
            final Uint8List bytes = Uri.parse(imageData).data!.contentAsBytes();
            base64Image = base64Encode(bytes);
          }
        } else {
          throw Exception('Unsupported image data type for web validation');
        }
      } else {
        // For mobile platforms
        if (imageData is File) {
          final bytes = await imageData.readAsBytes();
          base64Image = base64Encode(bytes);
        } else if (imageData is String && imageData.isNotEmpty) {
          // Assume it's a file path
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
      
      // Prepare request to Google Vision API
      final response = await http.post(
        Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$_visionApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'requests': [
            {
              'image': {
                'content': base64Image
              },
              'features': [
                {'type': 'LABEL_DETECTION', 'maxResults': 10},
                {'type': 'FACE_DETECTION', 'maxResults': 5},
                {'type': 'OBJECT_LOCALIZATION', 'maxResults': 10}
              ]
            }
          ]
        })
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        print('Vision API response: ${jsonResponse.toString()}');
        
        bool containsHuman = false;
        double confidence = 0.0;
        
        // Check for human-related labels
        final annotations = jsonResponse['responses'][0];
        
        // Check face detection results
        if (annotations.containsKey('faceAnnotations') && 
            annotations['faceAnnotations'] != null &&
            annotations['faceAnnotations'].isNotEmpty) {
          containsHuman = true;
          confidence = annotations['faceAnnotations'][0]['detectionConfidence'] * 100;
        }
        
        // Check label detection results if no face found
        if (!containsHuman && annotations.containsKey('labelAnnotations')) {
          final List<dynamic> labels = annotations['labelAnnotations'];
          for (var label in labels) {
            String description = label['description'].toString().toLowerCase();
            if (description.contains('person') || 
                description.contains('human') || 
                description.contains('people') ||
                description.contains('face') ||
                description.contains('man') ||
                description.contains('woman') ||
                description.contains('child')) {
              containsHuman = true;
              confidence = label['score'] * 100;  // Convert to percentage
              break;
            }
          }
        }
        
        // Check object localization results if still no human found
        if (!containsHuman && annotations.containsKey('localizedObjectAnnotations')) {
          final List<dynamic> objects = annotations['localizedObjectAnnotations'];
          for (var object in objects) {
            String name = object['name'].toString().toLowerCase();
            if (name.contains('person') || 
                name.contains('human') ||
                name.contains('face') ||
                name.contains('man') ||
                name.contains('woman') ||
                name.contains('child')) {
              containsHuman = true;
              confidence = object['score'] * 100;  // Convert to percentage
              break;
            }
          }
        }
        
        result = {
          'isValid': true,
          'containsHuman': containsHuman,
          'confidence': confidence.round() / 100,  // Round to 2 decimal places
          'message': containsHuman 
              ? 'Image validated successfully. Human detected with ${confidence.toStringAsFixed(1)}% confidence.' 
              : 'No human detected in the image.'
        };
      } else {
        print('Error calling Google Vision API: ${response.statusCode}, ${response.body}');
        result['message'] = 'Error calling image validation service: ${response.statusCode}';
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

  Future<void> submitTip({
    required String dateLastSeen,
    required String timeLastSeen,
    required String gender,
    String ageRange = "Unknown", 
    String heightRange = "Unknown", // Changed height to heightRange with default value
    required String hairColor,
    required String clothing,
    required String features,
    required String description,
    required double lat,
    required double lng,
    required String userId,
    required String address,
    dynamic imageData, // New parameter for image data
    bool validateImage = true, // New parameter to control image validation
  }) async {
    try {
      // Validate image if provided and validation is enabled
      Map<String, dynamic> imageValidation = {'isValid': true, 'containsHuman': true};
      
      if (imageData != null && validateImage) {
        imageValidation = await validateImageWithGoogleVision(imageData);
        
        // If validation failed completely, continue without the image
        if (!imageValidation['isValid']) {
          print('Image validation failed: ${imageValidation['message']}');
          // We'll continue without the image, but log the error
        }
        // If validation succeeded but no human detected, throw an error
        else if (!imageValidation['containsHuman']) {
          throw Exception('No human detected in the image. Please upload a photo that clearly shows a person.');
        }
      }
    
      // Generate custom document ID for the report
      final String reportId = _generateCustomReportId();
      
      // Create the data map with all fields except the image
      final Map<String, dynamic> reportData = {
        'ageRange': ageRange,
        'heightRange': heightRange, // Store height range instead of height
        'clothing': clothing,
        'coordinates': {
          'lat': lat,
          'lng': lng
        },
        'address': address,
        'dateLastSeen': dateLastSeen,
        'description': description,
        'features': features,
        'gender': gender,
        'hairColor': hairColor,
        'timeLastSeen': timeLastSeen,
        'timestamp': FieldValue.serverTimestamp(),
        'uid': userId,
        'documentId': reportId, // Store document ID in the document itself
      };
      
      // Add image validation results if image was provided and validated
      if (imageData != null && validateImage) {
        reportData['imageValidation'] = {
          'containsHuman': imageValidation['containsHuman'],
          'confidence': imageValidation['confidence'],
        };
      }
      
      // Upload image if provided and validation passed or was skipped
      if (imageData != null && (!validateImage || imageValidation['containsHuman'])) {
        final String? imageUrl = await _uploadImage(imageData, reportId);
        if (imageUrl != null) {
          // Add the image URL to the report data
          reportData['imageUrl'] = imageUrl;
        }
      }
      
      // Create the report document in Firestore with custom document ID
      await _firestore.collection('reports-app').doc(reportId).set(reportData)
        .catchError((e) {
          print("Firestore write error: ${e.toString()}");
          throw e;
        });

      print('Report successfully added with custom ID: $reportId');
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
          .collection('reports-app')
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