import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import '/core/app_export.dart';

class IRFService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Google Vision API key - use the same one as in TipService
  final String _visionApiKey = 'AIzaSyBpeXXTgrLeT9PuUT-8H-AXPTW6sWlnys0';

  // Status step definitions from React reference
  final List<String> statusSteps = [
    'Reported',
    'Under Review',
    'Case Verified',
    'In Progress',
    'Resolved Case',
    'Unresolved Case',
  ];
  // Add helper method to upload image to Firebase Storage
  Future<String?> uploadImage(dynamic imageData, String irfId) async {
    try {
      // Create reference to the file path in storage
      // Using 'irf-app-images' folder which is allowed in the Firebase Storage rules
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
      return downloadUrl;    } catch (e) {
      print('Error uploading image: $e');
      if (e.toString().contains('unauthorized')) {
        throw Exception('User not authorized to upload images. Please check your permissions.');
      }
      throw Exception('Image upload failed.');
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
  String? get currentUserId => _auth.currentUser?.uid;
  
  // Generate a formal document ID format: IRF-YYYYMMDD-XXXX (where XXXX is sequential starting at 0001)
  Future<String> generateFormalDocumentId() async {
    final today = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(today);
    final idPrefix = 'IRF-$dateStr-';

    try {
      // Get all documents with today's date prefix by document ID in the incidents collection
      final QuerySnapshot querySnapshot = await _firestore
          .collection('incidents')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: idPrefix + '0001')
          .where(FieldPath.documentId, isLessThanOrEqualTo: idPrefix + '9999')
          .get();

      // Find the highest sequential number by checking doc.id
      int highestNumber = 0;
      for (final doc in querySnapshot.docs) {
        final String docId = doc.id;
        if (docId.startsWith(idPrefix) && docId.length > idPrefix.length) {
          final String seqPart = docId.substring(idPrefix.length);
          final int? seqNum = int.tryParse(seqPart);
          if (seqNum != null && seqNum > highestNumber) {
            highestNumber = seqNum;
          }
        }
      }
      // Increment for next document
      final int nextNumber = highestNumber + 1;
      final String paddedNumber = nextNumber.toString().padLeft(4, '0');
      final String newDocId = '$idPrefix$paddedNumber';
      return newDocId;
    } catch (e) {
      // Fallback ID using more reliable method - but ensure it's still sequential
      final String paddedNumber = '0001'; // Start with 0001 if there's an error
      final String fallbackId = '$idPrefix$paddedNumber';
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
      String formalId;
      DocumentReference docRef;
      int attempt = 0;
      do {
        formalId = await generateFormalDocumentId();
        docRef = irfCollection.doc(formalId);
        final docSnap = await docRef.get();
        if (!docSnap.exists) break;
        // If exists, increment the highest number and try again
        attempt++;
        // Artificially bump the date to force next number (for rare race conditions)
        if (attempt > 10) {
          throw Exception('Too many attempts to generate unique IRF ID');
        }
        // Wait a bit to avoid race
        await Future.delayed(Duration(milliseconds: 50));
      } while (true);

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

      // Use the formal ID as the document ID for the document itself
      await docRef.set(dataMap);
      return docRef;
    } catch (e) {
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
    // Get cases from all collections (similar to React implementation)
  Future<List<Map<String, dynamic>>> getUserCasesFromAllCollections() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final List<Map<String, dynamic>> allCases = [];

      // 1. Fetch from incidents collection
      final QuerySnapshot incidentsQuery = await _firestore
          .collection('incidents')
          .where('userId', isEqualTo: currentUserId)
          .get();

      for (final doc in incidentsQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final incidentDetails = data['incidentDetails'] ?? {};
        final status = data['status'] ?? 'Reported';
        
        // Skip resolved cases as they are archived
        if (status == 'Resolved Case' || status == 'Resolved') {
          continue;
        }
        
        allCases.add({
          'id': doc.id,
          'caseNumber': incidentDetails['incidentId'] ?? doc.id,
          'name': _extractCaseName(data),
          'dateCreated': _formatTimestamp(incidentDetails['createdAt'] ?? data['createdAt']),
          'status': status,
          'source': 'incidents',
          'pdfUrl': data['pdfUrl'],
          'rawData': data,
        });
      }
      
      // 2. Fetch from missingPersons collection
      final QuerySnapshot missingPersonsQuery = await _firestore
          .collection('missingPersons')
          .where('userId', isEqualTo: currentUserId)
          .get();

      for (final doc in missingPersonsQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'Reported';
        
        // Skip resolved cases as they are archived
        if (status == 'Resolved Case' || status == 'Resolved') {
          continue;
        }
        
        allCases.add({
          'id': doc.id,
          'caseNumber': data['case_id'] ?? doc.id,
          'name': data['name'] ?? 'Unknown Person',
          'dateCreated': _formatTimestamp(data['datetime_reported']),
          'status': status,
          'source': 'missingPersons',
          'pdfUrl': data['pdfUrl'],
          'rawData': data,
        });
      }
      
      // Note: We don't fetch from archivedCases collection for active case tracking
      // as these are resolved cases that should not appear in the user's active case list
      
      // Sort all cases by date (newest first)
      allCases.sort((a, b) {
        final DateTime dateA = _parseTimestamp(a['dateCreated']);
        final DateTime dateB = _parseTimestamp(b['dateCreated']);
        return dateB.compareTo(dateA);
      });
      
      return allCases;
    } catch (e) {
      print('Error fetching user cases from all collections: $e');
      return [];
    }
  }
  
  // Helper method to extract name from different structures
  String _extractCaseName(Map<String, dynamic> data) {
    if (data['itemC'] != null) {
      final itemC = data['itemC'];
      return ((itemC['firstName'] ?? '') +
          (itemC['middleName'] != null ? ' ${itemC['middleName']}' : '') +
          (itemC['familyName'] != null ? ' ${itemC['familyName']}' : '')).trim();
    } else if (data['name'] != null) {
      return data['name'];
    } else {
      return 'Unknown Person';
    }
  }
  
  // Helper method to format timestamp
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is Map && timestamp['seconds'] != null) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp['seconds'] * 1000);
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return '';
      }
      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      print('Error formatting timestamp: $e');
      return '';
    }
  }
  
  // Helper method to parse date string or timestamp to DateTime
  DateTime _parseTimestamp(dynamic timestamp) {
    try {
      if (timestamp is String) {
        return DateFormat('dd MMM yyyy').parse(timestamp);
      } else if (timestamp is Timestamp) {
        return timestamp.toDate();
      } else if (timestamp is Map && timestamp['seconds'] != null) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp['seconds'] * 1000);
      }
      return DateTime.now();
    } catch (e) {
      return DateTime.now();
    }
  }
  
  // Generate progress steps based on status
  List<Map<String, String>> generateProgressSteps(String currentStatus) {
    // Map to convert status to step number (1-indexed)
    final Map<String, int> statusToStep = {
      'Reported': 1,
      'Under Review': 2,
      'Case Verified': 3,
      'In Progress': 4,
      'Resolved Case': 5,
      'Unresolved Case': 6,
      'Resolved': 5, // Map 'Resolved' to 'Resolved Case' step
    };
    
    final List<Map<String, String>> caseProgressSteps = [
      {'stage': 'Reported', 'status': 'Pending'},
      {'stage': 'Under Review', 'status': 'Pending'},
      {'stage': 'Case Verified', 'status': 'Pending'},
      {'stage': 'In Progress', 'status': 'Pending'},
      {'stage': 'Resolved Case', 'status': 'Pending'},
      {'stage': 'Unresolved Case', 'status': 'Pending'},
    ];
    
    final int currentStep = statusToStep[currentStatus] ?? 1;
    
    return caseProgressSteps.map((step) {
      final int stepNumber = caseProgressSteps.indexOf(step) + 1;
      String status;
      
      if (stepNumber < currentStep) {
        status = 'Completed';
      } else if (stepNumber == currentStep) {
        status = 'In Progress';
      } else {
        status = 'Pending';
      }
      
      return {
        'stage': step['stage'] ?? '',
        'status': status,
      };
    }).toList();
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
          .collection('users')
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

  // Save reporting person data for future form use
  Future<bool> saveReportingPersonData(Map<String, dynamic> reportingPersonData) async {
    try {
      if (currentUserId == null) {
        print('Error: User not authenticated');
        return false;
      }

      // Generate formal document ID for saved reporting person data
      String formalDocId = await _generateSavedDataDocumentId();

      // Create a document in savedReportingPersonData collection with formal ID
      await _firestore
          .collection('savedReportingPersonData')
          .doc(formalDocId)
          .set({
        'userId': currentUserId,
        'documentId': formalDocId,
        'reportingPersonData': reportingPersonData,
        'savedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('Successfully saved reporting person data for user: $currentUserId with ID: $formalDocId');
      return true;
    } catch (e) {
      print('Error saving reporting person data: $e');
      return false;
    }
  }

  // Generate formal document ID for saved reporting person data: SRPD-YYYYMMDD-XXXX
  Future<String> _generateSavedDataDocumentId() async {
    final today = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(today);
    final idPrefix = 'SRPD-$dateStr-'; // SRPD = Saved Reporting Person Data

    try {
      // Get all documents with today's date prefix by document ID
      final QuerySnapshot querySnapshot = await _firestore
          .collection('savedReportingPersonData')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: idPrefix + '0001')
          .where(FieldPath.documentId, isLessThanOrEqualTo: idPrefix + '9999')
          .get();

      // Find the highest sequential number by checking doc.id
      int highestNumber = 0;
      for (final doc in querySnapshot.docs) {
        final String docId = doc.id;
        if (docId.startsWith(idPrefix) && docId.length > idPrefix.length) {
          final String seqPart = docId.substring(idPrefix.length);
          final int? seqNum = int.tryParse(seqPart);
          if (seqNum != null && seqNum > highestNumber) {
            highestNumber = seqNum;
          }
        }
      }

      // Increment for next document
      final int nextNumber = highestNumber + 1;
      final String paddedNumber = nextNumber.toString().padLeft(4, '0');
      final String newDocId = '$idPrefix$paddedNumber';
      return newDocId;
    } catch (e) {
      // Fallback ID using current user ID for uniqueness
      final String fallbackId = 'SRPD-${dateStr}-USER-${currentUserId?.substring(0, 8) ?? 'UNKNOWN'}';
      return fallbackId;
    }
  }

  // Retrieve saved reporting person data
  Future<Map<String, dynamic>?> getSavedReportingPersonData() async {
    try {
      if (currentUserId == null) {
        print('Error: User not authenticated');
        return null;
      }

      // Query by userId since we're no longer using userId as document ID
      final QuerySnapshot querySnapshot = await _firestore
          .collection('savedReportingPersonData')
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
        return data['reportingPersonData'] as Map<String, dynamic>?;
      }

      return null;
    } catch (e) {
      print('Error retrieving saved reporting person data: $e');
      return null;
    }
  }

  // Check if user has saved reporting person data
  Future<bool> hasSavedReportingPersonData() async {
    try {
      if (currentUserId == null) return false;

      // Query by userId since we're no longer using userId as document ID
      final QuerySnapshot querySnapshot = await _firestore
          .collection('savedReportingPersonData')
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking for saved reporting person data: $e');
      return false;
    }
  }

  // Clear saved reporting person data
  Future<bool> clearSavedReportingPersonData() async {
    try {
      if (currentUserId == null) {
        print('Error: User not authenticated');
        return false;
      }

      // Query by userId to find the document to delete
      final QuerySnapshot querySnapshot = await _firestore
          .collection('savedReportingPersonData')
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
        print('Successfully cleared saved reporting person data for user: $currentUserId');
        return true;
      } else {
        print('No saved reporting person data found for user: $currentUserId');
        return false;
      }
    } catch (e) {
      print('Error clearing saved reporting person data: $e');
      return false;
    }
  }

  // Update existing saved reporting person data
  Future<bool> updateSavedReportingPersonData(Map<String, dynamic> reportingPersonData) async {
    try {
      if (currentUserId == null) {
        print('Error: User not authenticated');
        return false;
      }

      // Query by userId to find the document to update
      final QuerySnapshot querySnapshot = await _firestore
          .collection('savedReportingPersonData')
          .where('userId', isEqualTo: currentUserId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({
          'reportingPersonData': reportingPersonData,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('Successfully updated saved reporting person data for user: $currentUserId');
        return true;
      } else {
        // If no existing document, create a new one
        return await saveReportingPersonData(reportingPersonData);
      }
    } catch (e) {
      print('Error updating saved reporting person data: $e');
      return false;
    }
  }
}
