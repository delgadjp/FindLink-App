import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
export 'dart:typed_data';
import '/core/app_export.dart';
import 'dart:typed_data';  // Add this for web support
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math; // Import math library for distance calculations and image processing
import 'package:image/image.dart' as img; // Import image package for optimization

class TipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Google Vision API key
  final String _visionApiKey = 'AIzaSyBpeXXTgrLeT9PuUT-8H-AXPTW6sWlnys0';

  // Generate a formal document ID format: REPORT-YYYYMMDD-XXXX (where XXXX is sequential starting at 0001)
  Future<String> generateFormalReportId() async {
    final today = DateTime.now();
    final dateStr = "${today.year.toString().padLeft(4, '0')}${today.month.toString().padLeft(2, '0')}${today.day.toString().padLeft(2, '0')}";
    final idPrefix = 'REPORTS_$dateStr-';
    try {
      final QuerySnapshot querySnapshot = await _firestore
          .collection('reports')
          .get();
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
      final int nextNumber = highestNumber + 1;
      final String paddedNumber = nextNumber.toString().padLeft(3, '0');
      final String newDocId = '$idPrefix$paddedNumber';
      return newDocId;
    } catch (e) {
      print('Error generating report document ID: $e');
      final String paddedNumber = '001';
      final String fallbackId = '$idPrefix$paddedNumber';
      return fallbackId;
    }
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

  // Enhanced method to validate image using Google Vision API with preprocessing
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

  Future<void> submitTip({
    required String dateLastSeen,
    required String timeLastSeen,
    String heightRange = "Unknown", 
    required String hairColor,
    required String clothing,
    required String features,
    required String description,
    required double lat,
    required double lng,
    required String userId,
    required String address,
    dynamic imageData, 
    bool validateImage = true, 
    required String caseId, // Add caseId to fetch missing person name
    required String missingPersonName, // Add missingPersonName as a required parameter
  }) async {
    try {
      // Validate image if provided and validation is enabled
      Map<String, dynamic> imageValidation = {'isValid': true, 'containsHuman': true};
      bool shouldUploadImage = imageData != null;
      
      if (imageData != null && validateImage) {
        imageValidation = await validateImageWithGoogleVision(imageData);
        
        // If validation failed completely, continue without the image
        if (!imageValidation['isValid']) {
          print('Image validation failed: [${imageValidation['message']}');
          shouldUploadImage = false;
        }
        // If validation succeeded but no human detected, don't upload the image
        else if (!imageValidation['containsHuman']) {
          print('No human detected in the image. The image will be automatically removed.');
          shouldUploadImage = false;
        }
      }
    
      // Generate formal reportId
      final String reportId = await generateFormalReportId();
        // Fetch missing person name by caseId using the correct field name
      String name = missingPersonName;
      try {
        final doc = await FirebaseFirestore.instance.collection('missingPersons').where('alarm_id', isEqualTo: caseId).get();
        if (doc.docs.isNotEmpty) {
          name = doc.docs.first.data()['name'] ?? missingPersonName;
          print('Found missing person in database: $name (using alarm_id: $caseId)');
        } else {
          print('No missing person found with alarm_id: $caseId, using provided name: $missingPersonName');
        }
      } catch (e) {
        print('Error fetching missing person name: $e');
      }
      
      // Format coordinates as GeoPoint for Firestore
      final GeoPoint coordinates = GeoPoint(lat, lng);

      // Format dateTimeLastSeen and timestamp
      final Timestamp createdAtTimestamp = Timestamp.now();
      final Timestamp dateTimeLastSeenTimestamp = Timestamp.fromDate(DateTime.parse(dateLastSeen + 'T' + timeLastSeen));

      // Prepare the data map
      final Map<String, dynamic> reportData = {
        'clothing': clothing,
        'coordinates': coordinates,
        'createdAt': createdAtTimestamp,
        'dateTimeLastSeen': dateTimeLastSeenTimestamp,
        'description': description,
        'features': features,
        'hairColor': hairColor,
        'height': heightRange,
        'imageUrl': null, // Will be set after upload
        'name': name,
        'timestamp': createdAtTimestamp,
        'uid': userId,
        'reportId': reportId,
      };
      
      // Add image validation results if image was provided and validated
      if (imageData != null && validateImage) {
        reportData['imageValidation'] = {
          'containsHuman': imageValidation['containsHuman'],
          'confidence': imageValidation['confidence'],
          'wasRemoved': !shouldUploadImage && imageData != null,
        };
      }
      
      // Upload image only if validation passed or was skipped
      if (shouldUploadImage) {
        final String? imageUrl = await _uploadImage(imageData, reportId);
        if (imageUrl != null) {
          // Add the image URL to the report data
          reportData['imageUrl'] = imageUrl;
        }
      }
      
      // Create the report document in Firestore with custom reportId
      await _firestore.collection('reports').doc(reportId).set(reportData)
        .catchError((e) {
          print("Firestore write error: \u001b[${e.toString()}");
          throw e;
        });

      print('Report successfully added with custom reportId: $reportId');
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

  // New method to find tips within a specified radius
  Future<List<Map<String, dynamic>>> findNearbyTips(double latitude, double longitude, double radiusInMeters) async {
    try {
      // Get all tips from the database
      final QuerySnapshot snapshot = await _firestore
          .collection('reports')
          .get();

      // Filter tips by distance
      List<Map<String, dynamic>> nearbyTips = [];
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
          // Check if this tip has coordinates
        if (data.containsKey('coordinates') && data['coordinates'] != null) {
          double? tipLat;
          double? tipLng;
          
          // Handle GeoPoint format
          if (data['coordinates'] is GeoPoint) {
            final GeoPoint geoPoint = data['coordinates'] as GeoPoint;
            tipLat = geoPoint.latitude;
            tipLng = geoPoint.longitude;
          }
          // Handle legacy coordinate formats
          else if (data['coordinates'] is Map) {
            tipLat = data['coordinates']['lat']?.toDouble();
            tipLng = data['coordinates']['lng']?.toDouble();
          }
          // Handle string format: "[lat° N, lng° E]"
          else if (data['coordinates'] is String) {
            final regex = RegExp(r'([\d.\-]+)°\s*N,\s*([\d.\-]+)°\s*E');
            final match = regex.firstMatch(data['coordinates']);
            if (match != null) {
              tipLat = double.tryParse(match.group(1)!);
              tipLng = double.tryParse(match.group(2)!);
            }
          }
          
          if (tipLat != null && tipLng != null) {
            final double distance = _calculateDistance(
              latitude, longitude, tipLat, tipLng);
            
            // If within radius, add to result list
            if (distance <= radiusInMeters) {
              data['id'] = doc.id;
              data['distance'] = distance;
              nearbyTips.add(data);
            }
          }
        }
      }
      
      // Sort by distance (closest first)
      nearbyTips.sort((a, b) => (a['distance'] as double).compareTo(b['distance'] as double));
      
      return nearbyTips;
    } catch (e) {
      print('Error finding nearby tips: $e');
      return [];
    }
  }

  // Helper method to calculate distance between two points using the Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    // Convert degrees to radians
    final double lat1Rad = _degreesToRadians(lat1);
    final double lon1Rad = _degreesToRadians(lon1);
    final double lat2Rad = _degreesToRadians(lat2);
    final double lon2Rad = _degreesToRadians(lon2);
    
    // Haversine formula
    final double dLat = lat2Rad - lat1Rad;
    final double dLon = lon2Rad - lon1Rad;
    final double a = 
        math.sin(dLat/2) * math.sin(dLat/2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) * 
        math.sin(dLon/2) * math.sin(dLon/2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1-a));
    
    return earthRadius * c; // Distance in meters
  }
  
  // Helper to convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}