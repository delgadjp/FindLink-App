import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/irf_model.dart';
import 'package:intl/intl.dart';
import '../storage/local_draft_service.dart';  // Import the new local draft service
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart';

class IRFService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final LocalDraftService _localDraftService = LocalDraftService();
  
  // Google Vision API key - use the same one as in TipService
  final String _visionApiKey = 'AIzaSyBpeXXTgrLeT9PuUT-8H-AXPTW6sWlnys0';

  // Add helper method to upload image to Firebase Storage
  Future<String?> _uploadImage(dynamic imageData, String irfId) async {
    try {
      // Create reference to the file path in storage
      final Reference storageRef = _storage
          .ref()
          .child('irf-attachments')
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

  // Expose the local draft service for direct access
  LocalDraftService get localDraftService => _localDraftService;
  
  // Collection reference - Uses only irf-test collection
  CollectionReference get irfCollection => _firestore.collection('irf-test');
  
  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;  // Generate a formal document ID format: IRF-YYYYMMDD-XXXX (where XXXX is sequential starting at 0001)
  Future<String> generateFormalDocumentId() async {
    final today = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(today);
    final idPrefix = 'IRF-$dateStr-';

    try {
      // Get all documents with today's date prefix
      final QuerySnapshot querySnapshot = await _firestore
          .collection('irf-test')
          .where('documentId', isGreaterThanOrEqualTo: idPrefix)
          .where('documentId', isLessThan: idPrefix + '\uf8ff')
          .get();

      // Debug info
      print('Found ${querySnapshot.docs.length} documents for today (${dateStr})');
      
      // Find the highest sequential number
      int highestNumber = 0;
      
      for (final doc in querySnapshot.docs) {
        final String? docId = doc['documentId'] as String?;
        if (docId != null && docId.startsWith(idPrefix) && docId.length > idPrefix.length) {
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
      
      // Add user ID and timestamps
      final dataWithMetadata = {
        ...irfData.toMap(),
        'documentId': formalId, // Store the ID inside the document too
        'userId': currentUserId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'status': 'submitted', // pending, submitted, approved, rejected
        'type': 'report' // Mark this document as an IRF report
      };
      
      // Use the formal ID as the document ID for the document itself
      final docRef = irfCollection.doc(formalId);
      await docRef.set(dataWithMetadata);
      print('Successfully submitted IRF with ID: $formalId');
      return docRef;
    } catch (e) {
      print('Error submitting IRF: $e');
      rethrow; // Rethrow to handle in UI
    }
  }
  
  // Save IRF draft locally using LocalDraftService
  Future<String> saveIRFDraft(IRFModel irfData) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      // Save draft locally instead of to Firebase
      final String draftId = await _localDraftService.saveDraft(irfData);
      return draftId;
    } catch (e) {
      print('Error saving local draft: $e');
      rethrow; // Rethrow to handle in UI
    }
  }
  
  // Update existing IRF
  Future<void> updateIRF(String irfId, IRFModel irfData, {bool isDraft = false}) async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // If it's a draft, update locally instead of in Firebase
    if (isDraft) {
      await _localDraftService.updateDraft(irfId, irfData);
      return;
    }
    
    // Otherwise update in Firebase
    final dataWithMetadata = {
      ...irfData.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'submitted'
    };
    
    return await irfCollection.doc(irfId).update(dataWithMetadata);
  }
  
  // Get IRF by ID - check local drafts first, then Firebase
  Future<dynamic> getIRF(String irfId) async {
    // Check if it's a local draft
    if (irfId.startsWith('LOCAL_DRAFT_')) {
      return await _localDraftService.getDraft(irfId);
    }
    
    // Otherwise get from Firebase
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
  
  // Get user's IRF drafts from local storage
  Future<List<IRFModel>> getUserDrafts() async {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
    
    // Get drafts from local storage
    List<Map<String, dynamic>> localDrafts = await _localDraftService.getLocalDrafts();
    
    // Convert to IRF models
    return localDrafts.map((draft) => _localDraftService.draftToModel(draft)).toList();
  }
  
  // Delete IRF - check if it's a local draft first
  Future<void> deleteIRF(String irfId) async {
    // If it's a local draft, delete locally
    if (irfId.startsWith('LOCAL_DRAFT_')) {
      bool success = await _localDraftService.deleteDraft(irfId);
      if (!success) {
        throw Exception('Failed to delete local draft');
      }
      return;
    }
    
    // Otherwise delete from Firebase
    return await irfCollection.doc(irfId).delete();
  }
}
