import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../core/app_export.dart';
import '../core/network/trusted_contacts_service.dart';
import '../core/network/simple_location_service.dart';
import '../core/services/auto_location_service.dart';
import '../models/location_model.dart';

class FindMeSettingsScreen extends StatefulWidget {
  @override
  _FindMeSettingsScreenState createState() => _FindMeSettingsScreenState();
}

class _FindMeSettingsScreenState extends State<FindMeSettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TrustedContactsService _trustedContactsService = TrustedContactsService();
  final SimpleLocationService _locationService = SimpleLocationService();
  final AutoLocationService _autoLocationService = AutoLocationService();

  bool _findMeEnabled = false;
  bool _isTracking = false;
  bool _loading = true;
  bool _shareWithContacts = true;
  bool _familySharingEnabled = false;
  bool _highAccuracyMode = false;
  List<TrustedContact> _trustedContacts = [];
  bool _isTogglingFindMe = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadTrustedContacts();
    
    // Ensure auto-initialization has completed
    _ensureAutoInitialization();
  }

  Future<void> _ensureAutoInitialization() async {
    // If auto-initialization hasn't been completed, try to do it now
    if (!_autoLocationService.hasInitialized) {
      await _autoLocationService.autoInitializeLocationService();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Find user document by userId field (not by document ID)
        final userQuery = await _firestore
            .collection('users')
            .where('userId', isEqualTo: user.uid)
            .limit(1)
            .get();
        
        if (userQuery.docs.isNotEmpty) {
          final userDoc = userQuery.docs.first;
          final userData = userDoc.data();
          
          setState(() {
            _findMeEnabled = userData['findMeEnabled'] ?? false;
            _isTracking = userData['isTracking'] ?? false;
            _shareWithContacts = userData['shareWithContacts'] ?? true;
            _familySharingEnabled = userData['familySharingEnabled'] ?? false;
            _highAccuracyMode = userData['highAccuracyMode'] ?? false;
            _loading = false;
          });
        } else {
          // No user document found, set defaults
          setState(() {
            _findMeEnabled = false;
            _isTracking = false;
            _shareWithContacts = true;
            _familySharingEnabled = false;
            _highAccuracyMode = false;
            _loading = false;
          });
        }
      } else {
        // No authenticated user
        setState(() {
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _loadTrustedContacts() async {
    final contacts = await _trustedContactsService.getTrustedContacts();
    setState(() {
      _trustedContacts = contacts;
    });
  }

  Future<void> _toggleFindMe(bool value) async {
    // Prevent multiple concurrent toggle operations
    if (_isTogglingFindMe) {
      print('Toggle operation already in progress');
      return;
    }

    try {
      setState(() {
        _isTogglingFindMe = true;
      });

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No authenticated user found');
      }

      // Find user document by userId field
      final userQuery = await _firestore
          .collection('users')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();
      
      DocumentReference userDocRef;
      if (userQuery.docs.isNotEmpty) {
        userDocRef = userQuery.docs.first.reference;
      } else {
        // Create new user document with custom ID format
        final now = DateTime.now();
        final datePart = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
        String emailPrefix = (user.email ?? 'USER').split('@')[0].substring(0, 3).toUpperCase();
        final customDocId = "USER_${datePart}_${emailPrefix}_001"; // Simplified for now
        
        userDocRef = _firestore.collection('users').doc(customDocId);
        await userDocRef.set({
          'userId': user.uid,
          'email': user.email,
          'findMeEnabled': false,
          'isTracking': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (value) {
        // Show consent dialog
        final consent = await _showConsentDialog();
        if (!consent) {
          setState(() {
            _isTogglingFindMe = false;
          });
          return;
        }

        // Show loading dialog
        bool dialogShown = false;
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              content: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 16),
                  Expanded(child: Text('Initializing FindMe...')),
                ],
              ),
            ),
          );
          dialogShown = true;
        }

        try {
          await _locationService.initializeLocationService();
          
          // Enable FindMe feature
          await userDocRef.update({
            'findMeEnabled': true,
            'findMeEnabledAt': FieldValue.serverTimestamp(),
            'shareWithContacts': _shareWithContacts,
            'highAccuracyMode': _highAccuracyMode,
          });

          // Enable FindMe in location service
          await _locationService.enableFindMe(user.uid);
          
          // Start simple location tracking
          bool trackingStarted = false;
          try {
            trackingStarted = await _locationService.startTracking();
            if (trackingStarted) {
              print('Simple location tracking started successfully');
            }
          } catch (e) {
            print('Location tracking failed: $e');
          }

          // Close loading dialog safely
          if (dialogShown && mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
            dialogShown = false;
          }

          if (mounted) {
            setState(() {
              _findMeEnabled = true;
              _isTracking = trackingStarted;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(trackingStarted 
                  ? 'FindMe feature enabled successfully!' 
                  : 'FindMe enabled. Location tracking will start automatically.'),
                backgroundColor: trackingStarted ? Colors.green : Colors.orange,
                duration: Duration(seconds: trackingStarted ? 2 : 3),
              ),
            );
          }
        } catch (e) {
          // Close loading dialog safely
          if (dialogShown && mounted && Navigator.canPop(context)) {
            Navigator.of(context).pop();
          }
          
          // Check if it's a permission/location service error
          String errorMessage = e.toString();
          if (errorMessage.contains('Location services are disabled')) {
            throw Exception('Please enable location services in your device settings to use FindMe.');
          } else if (errorMessage.contains('Location permissions')) {
            throw Exception('Location permissions are required. Please grant location access in app settings.');
          } else if (errorMessage.contains('TimeoutException') || errorMessage.contains('Cannot access location')) {
            // For timeout errors, still enable FindMe but warn about location access
            try {
              // Try to enable FindMe without the location test
              await userDocRef.update({
                'findMeEnabled': true,
                'findMeEnabledAt': FieldValue.serverTimestamp(),
                'shareWithContacts': _shareWithContacts,
                'highAccuracyMode': _highAccuracyMode,
              });

              await _locationService.enableFindMe(user.uid);

              if (mounted) {
                setState(() {
                  _findMeEnabled = true;
                  _isTracking = false;
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('FindMe enabled. Location access may take a moment to initialize.'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 4),
                  ),
                );
              }
              return; // Don't re-throw the error
            } catch (enableError) {
              print('Failed to enable FindMe even without location test: $enableError');
              throw enableError;
            }
          } else {
            throw e; // Re-throw other errors
          }
        }
      } else {
        // Disable FindMe feature
        try {
          // Stop tracking first
          await _locationService.stopTracking();
          
          // Update database
          await userDocRef.update({
            'findMeEnabled': false,
            'findMeDisabledAt': FieldValue.serverTimestamp(),
            'isTracking': false,
            'backgroundTrackingEnabled': false,
          });

          await _locationService.stopTracking();
          await _locationService.disableFindMe(user.uid);

          if (mounted) {
            setState(() {
              _findMeEnabled = false;
              _isTracking = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('FindMe feature disabled')),
            );
          }
        } catch (e) {
          print('Error disabling FindMe: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error disabling FindMe: ${e.toString()}')),
            );
          }
          throw e;
        }
      }
    } catch (e) {
      print('Error toggling FindMe: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating settings: ${e.toString()}')),
        );
        
        // Reset state in case of error
        setState(() {
          _findMeEnabled = false;
          _isTracking = false;
        });
      }
    } finally {
      // Always reset the toggle flag
      if (mounted) {
        setState(() {
          _isTogglingFindMe = false;
        });
      }
    }
  }

  Future<bool> _showConsentDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('FindMe Feature Consent'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'By enabling the FindMe feature, you consent to:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text('• True background location tracking (continues when app is closed)'),
                Text('• Real-time location sharing with family members'),
                Text('• Remote device actions (play sound, etc.)'),
                Text('• Sharing your location with designated trusted contacts'),
                Text('• Storing location data for up to 30 days'),
                Text('• Last known location when device goes offline'),
                SizedBox(height: 12),
                Text(
                  'Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Live location tracking even when app is closed'),
                Text('• Battery-efficient motion-based tracking'),
                Text('• Remote sound alerts and device management'),
                Text('• Battery and network status monitoring'),
                Text('• Offline location history'),
                SizedBox(height: 12),
                Text(
                  'Your location will ONLY be shared when:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Family sharing is enabled and trusted contacts have access'),
                Text('• You explicitly share your location'),
                SizedBox(height: 12),
                Text(
                  'This feature complies with the Data Privacy Act of 2012. You can disable it anytime.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Decline'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('I Consent'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> _updateSetting(String setting, bool value) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Find current user's custom document ID
      final currentUserQuery = await _firestore
          .collection('users')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();
      
      if (currentUserQuery.docs.isEmpty) return;

      final currentUserDocId = currentUserQuery.docs.first.id;

      await _firestore.collection('users').doc(currentUserDocId).update({setting: value});
    } catch (e) {
      print('Error updating setting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating setting')),
      );
    }
  }

  Future<void> _updateContactPermission(String contactId, String permission, bool value) async {
    try {
      // Get current contact index
      final contactIndex = _trustedContacts.indexWhere((c) => c.id == contactId);
      if (contactIndex == -1) return;
      
      // Update permissions - only handle canAccessLocation now
      if (permission == 'canAccessLocation') {
        await _trustedContactsService.updateTrustedContactPermissions(
          contactId, 
          value
        );
        
        // Update local state
        setState(() {
          _trustedContacts[contactIndex] = _trustedContacts[contactIndex].copyWith(canAccessLocation: value);
        });
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Permission updated successfully')),
      );
    } catch (e) {
      print('Error updating contact permission: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating permission')),
      );
    }
  }

  void _viewFamilyLocations() {
    // Navigate to family locations map view
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Family Locations'),
        content: Text('This would show a map with all family members\' real-time locations. Feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _viewFamilyMemberLocation(TrustedContact family) {
    // Navigate to specific family member's location
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${family.name}\'s Location'),
        content: Text('This would show ${family.name}\'s current location on a map. Feature coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _addTrustedContact() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _AddTrustedContactDialog(),
    );

    if (result != null) {
      final success = await _trustedContactsService.addTrustedContact(
        name: result['name']!,
        email: result['email']!,
        phone: result['phone']!,
        relationship: result['relationship']!,
      );

      if (success) {
        _loadTrustedContacts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Trusted contact added successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding trusted contact')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: Text(
            'FindMe Settings',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          backgroundColor: Color(0xFF0D47A1),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0D47A1), Colors.blue.shade100],
              stops: [0.0, 1.0],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
                SizedBox(height: 16),
                Text(
                  'Loading settings...',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'FindMe Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF0D47A1),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D47A1), Colors.blue.shade100],
            stops: [0.0, 1.0],
          ),
        ),
        child: SingleChildScrollView(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main FindMe Feature Card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Colors.blue.shade50],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Color(0xFF0D47A1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.my_location,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'FindMe Feature',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0D47A1),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Location tracking with real-time features similar to Find My Device and Find My iPhone.',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Enable FindMe',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF0D47A1),
                                ),
                              ),
                              Switch(
                                value: _findMeEnabled,
                                onChanged: _isTogglingFindMe ? null : _toggleFindMe,
                                activeColor: Color(0xFF0D47A1),
                                activeTrackColor: Color(0xFF0D47A1).withOpacity(0.3),
                              ),
                            ],
                          ),
                        ),
                        if (_findMeEnabled) ...[
                          SizedBox(height: 16),
                          Divider(color: Colors.blue.shade200),
                          SizedBox(height: 16),
                          Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _isTracking ? Colors.green.shade50 : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _isTracking ? Colors.green.shade200 : Colors.orange.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _isTracking ? Colors.green : Colors.orange,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _isTracking ? Icons.location_on : Icons.location_off,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _isTracking ? 'Real-time tracking active' : 'Real-time tracking inactive',
                                    style: TextStyle(
                                      color: _isTracking ? Colors.green.shade800 : Colors.orange.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Advanced Settings Card
              if (_findMeEnabled) ...[
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.blue.shade50],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color(0xFF0D47A1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.settings,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 16),
                              Text(
                                'Advanced Settings',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0D47A1),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),
                          _buildModernSwitchTile(
                            'Share with Trusted Contacts',
                            'Allow trusted contacts to view your location when family sharing is enabled',
                            _shareWithContacts,
                            (value) {
                              setState(() => _shareWithContacts = value);
                              _updateSetting('shareWithContacts', value);
                            },
                            Icons.contacts,
                          ),
                          SizedBox(height: 16),
                          _buildModernSwitchTile(
                            'High Accuracy Mode',
                            'More precise location but higher battery usage',
                            _highAccuracyMode,
                            (value) {
                              setState(() => _highAccuracyMode = value);
                              _updateSetting('highAccuracyMode', value);
                            },
                            Icons.gps_fixed,
                          ),
                          SizedBox(height: 16),
                          _buildModernSwitchTile(
                            'Family Location Sharing',
                            'Allow family members to see your location continuously',
                            _familySharingEnabled,
                            (value) {
                              setState(() => _familySharingEnabled = value);
                              _updateSetting('familySharingEnabled', value);
                            },
                            Icons.family_restroom,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],

              // Trusted Contacts Card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Colors.blue.shade50],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF0D47A1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.people,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                SizedBox(width: 16),
                                Text(
                                  'Trusted Contacts',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D47A1),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              decoration: BoxDecoration(
                                color: Color(0xFF0D47A1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: _addTrustedContact,
                                icon: Icon(Icons.add, color: Colors.white),
                                tooltip: 'Add Trusted Contact',
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Add family members or friends who can access your location. Grant specific permissions for each contact.',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 20),
                        if (_trustedContacts.isEmpty)
                          Container(
                            padding: EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.person_add, size: 48, color: Colors.grey.shade400),
                                  SizedBox(height: 12),
                                  Text(
                                    'No trusted contacts added yet',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Tap the + button to add your first contact',
                                    style: TextStyle(
                                      color: Colors.grey.shade500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: _trustedContacts.length,
                            itemBuilder: (context, index) {
                              final contact = _trustedContacts[index];
                              return Container(
                                margin: EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.shade200),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 50,
                                            height: 50,
                                            decoration: BoxDecoration(
                                              color: Color(0xFF0D47A1),
                                              borderRadius: BorderRadius.circular(25),
                                            ),
                                            child: Center(
                                              child: Text(
                                                contact.name[0].toUpperCase(),
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  contact.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Color(0xFF0D47A1),
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(
                                                  contact.email,
                                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                                ),
                                                Text(
                                                  '${contact.relationship} • ${contact.phone}',
                                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (contact.isVerified)
                                                Container(
                                                  padding: EdgeInsets.all(6),
                                                  margin: EdgeInsets.only(right: 8),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Icon(Icons.verified, color: Colors.white, size: 16),
                                                ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade100,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: IconButton(
                                                  constraints: BoxConstraints(minWidth: 40, minHeight: 40),
                                                  padding: EdgeInsets.all(8),
                                                  onPressed: () => _removeTrustedContact(contact.id),
                                                  icon: Icon(Icons.delete, color: Colors.red.shade700, size: 20),
                                                  tooltip: 'Remove Contact',
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 12),
                                      Container(
                                        padding: EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.location_on,
                                              size: 16,
                                              color: Color(0xFF0D47A1),
                                            ),
                                            SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                'Location Access',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFF0D47A1),
                                                ),
                                              ),
                                            ),
                                            Switch(
                                              value: contact.canAccessLocation,
                                              onChanged: (value) => _updateContactPermission(contact.id, 'canAccessLocation', value),
                                              activeColor: Color(0xFF0D47A1),
                                              activeTrackColor: Color(0xFF0D47A1).withOpacity(0.3),
                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Family Locations Card (only show when family sharing is enabled)
              if (_familySharingEnabled)
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.white, Colors.green.shade50],
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade600,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.map,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Text(
                                    'Family Locations',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.green.shade600,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  onPressed: _viewFamilyLocations,
                                  icon: Icon(Icons.location_on, color: Colors.white),
                                  tooltip: 'View All Locations',
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            'View real-time location of family members who have granted you access.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 20),
                          
                          // Show family members who granted location access
                          FutureBuilder<List<TrustedContact>>(
                            future: _trustedContactsService.getFamilyMembers(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(20),
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
                                    ),
                                  ),
                                );
                              }
                              
                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Container(
                                  padding: EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.orange.shade200),
                                  ),
                                  child: Center(
                                    child: Column(
                                      children: [
                                        Icon(Icons.family_restroom, size: 48, color: Colors.orange.shade400),
                                        SizedBox(height: 12),
                                        Text(
                                          'No family members are sharing location with you',
                                          style: TextStyle(
                                            color: Colors.orange.shade700,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }
                              
                              return ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) {
                                  final family = snapshot.data![index];
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.green.shade200),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding: EdgeInsets.all(16),
                                      leading: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade600,
                                          borderRadius: BorderRadius.circular(25),
                                        ),
                                        child: Icon(Icons.family_restroom, color: Colors.white),
                                      ),
                                      title: Text(
                                        family.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      subtitle: Text(
                                        '${family.relationship} • Location Sharing Enabled',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                      ),
                                      trailing: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade100,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: IconButton(
                                          onPressed: () => _viewFamilyMemberLocation(family),
                                          icon: Icon(Icons.navigation, color: Colors.green.shade700),
                                          tooltip: 'View Location',
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              if (_familySharingEnabled) SizedBox(height: 20),

              // Privacy Information Card
              Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, Colors.purple.shade50],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.purple.shade600,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.security,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Text(
                              'Privacy & Security',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        _buildPrivacyItem('All location data is encrypted and secured', Icons.lock),
                        _buildPrivacyItem('Background tracking works even when app is closed', Icons.phone_android),
                        _buildPrivacyItem('Motion-based tracking conserves battery life', Icons.battery_charging_full),
                        _buildPrivacyItem('Family sharing provides continuous location access', Icons.family_restroom),
                        _buildPrivacyItem('Individual permissions can be granted per contact', Icons.person_add),
                        _buildPrivacyItem('Location history is kept for maximum 30 days', Icons.history),
                        _buildPrivacyItem('You can disable any feature anytime', Icons.toggle_off),
                        _buildPrivacyItem('Full compliance with Data Privacy Act of 2012', Icons.gavel),
                        
                        SizedBox(height: 16),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFF0D47A1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Color(0xFF0D47A1).withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.star, color: Color(0xFF0D47A1), size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    'Features:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0D47A1),
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              _buildEnhancedFeature('Live location updates every 10 meters', Icons.gps_fixed),
                              _buildEnhancedFeature('Offline location buffering', Icons.cloud_off),
                              _buildEnhancedFeature('Remote sound alerts (even on silent)', Icons.volume_up),
                              _buildEnhancedFeature('Last known location when device is offline', Icons.location_searching),
                              _buildEnhancedFeature('Battery and network status monitoring', Icons.battery_alert),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
      )
    );
  }

  Widget _buildModernSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFF0D47A1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D47A1),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Color(0xFF0D47A1),
            activeTrackColor: Color(0xFF0D47A1).withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyItem(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.purple.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Colors.purple.shade600,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedFeature(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: Color(0xFF0D47A1),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Color(0xFF0D47A1),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _removeTrustedContact(String contactId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Trusted Contact'),
        content: Text('Are you sure you want to remove this trusted contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _trustedContactsService.removeTrustedContact(contactId);
      if (success) {
        _loadTrustedContacts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Trusted contact removed')),
        );
      }
    }
  }
}

class _AddTrustedContactDialog extends StatefulWidget {
  @override
  _AddTrustedContactDialogState createState() => _AddTrustedContactDialogState();
}

class _AddTrustedContactDialogState extends State<_AddTrustedContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  String _selectedRelationship = 'Family';

  final List<String> _relationships = [
    'Family',
    'Spouse',
    'Parent',
    'Child',
    'Sibling',
    'Friend',
    'Guardian',
    'Other'
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Add Trusted Contact'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Full Name'),
                validator: (value) => value?.isEmpty == true ? 'Required' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Required';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value!)) {
                    return 'Invalid email';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Phone Number'),
                keyboardType: TextInputType.phone,
                validator: (value) => value?.isEmpty == true ? 'Required' : null,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedRelationship,
                decoration: InputDecoration(labelText: 'Relationship'),
                items: _relationships.map((relationship) {
                  return DropdownMenuItem(
                    value: relationship,
                    child: Text(relationship),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedRelationship = value!);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text,
                'email': _emailController.text,
                'phone': _phoneController.text,
                'relationship': _selectedRelationship,
              });
            }
          },
          child: Text('Add'),
        ),
      ],
    );
  }
}
