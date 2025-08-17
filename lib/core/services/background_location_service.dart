import 'dart:async';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';
import '../app_export.dart';

/// Background Location Service using flutter_background_geolocation
/// Provides true background location tracking that continues when app is closed
class BackgroundLocationService {
  static final BackgroundLocationService _instance = BackgroundLocationService._internal();
  factory BackgroundLocationService() => _instance;
  BackgroundLocationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = Uuid();

  bool _isInitialized = false;
  bool _isTracking = false;

  bool get isTracking => _isTracking;
  bool get isInitialized => _isInitialized;

  /// Initialize the background location service
  Future<void> initializeBackgroundLocationService() async {
    if (_isInitialized) {
      print('BackgroundLocationService already initialized');
      return;
    }

    try {
      print('Initializing BackgroundLocationService...');

      // Configure the background geolocation plugin
      await bg.BackgroundGeolocation.ready(bg.Config(
        // Geolocation Options
        desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
        distanceFilter: 10.0, // meters
        
        // Activity Recognition Options
        stopTimeout: 1, // minutes
        
        // Application Options  
        debug: false, // Set to true for debugging
        logLevel: bg.Config.LOG_LEVEL_OFF,
        enableHeadless: true,
        
        // HTTP / Persistence Options
        autoSync: false, // We'll handle sync manually to Firebase
        maxRecordsToPersist: 100,
        
        // Location Authorization
        locationAuthorizationRequest: 'Always',
        backgroundPermissionRationale: bg.PermissionRationale(
          title: "Allow FindMe to access this device's location in the background?",
          message: "In order to track your location for safety purposes, please enable 'Allow all the time' location permission",
          positiveAction: 'Change to "Allow all the time"',
          negativeAction: 'Cancel',
        ),
        
        // iOS Options
        showsBackgroundLocationIndicator: false,
        
        // Android Options
        foregroundService: true,
        notification: bg.Notification(
          title: "FindMe Location Tracking",
          text: "Location tracking is active for your safety",
          color: "#FF5722",
          channelName: "Location Tracking",
          smallIcon: "drawable/ic_launcher",
          largeIcon: "drawable/ic_launcher",
        ),
      ));

      // Listen to location events
      bg.BackgroundGeolocation.onLocation(_onLocationChanged);
      
      // Listen to motion change events
      bg.BackgroundGeolocation.onMotionChange(_onMotionChange);
      
      // Listen to provider change events  
      bg.BackgroundGeolocation.onProviderChange(_onProviderChange);

      _isInitialized = true;
      print('BackgroundLocationService initialized successfully');
    } catch (e) {
      print('Error initializing BackgroundLocationService: $e');
      rethrow;
    }
  }

  /// Start background location tracking
  Future<bool> startBackgroundTracking() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found');
        return false;
      }

      if (!_isInitialized) {
        await initializeBackgroundLocationService();
      }

      if (_isTracking) {
        print('Background location tracking is already active');
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

      print('Starting background location tracking...');

      // Start the background geolocation plugin
      await bg.BackgroundGeolocation.start();
      _isTracking = true;
      
      // Update user's tracking status
      await userDoc.reference.update({
        'isTracking': true,
        'backgroundTrackingEnabled': true,
        'trackingStartedAt': FieldValue.serverTimestamp(),
      });

      print('Background location tracking started successfully');
      return true;
    } catch (e) {
      print('Error starting background location tracking: $e');
      _isTracking = false;
      return false;
    }
  }

  /// Stop background location tracking
  Future<void> stopBackgroundTracking() async {
    try {
      if (!_isTracking) {
        print('Background location tracking is not active');
        return;
      }

      print('Stopping background location tracking...');
      
      // Stop the background geolocation plugin
      await bg.BackgroundGeolocation.stop();
      _isTracking = false;

      final user = _auth.currentUser;
      if (user != null) {
        // Update user's tracking status
        final userQuery = await _firestore
            .collection('users')
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();
        
        if (userQuery.docs.isNotEmpty) {
          await userQuery.docs.first.reference.update({
            'isTracking': false,
            'backgroundTrackingEnabled': false,
            'trackingStoppedAt': FieldValue.serverTimestamp(),
          });
        }
      }
      
      print('Background location tracking stopped');
    } catch (e) {
      print('Error stopping background location tracking: $e');
      _isTracking = false;
      rethrow;
    }
  }

  /// Handle location changes
  void _onLocationChanged(bg.Location location) {
    print('Background location received: ${location.coords.latitude}, ${location.coords.longitude}');
    _saveLocationToFirebase(location);
  }

  /// Handle motion changes
  void _onMotionChange(bg.Location location) {
    print('Motion change detected at: ${location.coords.latitude}, ${location.coords.longitude}');
    print('Is moving: ${location.isMoving}');
  }

  /// Handle provider changes
  void _onProviderChange(bg.ProviderChangeEvent event) {
    print('Provider change: ${event.status}');
    if (!event.enabled) {
      print('Location services have been disabled');
    }
  }

  /// Save location data to Firebase
  Future<void> _saveLocationToFirebase(bg.Location location) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user - cannot save location');
        return;
      }

      // Get address from coordinates
      String? address;
      try {
        final placemarks = await placemarkFromCoordinates(
          location.coords.latitude,
          location.coords.longitude,
        );
        if (placemarks.isNotEmpty) {
          final placemark = placemarks.first;
          address = '${placemark.street ?? ''}, ${placemark.locality ?? ''}, ${placemark.country ?? ''}';
        }
      } catch (e) {
        print('Error getting address: $e');
      }

      // Generate location document ID
      final locationDocId = await _generateLocationDocumentId(user.uid);
      
      // Create location data
      final locationData = LocationData(
        id: locationDocId,
        userId: user.uid,
        latitude: location.coords.latitude,
        longitude: location.coords.longitude,
        accuracy: location.coords.accuracy,
        timestamp: DateTime.fromMillisecondsSinceEpoch(int.tryParse(location.timestamp) ?? DateTime.now().millisecondsSinceEpoch),
        address: address,
      );

      print('Saving background location for user ${user.uid}');

      // Save to findMeLocations collection
      await _firestore
          .collection('findMeLocations')
          .doc(locationDocId)
          .set(locationData.toMap());

      // Also update the user's lastKnownLocation field
      final userQuery = await _firestore
          .collection('users')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        await userQuery.docs.first.reference.update({
          'lastKnownLocation': {
            'latitude': location.coords.latitude,
            'longitude': location.coords.longitude,
            'accuracy': location.coords.accuracy,
            'timestamp': FieldValue.serverTimestamp(),
            'address': address,
          },
          'lastLocationUpdate': FieldValue.serverTimestamp(),
        });
      }

      // Cleanup old locations
      await _cleanupOldLocations(user.uid);
      
      print('Background location saved successfully');
    } catch (e) {
      print('Error saving background location: $e');
    }
  }

  /// Generate location document ID
  Future<String> _generateLocationDocumentId(String userId) async {
    try {
      // Find the user document to get their custom document ID format
      final userQuery = await _firestore
          .collection('users')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        final userDocumentId = userData['documentId'] ?? 'USR_001';
        
        // Extract prefix (e.g., "USR_001" -> "001")
        final userIdParts = userDocumentId.split('_');
        final userPrefix = userIdParts.length > 1 ? userIdParts[1] : '001';
        
        // Create location document ID: LOC_YYYYMMDD_XXX_HHMMSS
        final now = DateTime.now();
        final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';
        final timeStr = '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';
        
        return 'LOC_${dateStr}_${userPrefix}_$timeStr';
      }
    } catch (e) {
      print('Error generating location document ID: $e');
    }
    
    // Fallback to UUID
    return _uuid.v4();
  }

  /// Clean up old location data
  Future<void> _cleanupOldLocations(String userId) async {
    try {
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
          final timestampA = a['timestamp'] as Timestamp?;
          final timestampB = b['timestamp'] as Timestamp?;
          if (timestampA == null || timestampB == null) return 0;
          return timestampB.compareTo(timestampA);
        });

        // Delete old locations (keep only 100 most recent)
        final locationsToDelete = locations.skip(100);
        final batch = _firestore.batch();
        
        for (final locationData in locationsToDelete) {
          final doc = locationData['doc'] as QueryDocumentSnapshot;
          batch.delete(doc.reference);
        }
        
        await batch.commit();
        print('Cleaned up ${locationsToDelete.length} old locations');
      }
    } catch (e) {
      print('Error cleaning up old locations: $e');
    }
  }

  /// Enable FindMe feature with background tracking
  Future<void> enableFindMeBackground(String userId) async {
    // Find user document by userId field
    final userQuery = await _firestore
        .collection('users')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    
    if (userQuery.docs.isNotEmpty) {
      await userQuery.docs.first.reference.update({
        'findMeEnabled': true,
        'backgroundTrackingEnabled': true,
        'findMeEnabledAt': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Disable FindMe feature
  Future<void> disableFindMeBackground(String userId) async {
    try {
      await stopBackgroundTracking();
      
      // Find user document by userId field
      final userQuery = await _firestore
          .collection('users')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();
      
      if (userQuery.docs.isNotEmpty) {
        await userQuery.docs.first.reference.update({
          'findMeEnabled': false,
          'backgroundTrackingEnabled': false,
          'findMeDisabledAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error disabling FindMe background: $e');
      rethrow;
    }
  }

  /// Reset service state
  void resetState() {
    print('BackgroundLocationService: Resetting state...');
    _isTracking = false;
  }

  /// Get current location state
  Future<Map<String, dynamic>> getLocationState() async {
    try {
      final state = await bg.BackgroundGeolocation.state;
      return {
        'enabled': state.enabled,
        'isMoving': state.isMoving,
        'trackingMode': state.trackingMode,
        'odometer': state.odometer,
      };
    } catch (e) {
      print('Error getting location state: $e');
      return {};
    }
  }

  /// Dispose resources
  void dispose() {
    bg.BackgroundGeolocation.removeListeners();
  }
}
