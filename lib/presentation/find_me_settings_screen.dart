import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import '../core/app_export.dart';
import '../core/network/trusted_contacts_service.dart';
import '../core/network/simple_location_service.dart';
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

  bool _findMeEnabled = false;
  bool _isTracking = false;
  bool _loading = true;
  bool _allowRemoteActions = true;
  bool _shareWithContacts = true;
  bool _familySharingEnabled = false;
  bool _highAccuracyMode = false;
  String _deviceStatus = 'Online';
  LocationData? _lastKnownLocation;
  List<TrustedContact> _trustedContacts = [];
  bool _isTogglingFindMe = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadTrustedContacts();
    _loadDeviceStatus();
    _loadLastKnownLocation();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Use document ID directly instead of querying by userId field
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          
          setState(() {
            _findMeEnabled = userData['findMeEnabled'] ?? false;
            _isTracking = userData['isTracking'] ?? false;
            _allowRemoteActions = userData['allowRemoteActions'] ?? true;
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
            _allowRemoteActions = true;
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

  Future<void> _loadDeviceStatus() async {
    try {
      // Simulate device status check
      setState(() {
        _deviceStatus = _isTracking ? 'Online - Tracking Active' : 'Online - Tracking Inactive';
      });
    } catch (e) {
      setState(() {
        _deviceStatus = 'Status Unknown';
      });
    }
  }

  Future<void> _loadLastKnownLocation() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final locations = await _locationService.getLocationHistory(user.uid, limit: 1);
      if (locations.isNotEmpty) {
        setState(() {
          _lastKnownLocation = locations.first;
        });
      }
    } catch (e) {
      print('Error loading last known location: $e');
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

      // Query users collection by userId field to get the document reference
      final userDocRef = _firestore.collection('users').doc(user.uid);
      
      // Check if document exists, create if it doesn't
      final userDoc = await userDocRef.get();
      if (!userDoc.exists) {
        // Create user document with basic data
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
            'allowRemoteActions': _allowRemoteActions,
            'shareWithContacts': _shareWithContacts,
            'highAccuracyMode': _highAccuracyMode,
          });

          // Enable FindMe in service
          await _locationService.enableFindMe(user.uid);
          
          // Try to start location tracking (non-blocking)
          bool trackingStarted = false;
          try {
            trackingStarted = await _locationService.startTracking();
          } catch (e) {
            print('Warning: Could not start location tracking immediately: $e');
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
              _deviceStatus = trackingStarted ? 'Online - Tracking Active' : 'Online - Tracking Setup';
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
                'allowRemoteActions': _allowRemoteActions,
                'shareWithContacts': _shareWithContacts,
                'highAccuracyMode': _highAccuracyMode,
              });

              await _locationService.enableFindMe(user.uid);

              if (mounted) {
                setState(() {
                  _findMeEnabled = true;
                  _isTracking = false;
                  _deviceStatus = 'Online - Location Pending';
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
          });

          await _locationService.disableFindMe(user.uid);

          if (mounted) {
            setState(() {
              _findMeEnabled = false;
              _isTracking = false;
              _deviceStatus = 'Online - Tracking Inactive';
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
          _deviceStatus = 'Online - Tracking Inactive';
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
          title: Text('Enhanced FindMe Feature Consent'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'By enabling the Enhanced FindMe feature, you consent to:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text('• Continuous background location tracking'),
                Text('• Real-time location sharing with family members'),
                Text('• Remote device actions (play sound, etc.)'),
                Text('• Sharing your location with designated trusted contacts'),
                Text('• Storing location data for up to 30 days'),
                Text('• Last known location when device goes offline'),
                SizedBox(height: 12),
                Text(
                  'Enhanced Features:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• Live location tracking similar to Find My Device'),
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

      // Use document ID directly
      await _firestore.collection('users').doc(user.uid).update({setting: value});
    } catch (e) {
      print('Error updating setting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating setting')),
      );
    }
  }

  Future<void> _updateContactPermission(String contactId, String permission, bool value) async {
    try {
      // Get current contact to preserve other permissions
      final contactIndex = _trustedContacts.indexWhere((c) => c.id == contactId);
      if (contactIndex == -1) return;
      
      final contact = _trustedContacts[contactIndex];
      
      // Update permissions while preserving the other one
      bool newCanAccessLocation = contact.canAccessLocation;
      bool newCanPerformRemoteActions = contact.canPerformRemoteActions;
      
      if (permission == 'canAccessLocation') {
        newCanAccessLocation = value;
      } else if (permission == 'canPerformRemoteActions') {
        newCanPerformRemoteActions = value;
      }
      
      await _trustedContactsService.updateTrustedContactPermissions(
        contactId, 
        newCanAccessLocation, 
        newCanPerformRemoteActions
      );
      
      // Update local state
      setState(() {
        if (permission == 'canAccessLocation') {
          _trustedContacts[contactIndex] = _trustedContacts[contactIndex].copyWith(canAccessLocation: value);
        } else if (permission == 'canPerformRemoteActions') {
          _trustedContacts[contactIndex] = _trustedContacts[contactIndex].copyWith(canPerformRemoteActions: value);
        }
      });
      
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

  Future<void> _playDeviceSound() async {
    try {
      // In a real implementation, this would trigger a remote sound
      // For now, show a dialog simulating the action
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Device Sound'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.volume_up, size: 64, color: Colors.blue),
              SizedBox(height: 16),
              Text('Playing loud sound on your device...'),
              SizedBox(height: 8),
              Text('This will help you locate your device even if it\'s on silent mode.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Stop Sound'),
            ),
          ],
        ),
      );

      // Simulate sound for 5 seconds
      await Future.delayed(Duration(seconds: 5));
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      print('Error playing device sound: $e');
    }
  }

  void _shareCurrentLocation() {
    if (_lastKnownLocation != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Share Current Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Last Known Location:'),
              SizedBox(height: 8),
              Text('Lat: ${_lastKnownLocation!.latitude.toStringAsFixed(6)}'),
              Text('Lng: ${_lastKnownLocation!.longitude.toStringAsFixed(6)}'),
              if (_lastKnownLocation!.address != null) ...[
                SizedBox(height: 8),
                Text('Address: ${_lastKnownLocation!.address}'),
              ],
              SizedBox(height: 8),
              Text('Updated: ${_formatDateTime(_lastKnownLocation!.timestamp)}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // In a real implementation, this would share the location
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Location shared with trusted contacts')),
                );
              },
              child: Text('Share'),
            ),
          ],
        ),
      );
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
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
        appBar: AppBar(title: Text('Enhanced FindMe Settings')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Enhanced FindMe Settings'),
        backgroundColor: Color.fromARGB(255, 18, 32, 47),
        actions: [
          if (_findMeEnabled && _lastKnownLocation != null)
            IconButton(
              icon: Icon(Icons.share_location),
              onPressed: _shareCurrentLocation,
              tooltip: 'Share Current Location',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Device Status Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isTracking ? Icons.devices : Icons.devices_other,
                          color: _isTracking ? Colors.green : Colors.grey,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Device Status',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(_deviceStatus),
                    if (_lastKnownLocation != null) ...[
                      SizedBox(height: 8),
                      Text(
                        'Last seen: ${_formatDateTime(_lastKnownLocation!.timestamp)}',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (_lastKnownLocation!.address != null)
                        Text(
                          'Location: ${_lastKnownLocation!.address}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                    ],
                    if (_findMeEnabled) ...[
                      SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _playDeviceSound,
                              icon: Icon(Icons.volume_up),
                              label: Text('Play Sound'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _shareCurrentLocation,
                              icon: Icon(Icons.share_location),
                              label: Text('Share Location'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            
            // Main FindMe Feature Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enhanced FindMe Feature',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Enhanced location tracking with real-time features similar to Find My Device and Find My iPhone.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Enable Enhanced FindMe'),
                        Switch(
                          value: _findMeEnabled,
                          onChanged: _isTogglingFindMe ? null : _toggleFindMe,
                        ),
                      ],
                    ),
                    if (_findMeEnabled) ...[
                      Divider(),
                      Row(
                        children: [
                          Icon(
                            _isTracking ? Icons.location_on : Icons.location_off,
                            color: _isTracking ? Colors.green : Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text(
                            _isTracking ? 'Real-time tracking active' : 'Real-time tracking inactive',
                            style: TextStyle(
                              color: _isTracking ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Advanced Settings Card
            if (_findMeEnabled) ...[
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Advanced Settings',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 16),
                      SwitchListTile(
                        title: Text('Allow Remote Actions'),
                        subtitle: Text('Let trusted contacts play sounds and perform device actions'),
                        value: _allowRemoteActions,
                        onChanged: (value) {
                          setState(() => _allowRemoteActions = value);
                          _updateSetting('allowRemoteActions', value);
                        },
                      ),
                      SwitchListTile(
                        title: Text('Share with Trusted Contacts'),
                        subtitle: Text('Allow trusted contacts to view your location when family sharing is enabled'),
                        value: _shareWithContacts,
                        onChanged: (value) {
                          setState(() => _shareWithContacts = value);
                          _updateSetting('shareWithContacts', value);
                        },
                      ),
                      SwitchListTile(
                        title: Text('High Accuracy Mode'),
                        subtitle: Text('More precise location but higher battery usage'),
                        value: _highAccuracyMode,
                        onChanged: (value) {
                          setState(() => _highAccuracyMode = value);
                          _updateSetting('highAccuracyMode', value);
                        },
                      ),
                      SwitchListTile(
                        title: Text('Family Location Sharing'),
                        subtitle: Text('Allow family members to see your location continuously'),
                        value: _familySharingEnabled,
                        onChanged: (value) {
                          setState(() => _familySharingEnabled = value);
                          _updateSetting('familySharingEnabled', value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],

            // Trusted Contacts Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Trusted Contacts',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          onPressed: _addTrustedContact,
                          icon: Icon(Icons.add),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add family members or friends who can access your location. Grant specific permissions for each contact.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 16),
                    if (_trustedContacts.isEmpty)
                      Center(
                        child: Text(
                          'No trusted contacts added yet',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _trustedContacts.length,
                        itemBuilder: (context, index) {
                          final contact = _trustedContacts[index];
                          return ListTile(
                            leading: CircleAvatar(
                              child: Text(contact.name[0].toUpperCase()),
                            ),
                            title: Text(contact.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(contact.email),
                                Text('${contact.relationship} • ${contact.phone}'),
                                SizedBox(height: 8),
                                // Permission toggles for each contact
                                Row(
                                  children: [
                                    Expanded(
                                      child: CheckboxListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        controlAffinity: ListTileControlAffinity.leading,
                                        title: Text('Location Access', style: TextStyle(fontSize: 12)),
                                        value: contact.canAccessLocation,
                                        onChanged: (value) => _updateContactPermission(contact.id, 'canAccessLocation', value ?? false),
                                      ),
                                    ),
                                    Expanded(
                                      child: CheckboxListTile(
                                        dense: true,
                                        contentPadding: EdgeInsets.zero,
                                        controlAffinity: ListTileControlAffinity.leading,
                                        title: Text('Remote Actions', style: TextStyle(fontSize: 12)),
                                        value: contact.canPerformRemoteActions,
                                        onChanged: (value) => _updateContactPermission(contact.id, 'canPerformRemoteActions', value ?? false),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (contact.isVerified)
                                  Icon(Icons.verified, color: Colors.green, size: 20),
                                IconButton(
                                  onPressed: () => _removeTrustedContact(contact.id),
                                  icon: Icon(Icons.delete, color: Colors.red),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            // Family Locations Card (only show when family sharing is enabled)
            if (_familySharingEnabled)
              Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Family Locations',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            onPressed: _viewFamilyLocations,
                            icon: Icon(Icons.location_on, color: Colors.blue),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        'View real-time location of family members who have granted you access.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      SizedBox(height: 16),
                      
                      // Show family members who granted location access
                      FutureBuilder<List<TrustedContact>>(
                        future: _trustedContactsService.getFamilyMembers(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          
                          if (!snapshot.hasData || snapshot.data!.isEmpty) {
                            return Center(
                              child: Text(
                                'No family members are sharing location with you',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          }
                          
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.length,
                            itemBuilder: (context, index) {
                              final family = snapshot.data![index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: Icon(Icons.family_restroom, color: Colors.white),
                                ),
                                title: Text(family.name),
                                subtitle: Text('${family.relationship} • Location Sharing Enabled'),
                                trailing: IconButton(
                                  onPressed: () => _viewFamilyMemberLocation(family),
                                  icon: Icon(Icons.navigation, color: Colors.blue),
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
            SizedBox(height: 16),

            // Privacy Information Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Privacy & Security',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• All location data is encrypted and secured'),
                    Text('• Real-time tracking only when FindMe is enabled'),
                    Text('• Remote actions require trusted contact verification'),
                    Text('• Family sharing provides continuous location access'),
                    Text('• Individual permissions can be granted per contact'),
                    Text('• Location history is kept for maximum 30 days'),
                    Text('• You can disable any feature anytime'),
                    Text('• Full compliance with Data Privacy Act of 2012'),
                    SizedBox(height: 12),
                    Text(
                      'Enhanced Features:',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                    ),
                    Text('• Live location updates every 10 meters'),
                    Text('• Offline location buffering'),
                    Text('• Remote sound alerts (even on silent)'),
                    Text('• Last known location when device is offline'),
                    Text('• Battery and network status monitoring'),
                  ],
                ),
              ),
            ),
          ],
        ),
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
