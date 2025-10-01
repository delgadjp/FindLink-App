import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:io' show File;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
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

  // Helper to build organized document IDs for saved reporting person data
  String _generateSavedReportingPersonDocId(
    String userId, {
    String? firstName,
    DateTime? referenceDate,
  }) {
    final dateStr = DateFormat('yyyyMMdd').format(referenceDate ?? DateTime.now());
    final sanitizedFirstName = (firstName ?? '')
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();

    if (sanitizedFirstName.isNotEmpty) {
      return 'SRPD-$dateStr-$sanitizedFirstName';
    }

    final sanitizedUser = userId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final normalized = sanitizedUser.isNotEmpty ? sanitizedUser : 'USER';
    final suffix = normalized.length >= 6
        ? normalized.substring(0, 6)
        : normalized.padRight(6, '0');
    return 'SRPD-$dateStr-$suffix';
  }

  // Fetch the saved reporting person document for the current user, if any
  Future<DocumentSnapshot<Map<String, dynamic>>?> _getSavedReportingPersonDocSnapshot() async {
    if (currentUserId == null) return null;

    final query = await _firestore
        .collection('savedReportingPersonData')
        .where('userId', isEqualTo: currentUserId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return query.docs.first;
    }

    return null;
  }

  Future<String> _resolveSavedReportingPersonDocId(
    CollectionReference<Map<String, dynamic>> collection,
    String desiredDocId,
    String userId, {
    String? existingDocId,
  }) async {
    if (existingDocId == desiredDocId) {
      return desiredDocId;
    }

    final desiredSnapshot = await collection.doc(desiredDocId).get();
    if (!desiredSnapshot.exists) {
      return desiredDocId;
    }

    final desiredData = desiredSnapshot.data();
    if (desiredData != null && desiredData['userId'] == userId) {
      return desiredDocId;
    }

    final sanitizedUser = userId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final shortUser = sanitizedUser.length >= 6
        ? sanitizedUser.substring(0, 6)
        : sanitizedUser.padRight(6, '0');
    final candidate = '$desiredDocId-$shortUser';

    if (candidate == existingDocId) {
      return candidate;
    }

    final candidateSnapshot = await collection.doc(candidate).get();
    if (!candidateSnapshot.exists) {
      return candidate;
    }

    final fallbackSuffix = DateFormat('HHmmss').format(DateTime.now());
    return '$desiredDocId-$fallbackSuffix';
  }
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

  // Helper method to optimize image quality before Vision API call
  Future<Uint8List> _optimizeImageForVision(Uint8List imageBytes) async {
    try {
      // Decode image to check dimensions and quality
      img.Image? image = img.decodeImage(imageBytes);
      if (image == null) return imageBytes;
      
      // Check and optimize resolution (ideal: 640-1024px on longest side)
      int maxDimension = math.max(image.width, image.height);
      if (maxDimension > 1024) {
        // Resize maintaining aspect ratio
        double scale = 1024.0 / maxDimension;
        int newWidth = (image.width * scale).round();
        int newHeight = (image.height * scale).round();
        image = img.copyResize(image, width: newWidth, height: newHeight);
      } else if (maxDimension < 400) {
        // If too small, upscale slightly for better detection
        double scale = 400.0 / maxDimension;
        int newWidth = (image.width * scale).round();
        int newHeight = (image.height * scale).round();
        image = img.copyResize(image, width: newWidth, height: newHeight);
      }
      
      // Enhance contrast and brightness for better detection
      image = img.adjustColor(image, 
        contrast: 1.1,    // Slight contrast boost
        brightness: 1.05, // Slight brightness boost
        saturation: 1.1   // Slight saturation boost
      );
      
      // Apply subtle sharpening for better edge detection
      image = img.convolution(image, filter: [
        0, -1, 0,
        -1, 5, -1,
        0, -1, 0
      ]);
      
      // Convert back to bytes with optimal quality
      return Uint8List.fromList(img.encodeJpg(image, quality: 85));
    } catch (e) {
      print('Error optimizing image: $e');
      return imageBytes; // Return original if optimization fails
    }
  }

  // Add method to validate image using Google Vision API with improved accuracy
  Future<Map<String, dynamic>> validateImageWithGoogleVision(dynamic imageData) async {
    try {
      Map<String, dynamic> result = {
        'isValid': false,
        'containsHuman': false,
        'confidence': 0.0,
        'message': 'Image validation failed'
      };
      
      Uint8List imageBytes;
      
      if (kIsWeb) {
        if (imageData is Uint8List) {
          imageBytes = imageData;
        } else if (imageData is String) {
          if (imageData.startsWith('data:image')) {
            imageBytes = base64Decode(imageData.split(',')[1]);
          } else {
            final Uint8List bytes = Uri.parse(imageData).data!.contentAsBytes();
            imageBytes = bytes;
          }
        } else {
          throw Exception('Unsupported image data type for web validation');
        }
      } else {
        if (imageData is File) {
          imageBytes = await imageData.readAsBytes();
        } else if (imageData is String && imageData.isNotEmpty) {
          final File file = File(imageData);
          if (await file.exists()) {
            imageBytes = await file.readAsBytes();
          } else {
            throw Exception('File does not exist at path: $imageData');
          }
        } else if (imageData is Uint8List) {
          imageBytes = imageData;
        } else {
          throw Exception('Unsupported image data type for mobile validation');
        }
      }
      
      // Optimize image for better Vision API accuracy
      final optimizedBytes = await _optimizeImageForVision(imageBytes);
      final base64Image = base64Encode(optimizedBytes);
      
      final response = await http.post(
        Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$_visionApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'requests': [{
            'image': {
              'content': base64Image
            },
            'features': [
              {'type': 'LABEL_DETECTION', 'maxResults': 20},
              {'type': 'FACE_DETECTION', 'maxResults': 10},
              {'type': 'OBJECT_LOCALIZATION', 'maxResults': 20},
              {'type': 'SAFE_SEARCH_DETECTION'},
              {'type': 'TEXT_DETECTION', 'maxResults': 5}, // Can help identify context
              {'type': 'CROP_HINTS', 'maxResults': 3}, // Helps identify main subject
              {'type': 'IMAGE_PROPERTIES'} // Color analysis for better context
            ]
          }]
        })
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final annotations = jsonResponse['responses'][0];
        
        // Use improved multi-criteria validation
        final validationResult = _analyzeHumanDetection(annotations);
        
        result = {
          'isValid': true,
          'containsHuman': validationResult['containsHuman'],
          'confidence': validationResult['confidence'],
          'message': validationResult['message'],
          'details': validationResult['details'], // Add detailed breakdown
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

  // Improved human detection analysis with multiple validation criteria
  Map<String, dynamic> _analyzeHumanDetection(Map<String, dynamic> annotations) {
    double faceScore = 0.0;
    double objectScore = 0.0;
    double labelScore = 0.0;
    double contextScore = 0.0; // New context scoring
    double totalConfidence = 0.0;
    
    List<String> detectedFeatures = [];
    List<String> detailBreakdown = [];
    
    // 1. Face Detection Analysis (Highest weight - most reliable)
    if (annotations.containsKey('faceAnnotations') && 
        annotations['faceAnnotations'] is List && 
        annotations['faceAnnotations'].isNotEmpty) {
      
      for (var face in annotations['faceAnnotations']) {
        double faceConfidence = face['detectionConfidence']?.toDouble() ?? 0.0;
        
        // Enhanced face quality assessment
        String joyLikelihood = face['joyLikelihood'] ?? 'UNKNOWN';
        String angerLikelihood = face['angerLikelihood'] ?? 'UNKNOWN';
        String surpriseLikelihood = face['surpriseLikelihood'] ?? 'UNKNOWN';
        String blurredLikelihood = face['blurredLikelihood'] ?? 'UNKNOWN';
        
        // Boost confidence for faces with clear emotional expressions
        double emotionBoost = 0.0;
        if (joyLikelihood == 'LIKELY' || joyLikelihood == 'VERY_LIKELY' ||
            angerLikelihood == 'LIKELY' || angerLikelihood == 'VERY_LIKELY' ||
            surpriseLikelihood == 'LIKELY' || surpriseLikelihood == 'VERY_LIKELY') {
          emotionBoost = 0.1; // 10% boost for emotional expressions
        }
        
        // Penalize for blurred faces
        double blurPenalty = 0.0;
        if (blurredLikelihood == 'LIKELY' || blurredLikelihood == 'VERY_LIKELY') {
          blurPenalty = 0.2; // 20% penalty for blurred faces
        }
        
        double adjustedConfidence = faceConfidence + emotionBoost - blurPenalty;
        
        // Only count faces with high confidence (>0.6 after adjustments)
        if (adjustedConfidence > 0.6) {
          faceScore = math.max(faceScore, adjustedConfidence);
          detectedFeatures.add('High-quality face (${(adjustedConfidence * 100).toStringAsFixed(1)}%)');
        } else if (adjustedConfidence > 0.4) {
          // Medium confidence faces get lower weight
          faceScore = math.max(faceScore, adjustedConfidence * 0.7);
          detectedFeatures.add('Medium-quality face (${(adjustedConfidence * 100).toStringAsFixed(1)}%)');
        }
      }
    }
    
    // 2. Object Localization Analysis (Medium weight)
    if (annotations.containsKey('localizedObjectAnnotations') && 
        annotations['localizedObjectAnnotations'] is List) {
      
      for (var obj in annotations['localizedObjectAnnotations']) {
        String objName = (obj['name']?.toString() ?? '').toLowerCase();
        double objConfidence = obj['score']?.toDouble() ?? 0.0;
        
        // Analyze bounding box for size validation
        if (obj.containsKey('boundingPoly') && obj['boundingPoly'].containsKey('normalizedVertices')) {
          var vertices = obj['boundingPoly']['normalizedVertices'];
          if (vertices is List && vertices.length >= 4) {
            double width = (vertices[1]['x'] ?? 0.0) - (vertices[0]['x'] ?? 0.0);
            double height = (vertices[2]['y'] ?? 0.0) - (vertices[0]['y'] ?? 0.0);
            double area = width * height;
            
            // Boost confidence for larger objects (likely to be main subjects)
            if (area > 0.1) { // Object takes up >10% of image
              objConfidence *= 1.2;
            }
          }
        }
        
        // Only consider high-confidence person objects
        if ((objName == 'person' || objName == 'human') && objConfidence > 0.75) {
          objectScore = math.max(objectScore, objConfidence);
          detectedFeatures.add('Person object (${(objConfidence * 100).toStringAsFixed(1)}%)');
        }
      }
    }
    
    // 3. Context Analysis using Crop Hints and Text Detection
    if (annotations.containsKey('cropHintsAnnotation') && 
        annotations['cropHintsAnnotation'].containsKey('cropHints')) {
      var cropHints = annotations['cropHintsAnnotation']['cropHints'];
      if (cropHints is List && cropHints.isNotEmpty) {
        // If crop hints suggest a portrait-style crop, boost context score
        var firstHint = cropHints[0];
        if (firstHint.containsKey('boundingPoly')) {
          contextScore += 0.2; // 20% boost for portrait-style composition
          detectedFeatures.add('Portrait composition detected');
        }
      }
    }
    
    // Text detection context (avoid photos of photos/documents)
    bool hasSuspiciousText = false;
    if (annotations.containsKey('textAnnotations') && 
        annotations['textAnnotations'] is List &&
        annotations['textAnnotations'].isNotEmpty) {
      
      String fullText = '';
      for (var textAnnotation in annotations['textAnnotations']) {
        String description = (textAnnotation['description']?.toString() ?? '').toLowerCase();
        fullText += '$description ';
      }
      
      // Check for suspicious text that indicates photos of documents/IDs
      List<String> suspiciousTerms = [
        'driver', 'license', 'passport', 'id card', 'identification',
        'birth certificate', 'social security', 'voter', 'employee',
        'student id', 'membership', 'card', 'official', 'government'
      ];
      
      for (String term in suspiciousTerms) {
        if (fullText.contains(term)) {
          hasSuspiciousText = true;
          detailBreakdown.add('Suspicious text detected: $term');
          break;
        }
      }
    }
    
    // 4. Label Detection Analysis (Lowest weight - most prone to false positives)
    if (annotations.containsKey('labelAnnotations') && 
        annotations['labelAnnotations'] is List) {
      
      // Enhanced human-related labels with confidence requirements
      final Map<String, double> humanLabels = {
        'human face': 0.85,
        'facial expression': 0.8,
        'human': 0.9,
        'people': 0.85,
        'human head': 0.8,
        'human eye': 0.8,
        'human hair': 0.75,
        'human nose': 0.8,
        'human mouth': 0.8,
        'portrait': 0.7,
        'selfie': 0.85,
        'smile': 0.75,
        'skin': 0.8,
        'forehead': 0.8,
        'cheek': 0.8,
        'eyebrow': 0.8
      };
      
      // Expanded exclude labels for better filtering
      final Set<String> excludeLabels = {
        'person', 'face', 'human body', // Too generic
        'art', 'artwork', 'drawing', 'painting', 'illustration', 'sketch',
        'statue', 'sculpture', 'mannequin', 'toy', 'doll', 'figure',
        'photo', 'photograph', 'image', 'picture', 'selfie',
        'poster', 'sign', 'text', 'logo', 'document',
        'screen', 'monitor', 'display', 'television', 'phone'
      };
      
      for (var label in annotations['labelAnnotations']) {
        String description = (label['description']?.toString() ?? '').toLowerCase();
        double labelConfidence = label['score']?.toDouble() ?? 0.0;
        
        // Skip excluded labels
        if (excludeLabels.contains(description)) {
          detailBreakdown.add('Excluded: $description (${(labelConfidence * 100).toStringAsFixed(1)}%)');
          continue;
        }
        
        // Check for specific human labels with required confidence
        for (String humanLabel in humanLabels.keys) {
          double requiredConfidence = humanLabels[humanLabel]!;
          if (description.contains(humanLabel) && labelConfidence >= requiredConfidence) {
            labelScore = math.max(labelScore, labelConfidence);
            detectedFeatures.add('$humanLabel (${(labelConfidence * 100).toStringAsFixed(1)}%)');
            break;
          }
        }
      }
    }
    
    // 5. Calculate enhanced weighted final score
    // Face detection: 50% weight (most reliable)
    // Object detection: 25% weight (moderately reliable) 
    // Label detection: 15% weight (least reliable)
    // Context score: 10% weight (composition and quality indicators)
    totalConfidence = (faceScore * 0.5) + (objectScore * 0.25) + (labelScore * 0.15) + (contextScore * 0.1);
    
    // Apply penalties for suspicious content
    if (hasSuspiciousText) {
      totalConfidence *= 0.7; // 30% penalty for document-like content
      detailBreakdown.add('Applied penalty for document-like content');
    }
    
    // Require minimum confidence threshold of 0.7 for positive detection (increased from 0.65)
    bool containsHuman = totalConfidence >= 0.7 && !hasSuspiciousText;
    
    // Generate detailed message
    String message;
    if (containsHuman) {
      message = 'Human detected with ${(totalConfidence * 100).toStringAsFixed(1)}% confidence.';
      if (detectedFeatures.isNotEmpty) {
        message += '\nDetected features: ${detectedFeatures.take(3).join(', ')}';
        if (detectedFeatures.length > 3) {
          message += ' and ${detectedFeatures.length - 3} more...';
        }
      }
    } else {
      message = 'No reliable human detection. Confidence: ${(totalConfidence * 100).toStringAsFixed(1)}%';
      if (hasSuspiciousText) {
        message += '\nImage appears to be a document or ID photo.';
      } else if (detectedFeatures.isNotEmpty) {
        message += '\nWeak features found: ${detectedFeatures.take(2).join(', ')}';
      } else {
        message += '\nNo clear human features detected.';
      }
    }
    
    return {
      'containsHuman': containsHuman,
      'confidence': totalConfidence,
      'message': message,
      'details': {
        'faceScore': faceScore,
        'objectScore': objectScore,
        'labelScore': labelScore,
        'contextScore': contextScore,
        'hasSuspiciousText': hasSuspiciousText,
        'detectedFeatures': detectedFeatures,
        'breakdown': detailBreakdown,
      }
    };
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

      final collection = _firestore.collection('savedReportingPersonData');
      final existingSnapshot = await _getSavedReportingPersonDocSnapshot();
      final existingData = existingSnapshot?.data();
      Map<String, dynamic>? existingReportingData;
      if (existingData != null) {
        final rpData = existingData['reportingPersonData'];
        if (rpData is Map<String, dynamic>) {
          existingReportingData = Map<String, dynamic>.from(rpData);
        }
      }

      final savedAtField = existingData?['savedAt'];
      DateTime? savedAtDate;
      if (savedAtField is Timestamp) {
        savedAtDate = savedAtField.toDate();
      } else if (savedAtField is DateTime) {
        savedAtDate = savedAtField;
      }

      final targetFirstName = (reportingPersonData['firstName'] ?? existingReportingData?['firstName'])?.toString();
      final desiredDocId = _generateSavedReportingPersonDocId(
        currentUserId!,
        firstName: targetFirstName,
        referenceDate: savedAtDate,
      );

      final resolvedDocId = await _resolveSavedReportingPersonDocId(
        collection,
        desiredDocId,
        currentUserId!,
        existingDocId: existingSnapshot?.id,
      );

      if (existingSnapshot != null && existingSnapshot.id != resolvedDocId) {
        final newDocRef = collection.doc(resolvedDocId);
        await newDocRef.set({
          'userId': currentUserId,
          'documentId': resolvedDocId,
          'reportingPersonData': reportingPersonData,
          'savedAt': savedAtField ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        await existingSnapshot.reference.delete();
        print('Migrated saved reporting person data for user: $currentUserId from ${existingSnapshot.id} to $resolvedDocId');
        return true;
      }

      DocumentReference<Map<String, dynamic>> targetDocRef;
      bool isNewDoc = false;

      if (existingSnapshot == null) {
        targetDocRef = collection.doc(resolvedDocId);
        isNewDoc = true;
      } else {
        targetDocRef = existingSnapshot.reference;
      }

      final Map<String, dynamic> payload = {
        'userId': currentUserId,
        'documentId': targetDocRef.id,
        'reportingPersonData': reportingPersonData,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isNewDoc) {
        payload['savedAt'] = FieldValue.serverTimestamp();
        await targetDocRef.set(payload);
        print('Successfully saved reporting person data for user: $currentUserId with ID: ${targetDocRef.id}');
      } else {
        await targetDocRef.update(payload);
        print('Successfully updated existing reporting person data for user: $currentUserId with ID: ${targetDocRef.id}');
      }
      return true;
    } catch (e) {
      print('Error saving reporting person data: $e');
      return false;
    }
  }

  // Retrieve saved reporting person data
  Future<Map<String, dynamic>?> getSavedReportingPersonData() async {
    try {
      if (currentUserId == null) {
        print('Error: User not authenticated');
        return null;
      }

      final existingSnapshot = await _getSavedReportingPersonDocSnapshot();

      if (existingSnapshot != null) {
        final data = existingSnapshot.data();
        return data?['reportingPersonData'] as Map<String, dynamic>?;
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

      final existingSnapshot = await _getSavedReportingPersonDocSnapshot();

      return existingSnapshot != null;
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

      final existingSnapshot = await _getSavedReportingPersonDocSnapshot();

      if (existingSnapshot != null) {
        await existingSnapshot.reference.delete();
        print('Successfully cleared saved reporting person data for user: $currentUserId');
        return true;
      }

      print('No saved reporting person data found for user: $currentUserId');
      return false;
    } catch (e) {
      print('Error clearing saved reporting person data: $e');
      return false;
    }
  }

  // Update existing saved reporting person data
  Future<bool> updateSavedReportingPersonData(Map<String, dynamic> reportingPersonData) async {
    return await saveReportingPersonData(reportingPersonData);
  }
}
