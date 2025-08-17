import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../network/simple_location_service.dart';
import 'background_location_service.dart';

/// Service to automatically initialize and start location tracking
/// when the app launches if Find Me is already enabled for the user
class AutoLocationService {
  static final AutoLocationService _instance = AutoLocationService._internal();
  factory AutoLocationService() => _instance;
  AutoLocationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SimpleLocationService _locationService = SimpleLocationService();
  final BackgroundLocationService _backgroundLocationService = BackgroundLocationService();

  bool _hasInitialized = false;

  /// Initialize location service automatically if Find Me is enabled
  /// This should be called when the app starts and user is authenticated
  Future<void> autoInitializeLocationService() async {
    try {
      // Prevent multiple initialization attempts
      if (_hasInitialized) {
        print('AutoLocationService already initialized');
        return;
      }

      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user - skipping auto location initialization');
        return;
      }

      print('AutoLocationService: Checking if Find Me is enabled for user ${user.uid}');

      // Find user document by userId field
      final userQuery = await _firestore
          .collection('users')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();
      
      if (userQuery.docs.isEmpty) {
        print('AutoLocationService: User document not found');
        return;
      }

      final userData = userQuery.docs.first.data();
      final findMeEnabled = userData['findMeEnabled'] ?? false;
      final isCurrentlyTracking = userData['isTracking'] ?? false;
      final locationService = _locationService;

      print('AutoLocationService: FindMe enabled: $findMeEnabled, Currently tracking: $isCurrentlyTracking, Service tracking: ${locationService.isTracking}');

      if (findMeEnabled) {
        // Initialize both location services
        await locationService.initializeLocationService();
        await _backgroundLocationService.initializeBackgroundLocationService();
        
        // Check if we need to start or restart tracking
        if (!locationService.isTracking && !_backgroundLocationService.isTracking) {
          print('AutoLocationService: Location service not tracking - starting background location tracking');
          
          // Reset state first to ensure clean start
          locationService.resetState();
          _backgroundLocationService.resetState();
          
          // Try to start background location tracking (preferred)
          try {
            final backgroundTrackingStarted = await _backgroundLocationService.startBackgroundTracking();
            if (backgroundTrackingStarted) {
              print('AutoLocationService: Background location tracking started successfully');
              
              // Update database to reflect current tracking state
              await userQuery.docs.first.reference.update({
                'isTracking': true,
                'backgroundTrackingEnabled': true,
                'trackingStartedAt': FieldValue.serverTimestamp(),
                'autoInitializedAt': FieldValue.serverTimestamp(),
              });
            } else {
              print('AutoLocationService: Background tracking failed, trying simple tracking');
              // Fallback to simple tracking
              final trackingStarted = await locationService.startTracking();
              if (trackingStarted) {
                print('AutoLocationService: Simple location tracking started successfully');
                
                await userQuery.docs.first.reference.update({
                  'isTracking': true,
                  'backgroundTrackingEnabled': false,
                  'trackingStartedAt': FieldValue.serverTimestamp(),
                  'autoInitializedAt': FieldValue.serverTimestamp(),
                });
              } else {
                print('AutoLocationService: Failed to start any location tracking');
              }
            }
          } catch (e) {
            print('AutoLocationService: Error starting background location tracking: $e');
            // Fallback to simple tracking
            try {
              final trackingStarted = await locationService.startTracking();
              if (trackingStarted) {
                print('AutoLocationService: Fallback to simple location tracking successful');
              }
            } catch (fallbackError) {
              print('AutoLocationService: Fallback tracking also failed: $fallbackError');
            }
          }
        } else {
          print('AutoLocationService: Location service already tracking');
          // Ensure database is in sync
          if (!isCurrentlyTracking) {
            await userQuery.docs.first.reference.update({
              'isTracking': true,
              'trackingStartedAt': FieldValue.serverTimestamp(),
              'autoResumedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      } else {
        print('AutoLocationService: FindMe not enabled - skipping location initialization');
      }

      _hasInitialized = true;
    } catch (e) {
      print('AutoLocationService: Error during auto initialization: $e');
      // Don't throw error - app should continue to work
    }
  }

  /// Reset the initialization state
  /// Call this when user logs out
  void reset() {
    _hasInitialized = false;
    // Also reset both location services state
    _locationService.resetState();
    _backgroundLocationService.resetState();
    print('AutoLocationService: Reset initialization state');
  }

  /// Force re-initialization even if already initialized
  /// This can be used when the user manually toggles Find Me
  Future<void> forceReinitialization() async {
    print('AutoLocationService: Forcing re-initialization...');
    _hasInitialized = false;
    await autoInitializeLocationService();
  }

  /// Check if auto initialization has completed
  bool get hasInitialized => _hasInitialized;
}
