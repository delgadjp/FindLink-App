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

      // Check if user has enabled FindMe feature
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      
      if (userData == null || userData['findMeEnabled'] != true) {
        print('FindMe feature not enabled for user');
        return false;
      }

      print('Starting simple location tracking...');
      _isTracking = true;
      
      // Update user's tracking status
      await _firestore.collection('users').doc(user.uid).update({
        'isTracking': true,
        'trackingStartedAt': FieldValue.serverTimestamp(),
      });

      // Start periodic location updates every 30 seconds
      _locationTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
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
        await _firestore.collection('users').doc(user.uid).update({
          'isTracking': false,
          'trackingStoppedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error stopping location tracking: $e');
      // Still set tracking to false even if stop failed
      _isTracking = false;
      rethrow;
    }
  }

  /// Update current location
  Future<void> _updateLocation() async {
    try {
      final user = _auth.currentUser;
      if (user == null || !_isTracking) return;

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

      // Create location data
      final locationData = LocationData(
        id: _uuid.v4(),
        userId: user.uid,
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        timestamp: DateTime.now(),
        address: address,
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('locations')
          .doc(locationData.id)
          .set(locationData.toMap());

      // Keep only last 100 locations (cleanup old data)
      await _cleanupOldLocations(user.uid);
      
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
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('locations')
          .orderBy('timestamp', descending: true)
          .limit(101) // Get 101 to identify the 101st item
          .get();

      if (query.docs.length > 100) {
        // Delete documents older than the 100th most recent
        final cutoffTimestamp = query.docs[99].data()['timestamp'];
        
        final oldDocs = await _firestore
            .collection('users')
            .doc(userId)
            .collection('locations')
            .where('timestamp', isLessThan: cutoffTimestamp)
            .get();

        // Delete old documents in batches
        final batch = _firestore.batch();
        for (var doc in oldDocs.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
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
      print('Getting location history for user: $userId with limit: $limit');
      
      Query query = _firestore
          .collection('users')
          .doc(userId)
          .collection('locations')
          .orderBy('timestamp', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final querySnapshot = await query.get();
      print('Location history query returned ${querySnapshot.docs.length} documents');
      
      if (querySnapshot.docs.isEmpty) {
        print('No location documents found for user: $userId');
        return [];
      }
      
      final locations = <LocationData>[];
      for (var doc in querySnapshot.docs) {
        try {
          final location = LocationData.fromSnapshot(doc);
          locations.add(location);
          print('Successfully parsed location: ${location.latitude}, ${location.longitude} at ${location.timestamp}');
        } catch (e) {
          print('Error parsing location document ${doc.id}: $e');
          print('Document data: ${doc.data()}');
          // Continue with other documents instead of failing completely
        }
      }
      
      print('Successfully parsed ${locations.length} locations out of ${querySnapshot.docs.length} documents');
      return locations;
    } catch (e) {
      print('Error getting location history for user $userId: $e');
      return [];
    }
  }

  /// Enable FindMe feature for user
  Future<void> enableFindMe(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'findMeEnabled': true,
      'findMeEnabledAt': FieldValue.serverTimestamp(),
    });
  }

  /// Disable FindMe feature for user
  Future<void> disableFindMe(String userId) async {
    try {
      await stopTracking();
      await _firestore.collection('users').doc(userId).update({
        'findMeEnabled': false,
        'findMeDisabledAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error disabling FindMe: $e');
      rethrow;
    }
  }

  /// Reset location service state
  void resetState() {
    _isTracking = false;
    _locationTimer?.cancel();
    _locationTimer = null;
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
