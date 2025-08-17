import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:uuid/uuid.dart';
import '/core/app_export.dart';

/// A simpler location service that uses only Geolocator
/// This avoids the complex background geolocation plugin conflicts
class SimpleLocationService {
  static final SimpleLocationService _instance = SimpleLocationService._internal();
  factory SimpleLocationService() => _instance;
  SimpleLocationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = Uuid();

  bool _isTracking = false;
  Timer? _locationTimer;
  bool get isTracking => _isTracking;

  /// Initialize the simple location service
  Future<void> initializeLocationService() async {
    try {
      print('Initializing SimpleLocationService...');
      
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable location services in your device settings.');
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied. Please grant location access to use FindMe.');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied. Please enable location access in app settings.');
      }

      // Don't test location access during initialization to avoid timeouts
      // Location will be tested when tracking actually starts
      print('SimpleLocationService initialized successfully');
    } catch (e) {
      print('Error initializing SimpleLocationService: $e');
      rethrow;
    }
  }

  /// Start location tracking with periodic updates
  Future<bool> startTracking() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return false;
      }

      // Check if already tracking
      if (_isTracking) {
        print('Location tracking is already active');
        return true;
      }

      // Find user document by userId field
      final userQuery = await _firestore
          .collection('users')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();
      
      if (userQuery.docs.isEmpty) {
        print('User document not found');
        return false;
      }

      final userDoc = userQuery.docs.first;
      final userData = userDoc.data();
      
      if (userData['findMeEnabled'] != true) {
        print('FindMe feature not enabled for user');
        return false;
      }

      print('Starting simple location tracking...');
      _isTracking = true;
      
      // Update user's tracking status using the correct document reference
      await userDoc.reference.update({
        'isTracking': true,
        'trackingStartedAt': FieldValue.serverTimestamp(),
      });

      // Start periodic location updates every 5 minutes (300 seconds)
      _locationTimer = Timer.periodic(Duration(minutes: 5), (timer) async {
        try {
          if (!_isTracking) {
            timer.cancel();
            return;
          }
          await _updateLocation();
        } catch (e) {
          print('Error in location timer: $e');
          // Don't stop tracking for individual location update failures
        }
      });

      // Get initial location
      _updateLocation();
      
      print('Simple location tracking started successfully');
      return true;
    } catch (e) {
      print('Error starting location tracking: $e');
      _isTracking = false;
      return false;
    }
  }

  /// Stop location tracking
  Future<void> stopTracking() async {
    try {
      // Only try to stop if we're actually tracking
      if (_isTracking) {
        print('Stopping simple location tracking...');
        _locationTimer?.cancel();
        _locationTimer = null;
        print('Simple location tracking stopped');
      }
      
      _isTracking = false;
      
      final user = _auth.currentUser;
      if (user != null) {
        // Find user document by userId field
        final userQuery = await _firestore
            .collection('users')
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();
        
        if (userQuery.docs.isNotEmpty) {
          await userQuery.docs.first.reference.update({
            'isTracking': false,
            'trackingStoppedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (e) {
      print('Error stopping location tracking: $e');
      // Still set tracking to false even if stop failed
      _isTracking = false;
      rethrow;
    }
  }

  /// Generate a formal document ID format for locations: LOC_YYYYMMDD_XXX_HHMMSS (where XXX is user prefix and HHMMSS is time)
  Future<String> _generateLocationDocumentId(String userId) async {
    try {
      // Find the user document to get their custom document ID format
      final userQuery = await _firestore
          .collection('users')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (userQuery.docs.isNotEmpty) {
        final userDocId = userQuery.docs.first.id; // e.g., "USER_20250808_HOM_001"
        
        // Extract the prefix part (e.g., "HOM" from "USER_20250808_HOM_001")
        final parts = userDocId.split('_');
        final userPrefix = parts.length >= 3 ? parts[2] : 'USR';
        
        // Create location document ID with current date and time
        final now = DateTime.now();
        final datePart = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
        final timePart = "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";
        
        return "LOC_${datePart}_${userPrefix}_${timePart}";
      } else {
        // Fallback to using UUID if user document not found
        return _uuid.v4();
      }
    } catch (e) {
      print('Error generating location document ID: $e');
      // Fallback to UUID
      return _uuid.v4();
    }
  }

  /// Update current location
  Future<void> _updateLocation() async {
    try {
      final user = _auth.currentUser;
      if (user == null || !_isTracking) return;

      // Find user document by userId field to get the correct document ID
      final userQuery = await _firestore
          .collection('users')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();
      
      if (userQuery.docs.isEmpty) {
        print('User document not found for location update');
        return;
      }

      // Check if FindMe is enabled
      final userData = userQuery.docs.first.data();
      if (userData['findMeEnabled'] != true) {
        print('FindMe feature not enabled for user');
        return;
      }

      // Get current position with longer timeout and fallback
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30), // Increased timeout
        );
      } catch (e) {
        print('High accuracy location failed, trying medium accuracy: $e');
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 20),
          );
        } catch (e2) {
          print('Medium accuracy location failed, trying low accuracy: $e2');
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 15),
          );
        }
      }

      // Get address from coordinates
      String? address;
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          address = '${placemark.street}, ${placemark.locality}, ${placemark.country}';
        }
      } catch (e) {
        print('Error getting address: $e');
        // Continue without address
      }

      // Create location data with custom document ID
      final locationDocId = await _generateLocationDocumentId(user.uid);
      final locationData = LocationData(
        id: locationDocId, // Use the custom document ID
        userId: user.uid, // Keep the auth UID for identification
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
        address: address,
      );

      print('Saving location for user ${user.uid}: ${position.latitude}, ${position.longitude}');
      print('Location document ID: $locationDocId');
      print('Location data userId field: ${user.uid}');

      // Save to findMeLocations collection with custom document ID
      await _firestore
          .collection('findMeLocations')
          .doc(locationDocId)
          .set(locationData.toMap());

      // Verify the saved data by reading it back
      final savedDoc = await _firestore
          .collection('findMeLocations')
          .doc(locationDocId)
          .get();
      
      if (savedDoc.exists) {
        final savedData = savedDoc.data();
        print('✅ Location saved and verified:');
        print('   Doc ID: ${savedDoc.id}');
        print('   UserId in document: ${savedData?['userId']}');
        print('   Coordinates: ${savedData?['latitude']}, ${savedData?['longitude']}');
        
        if (savedData?['userId'] != user.uid) {
          print('❌ CRITICAL ERROR: Saved location userId does not match current user!');
        }
      } else {
        print('❌ ERROR: Failed to save location document');
      }

      // Also update the user's lastKnownLocation field for trusted contacts to access
      await userQuery.docs.first.reference.update({
        'lastKnownLocation': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': FieldValue.serverTimestamp(),
          'address': address,
        },
        'lastLocationUpdate': FieldValue.serverTimestamp(),
      });

      // Keep only last 100 locations (cleanup old data)
      await _cleanupOldLocations(user.uid); // Pass auth UID for querying
      
      print('Location updated: ${position.latitude}, ${position.longitude}');
      
    } catch (e) {
      print('Error updating location: $e');
      // Don't stop tracking for individual location failures
      // Continue trying on the next timer iteration
    }
  }

  /// Clean up old location data to prevent excessive storage
  Future<void> _cleanupOldLocations(String userId) async {
    try {
      // Get all locations for this user, sorted by timestamp (newest first)
      final query = await _firestore
          .collection('findMeLocations')
          .where('userId', isEqualTo: userId)
          .get();

      if (query.docs.length > 100) {
        // Convert to list and sort by timestamp
        final locations = query.docs.map((doc) {
          final data = doc.data();
          return {
            'doc': doc,
            'timestamp': data['timestamp'],
          };
        }).toList();
        
        // Sort by timestamp (newest first)
        locations.sort((a, b) {
          final aTimestamp = a['timestamp'];
          final bTimestamp = b['timestamp'];
          
          DateTime aTime = DateTime(1970);
          DateTime bTime = DateTime(1970);
          
          if (aTimestamp is Timestamp) {
            aTime = aTimestamp.toDate();
          }
          if (bTimestamp is Timestamp) {
            bTime = bTimestamp.toDate();
          }
          
          return bTime.compareTo(aTime);
        });
        
        // Keep only the newest 100, delete the rest
        if (locations.length > 100) {
          final docsToDelete = locations.sublist(100);
          
          // Delete old documents in batches
          final batch = _firestore.batch();
          for (var item in docsToDelete) {
            final doc = item['doc'] as DocumentSnapshot;
            batch.delete(doc.reference);
          }
          await batch.commit();
          
          print('Cleaned up ${docsToDelete.length} old location records');
        }
      }
    } catch (e) {
      print('Error cleaning up old locations: $e');
    }
  }

  /// Get current location
  Future<Position?> getCurrentLocation() async {
    try {
      // Try high accuracy first
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 20),
      );
    } catch (e) {
      print('High accuracy location failed, trying medium accuracy: $e');
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        );
      } catch (e2) {
        print('Medium accuracy location failed, trying low accuracy: $e2');
        try {
          return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 10),
          );
        } catch (e3) {
          print('All location attempts failed: $e3');
          return null;
        }
      }
    }
  }

  /// Get location history for a user
  Future<List<LocationData>> getLocationHistory(String userId, {int? limit}) async {
    try {
      print('=== GET LOCATION HISTORY DEBUG START ===');
      print('Requested userId: $userId');
      print('Requested limit: $limit');
      
      // Use simpler query without orderBy to avoid index requirement
      Query query = _firestore
          .collection('findMeLocations')
          .where('userId', isEqualTo: userId);
      
      final querySnapshot = await query.get();
      print('Raw query returned ${querySnapshot.docs.length} documents');
      
      if (querySnapshot.docs.isEmpty) {
        print('No location documents found for user: $userId');
        
        // Debug: Let's see what location documents exist in the collection
        print('DEBUG: Checking all location documents...');
        final allDocsQuery = await _firestore.collection('findMeLocations').limit(10).get();
        print('Total location documents in collection: ${allDocsQuery.docs.length}');
        for (var doc in allDocsQuery.docs) {
          final data = doc.data();
          print('  Doc ID: ${doc.id}, UserId: ${data['userId']}, Lat: ${data['latitude']}, Lng: ${data['longitude']}');
        }
        
        return [];
      }
      
      final locations = <LocationData>[];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data() as Map<String, dynamic>?;
          if (data != null) {
            print('Processing location document ${doc.id}:');
            print('  - Document userId: ${data['userId']}');
            print('  - Document latitude: ${data['latitude']}');
            print('  - Document longitude: ${data['longitude']}');
            print('  - Document address: ${data['address']}');
          }
          
          final location = LocationData.fromSnapshot(doc);
          locations.add(location);
          print('  - Successfully parsed location at ${location.timestamp}');
        } catch (e) {
          print('Error parsing location document ${doc.id}: $e');
          print('Document data: ${doc.data()}');
          // Continue with other documents instead of failing completely
        }
      }
      
      // Sort by timestamp in the app (newest first)
      locations.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      // Apply limit after sorting if specified
      if (limit != null && locations.length > limit) {
        locations.removeRange(limit, locations.length);
      }
      
      print('Successfully parsed and sorted ${locations.length} locations out of ${querySnapshot.docs.length} documents');
      if (locations.isNotEmpty) {
        final latest = locations.first;
        print('Latest location: ${latest.latitude}, ${latest.longitude} for userId: ${latest.userId}');
      }
      print('=== GET LOCATION HISTORY DEBUG END ===');
      
      return locations;
    } catch (e) {
      print('Error getting location history for user $userId: $e');
      return [];
    }
  }

  /// Enable FindMe feature for user
  Future<void> enableFindMe(String userId) async {
    // Find user document by userId field
    final userQuery = await _firestore
        .collection('users')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    
    if (userQuery.docs.isNotEmpty) {
      final userDocId = userQuery.docs.first.id;
      await _firestore.collection('users').doc(userDocId).update({
        'findMeEnabled': true,
        'findMeEnabledAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Disable FindMe feature for user
  Future<void> disableFindMe(String userId) async {
    try {
      await stopTracking();
      
      // Find user document by userId field
      final userQuery = await _firestore
          .collection('users')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (userQuery.docs.isNotEmpty) {
        final userDocId = userQuery.docs.first.id;
        await _firestore.collection('users').doc(userDocId).update({
          'findMeEnabled': false,
          'findMeDisabledAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error disabling FindMe: $e');
      rethrow;
    }
  }

  /// Reset location service state
  void resetState() {
    print('SimpleLocationService: Resetting state...');
    _isTracking = false;
    _locationTimer?.cancel();
    _locationTimer = null;
    print('SimpleLocationService: State reset completed');
  }

  /// Check if location services are available
  Future<bool> isLocationServiceReady() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();
      return serviceEnabled && 
             permission != LocationPermission.denied && 
             permission != LocationPermission.deniedForever;
    } catch (e) {
      print('Error checking location service state: $e');
      return false;
    }
  }
}
