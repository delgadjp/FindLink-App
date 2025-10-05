import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

/// Global notification manager that handles all notifications independently of UI screens
/// This ensures notifications work from any screen or when the app is in the background
class GlobalNotificationManager {
  GlobalNotificationManager._internal();

  static final GlobalNotificationManager _instance = GlobalNotificationManager._internal();

  factory GlobalNotificationManager() => _instance;

  static GlobalNotificationManager get instance => _instance;

  bool _initialized = false;
  Map<String, dynamic>? _userData;
  List<StreamSubscription<QuerySnapshot>> _streamSubscriptions = [];
  Map<String, String> _previousCaseStatuses = {};
  Set<String> _notifiedLiftingFormIds = {};
  bool _hasLoadedInitialData = false;
  
  Timer? _initializationTimer;

  Future<void> initialize() async {
    if (_initialized) return;

    // Listen for auth state changes
    FirebaseAuth.instance.authStateChanges().listen(_onAuthStateChanged);
    
    _initialized = true;
    debugPrint('GlobalNotificationManager initialized');
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user != null) {
      // User logged in - start monitoring
      await _startNotificationMonitoring();
    } else {
      // User logged out - cleanup
      await _cleanup();
    }
  }

  Future<void> _startNotificationMonitoring() async {
    // Cancel any existing timer
    _initializationTimer?.cancel();
    
    // Small delay to ensure user data is available
    _initializationTimer = Timer(const Duration(seconds: 2), () async {
      await _fetchUserData();
      await _loadNotifiedLiftingFormIds();
      await _initializeStreams();
      _hasLoadedInitialData = true;
    });
  }

  Future<void> _fetchUserData() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Try to find user document by userId first
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('userId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        // Fallback: try to find by email
        userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: currentUser.email)
            .limit(1)
            .get();
      }

      if (userQuery.docs.isNotEmpty) {
        _userData = userQuery.docs.first.data() as Map<String, dynamic>;
        debugPrint('GlobalNotificationManager: User data loaded for ${_userData!['firstName'] ?? 'Unknown'}');
      } else {
        // Create basic user data from Firebase Auth
        _userData = {
          'firstName': currentUser.displayName?.split(' ')[0] ?? 'User',
          'lastName': currentUser.displayName?.split(' ').skip(1).join(' ') ?? '',
          'email': currentUser.email ?? '',
          'userId': currentUser.uid,
        };
        debugPrint('GlobalNotificationManager: Using Firebase Auth data');
      }
    } catch (e) {
      debugPrint('GlobalNotificationManager: Error fetching user data: $e');
    }
  }

  Future<void> _loadNotifiedLiftingFormIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? notifiedIds = prefs.getStringList('notified_lifting_form_ids');
      if (notifiedIds != null) {
        _notifiedLiftingFormIds = notifiedIds.toSet();
      }
    } catch (e) {
      debugPrint('GlobalNotificationManager: Error loading notified lifting form IDs: $e');
    }
  }

  Future<void> _saveNotifiedLiftingFormIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('notified_lifting_form_ids', _notifiedLiftingFormIds.toList());
    } catch (e) {
      debugPrint('GlobalNotificationManager: Error saving notified lifting form IDs: $e');
    }
  }

  Future<void> _initializeStreams() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null || _userData == null) return;

    // Clear existing subscriptions
    await _cleanup();

    debugPrint('GlobalNotificationManager: Initializing streams for user ${currentUser.uid}');

    // Stream from incidents collection
    final incidentsStream = FirebaseFirestore.instance
        .collection('incidents')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots();

    // Stream from missingPersons collection
    final missingPersonsStream = FirebaseFirestore.instance
        .collection('missingPersons')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots();

    // Stream from archivedCases collection
    final archivedCasesStream = FirebaseFirestore.instance
        .collection('archivedCases')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots();

    // Setup lifting form stream
    final String? firstName = _userData!['firstName'] ?? _userData!['displayName']?.split(' ')[0];
    final String? middleName = _userData!['middleName'];
    final String? lastName = _userData!['lastName'] ?? _userData!['familyName'];

    if (firstName != null) {
      final String fullName = [firstName, middleName, lastName]
          .where((name) => name != null && name.isNotEmpty)
          .join(' ');

      final liftingFormStream = FirebaseFirestore.instance
          .collection('liftingform')
          .where('reporterName', isEqualTo: fullName)
          .snapshots();

      _streamSubscriptions.add(liftingFormStream.listen(_onLiftingFormUpdate));
    }

    // Add stream subscriptions
    _streamSubscriptions.add(incidentsStream.listen(_onCaseUpdate));
    _streamSubscriptions.add(missingPersonsStream.listen(_onCaseUpdate));
    _streamSubscriptions.add(archivedCasesStream.listen(_onCaseUpdate));

    debugPrint('GlobalNotificationManager: ${_streamSubscriptions.length} streams initialized');
  }

  void _onCaseUpdate(QuerySnapshot snapshot) async {
    if (!_hasLoadedInitialData) return;
    
    try {
      final Map<String, String> newStatuses = Map<String, String>.from(_previousCaseStatuses);
      final List<Map<String, String>> progressedCases = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final caseId = doc.id;
        final currentStatus = data['status'] ?? 'Reported';
        final previousStatus = _previousCaseStatuses[caseId];

        newStatuses[caseId] = currentStatus;

        if (previousStatus != null && previousStatus != currentStatus) {
          // Status changed - prepare notification
          final caseNumber = data['caseNumber'] ?? data['id'] ?? caseId;
          final caseName = _extractCaseName(data);
          
          progressedCases.add({
            'caseId': caseId,
            'caseNumber': caseNumber,
            'caseName': caseName,
            'previousStatus': previousStatus,
            'currentStatus': currentStatus,
          });
        }
      }

      _previousCaseStatuses = newStatuses;

      // Send notifications for progressed cases
      for (final caseInfo in progressedCases) {
        if (caseInfo['currentStatus'] == 'Resolved' || caseInfo['currentStatus'] == 'Resolved Case') {
          await NotificationService().showCaseResolvedNotification(
            caseId: caseInfo['caseId']!,
            caseNumber: caseInfo['caseNumber']!,
            caseName: caseInfo['caseName'],
          );
        } else {
          await NotificationService().showCaseStatusNotification(
            caseId: caseInfo['caseId']!,
            caseNumber: caseInfo['caseNumber']!,
            status: caseInfo['currentStatus']!,
            caseName: caseInfo['caseName'],
          );
        }
        debugPrint('GlobalNotificationManager: Sent notification for case ${caseInfo['caseNumber']} - ${caseInfo['currentStatus']}');
      }
    } catch (e) {
      debugPrint('GlobalNotificationManager: Error handling case update: $e');
    }
  }

  void _onLiftingFormUpdate(QuerySnapshot snapshot) async {
    if (!_hasLoadedInitialData) return;

    try {
      final List<Map<String, dynamic>> newForms = [];

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final formId = doc.id;

        if (!_notifiedLiftingFormIds.contains(formId)) {
          newForms.add({
            'id': formId,
            'reporterName': data['reporterName'] ?? 'Unknown Reporter',
            'location': data['location'] ?? '',
            'subject': data['subject'] ?? '',
            'data': data,
          });
          _notifiedLiftingFormIds.add(formId);
        }
      }

      if (newForms.isNotEmpty) {
        // Send notifications for new lifting forms
        for (final form in newForms) {
          await NotificationService().showNewLiftingFormNotification(
            liftingFormId: form['id'],
            reporterName: form['reporterName'],
            location: form['location'],
            subject: form['subject'],
          );
          debugPrint('GlobalNotificationManager: Sent notification for new lifting form from ${form['reporterName']}');
        }

        await _saveNotifiedLiftingFormIds();
      }
    } catch (e) {
      debugPrint('GlobalNotificationManager: Error handling lifting form update: $e');
    }
  }

  String _extractCaseName(Map<String, dynamic> data) {
    if (data['itemC'] != null) {
      final itemC = data['itemC'];
      return ((itemC['firstName'] ?? '') +
              ' ' +
              (itemC['middleName'] ?? '') +
              ' ' +
              (itemC['lastName'] ?? ''))
          .trim();
    } else if (data['name'] != null) {
      return data['name'];
    } else {
      return 'Unknown Case';
    }
  }

  Future<void> _cleanup() async {
    for (var subscription in _streamSubscriptions) {
      await subscription.cancel();
    }
    _streamSubscriptions.clear();
    _initializationTimer?.cancel();
    debugPrint('GlobalNotificationManager: Cleaned up streams');
  }

  Future<void> dispose() async {
    await _cleanup();
    _initialized = false;
    _userData = null;
    _previousCaseStatuses.clear();
    _notifiedLiftingFormIds.clear();
    _hasLoadedInitialData = false;
  }

  // Public method to manually refresh streams (useful after login)
  Future<void> refreshStreams() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && _initialized) {
      await _startNotificationMonitoring();
    }
  }
}