import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_export.dart';
import '../models/location_model.dart';
import 'live_location_tracking_screen.dart';

class FindMyDevicesScreen extends StatefulWidget {
  @override
  _FindMyDevicesScreenState createState() => _FindMyDevicesScreenState();
}

class _FindMyDevicesScreenState extends State<FindMyDevicesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SimpleLocationService _locationService = SimpleLocationService();

  List<Map<String, dynamic>> _devices = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      print('=== LOAD DEVICES DEBUG START ===');
      print('Current user: ${user.uid}');

      // Find current user's document by userId field (not by document ID)
      final userQuery = await _firestore
          .collection('users')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      List<Map<String, dynamic>> devices = [];

      if (userQuery.docs.isNotEmpty) {
        final userDoc = userQuery.docs.first;
        final userData = userDoc.data();
        
        print('Current user data found: ${userData['name']}');
        
        // Get latest location
        LocationData? lastLocation;
        try {
          final locations = await _locationService.getLocationHistory(user.uid, limit: 1);
          if (locations.isNotEmpty) {
            lastLocation = locations.first;
            print('Current user location found: ${lastLocation.latitude}, ${lastLocation.longitude}');
          } else {
            print('No location found for current user');
          }
        } catch (e) {
          print('Error getting current user location: $e');
        }

        devices.add({
          'id': user.uid,
          'name': userData['name'] ?? 'My Device',
          'deviceType': 'phone',
          'isOnline': userData['isTracking'] ?? false,
          'findMeEnabled': userData['findMeEnabled'] ?? false,
          'lastLocation': lastLocation,
          'isCurrentDevice': true,
          'batteryLevel': 85, // Simulated
          'networkStatus': 'Connected',
        });
      }

      // Load trusted contacts who have shared their location
      final trustedContactsQuery = await _firestore
          .collection('findMeTrustedContacts')
          .where('userId', isEqualTo: user.uid)
          .where('canAccessLocation', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .get();

      print('Found ${trustedContactsQuery.docs.length} trusted contacts with location access');
      
      // ADDITIONAL DEBUG: Let's also check all trusted contacts (not just with location access)
      final allTrustedContactsQuery = await _firestore
          .collection('findMeTrustedContacts')
          .where('userId', isEqualTo: user.uid)
          .get();
      
      print('DEBUG: Found ${allTrustedContactsQuery.docs.length} total trusted contacts');
      for (var doc in allTrustedContactsQuery.docs) {
        final data = doc.data();
        print('  Contact: ${data['name']}, canAccessLocation: ${data['canAccessLocation']}, isVerified: ${data['isVerified']}');
      }

      // Process the verified trusted contacts with location access
      for (var contactDoc in trustedContactsQuery.docs) {
        final contactData = contactDoc.data();
        final contactUserId = contactData['contactUserId'];
        
        print('Processing trusted contact:');
        print('  - Contact doc ID: ${contactDoc.id}');
        print('  - Contact name: ${contactData['name']}');
        print('  - Contact userId: $contactUserId');

        try {
          // Get contact's user data by their userId field
          final contactUserQuery = await _firestore
              .collection('users')
              .where('userId', isEqualTo: contactUserId)
              .limit(1)
              .get();

          if (contactUserQuery.docs.isNotEmpty) {
            final contactUserData = contactUserQuery.docs.first.data();
            
            print('  - Contact user found: ${contactUserData['name'] ?? contactUserData['displayName']}');
            print('  - Family sharing enabled: ${contactUserData['familySharingEnabled']}');
            print('  - FindMe enabled: ${contactUserData['findMeEnabled']}');
            
            // Only show if family sharing is enabled
            if (contactUserData['familySharingEnabled'] == true) {
              // Get contact's latest location
              LocationData? contactLocation;
              try {
                print('  - Getting location history for contactUserId: $contactUserId');
                print('  - Current user ID for comparison: ${user.uid}');
                
                // CRITICAL FIX: Make sure we're not accidentally querying current user's location
                if (contactUserId == user.uid) {
                  print('  - ❌ ERROR: contactUserId matches current user! This should not happen.');
                  print('  - Contact name: ${contactData['name']}');
                  print('  - This indicates a bug in trusted contact storage.');
                  continue; // Skip this contact to avoid showing duplicate location
                }
                
                final locations = await _locationService.getLocationHistory(contactUserId, limit: 1);
                if (locations.isNotEmpty) {
                  contactLocation = locations.first;
                  print('  - Contact location found: ${contactLocation.latitude}, ${contactLocation.longitude}');
                  print('  - Contact location address: ${contactLocation.address}');
                  print('  - Contact location userId field: ${contactLocation.userId}');
                  
                  // CRITICAL VALIDATION: Ensure the location actually belongs to the contact
                  if (contactLocation.userId != contactUserId) {
                    print('  - ❌ CRITICAL BUG DETECTED: Location userId (${contactLocation.userId}) != contactUserId ($contactUserId)');
                    print('  - This means the wrong location is being returned!');
                    // Don't use this location data as it's incorrect
                    contactLocation = null;
                  } else {
                    print('  - ✅ Location validation passed: userId matches contactUserId');
                  }
                } else {
                  print('  - No location found for contact');
                }
              } catch (e) {
                print('  - Error getting contact location: $e');
              }

              // Only add if we have valid location data or contact is trackable
              // Also prevent duplicate device IDs
              final existingDevice = devices.firstWhere(
                (device) => device['id'] == contactUserId, 
                orElse: () => <String, dynamic>{}
              );
              
              if (existingDevice.isEmpty) {
                devices.add({
                  'id': contactUserId,
                  'name': contactData['name'] ?? 'Unknown Contact',
                  'deviceType': 'family',
                  'isOnline': contactUserData['isTracking'] ?? false,
                  'findMeEnabled': contactUserData['findMeEnabled'] ?? false,
                  'lastLocation': contactLocation,
                  'isCurrentDevice': false,
                  'relationship': contactData['relationship'] ?? 'Family',
                });
                
                print('  - Added contact to devices list');
              } else {
                print('  - Skipping contact: duplicate device ID detected');
              }
            } else {
              print('  - Skipping contact: family sharing not enabled');
            }
          } else {
            print('  - Contact user not found for contactUserId: $contactUserId');
          }
        } catch (e) {
          print('  - Error loading contact device: $e');
        }
      }
      
      // EXPERIMENTAL FIX: If no trusted contacts were found with the strict query,
      // try a broader approach that looks for mutual relationships
      if (trustedContactsQuery.docs.isEmpty) {
        print('');
        print('=== EXPERIMENTAL FIX: Checking for mutual trusted contact relationships ===');
        
        try {
          // Find users who have current user as their trusted contact with location sharing
          final mutualContactsQuery = await _firestore
              .collection('findMeTrustedContacts')
              .where('contactUserId', isEqualTo: user.uid)
              .where('canAccessLocation', isEqualTo: true)
              .where('isVerified', isEqualTo: true)
              .get();
          
          print('Found ${mutualContactsQuery.docs.length} users who have current user as trusted contact');
          
          for (var mutualContactDoc in mutualContactsQuery.docs) {
            final mutualContactData = mutualContactDoc.data();
            final mutualOwnerId = mutualContactData['userId']; // The person who added current user as contact
            
            print('Processing mutual relationship:');
            print('  - Mutual owner userId: $mutualOwnerId');
            print('  - Current user is their contact: ${mutualContactData['contactUserId']}');
            
            // Now check if current user also has this person as their trusted contact
            final reverseContactQuery = await _firestore
                .collection('findMeTrustedContacts')
                .where('userId', isEqualTo: user.uid)
                .where('contactUserId', isEqualTo: mutualOwnerId)
                .where('isVerified', isEqualTo: true)
                .limit(1)
                .get();
            
            if (reverseContactQuery.docs.isNotEmpty) {
              final reverseContactData = reverseContactQuery.docs.first.data();
              print('  - ✅ Found mutual relationship! Current user also has them as contact');
              print('  - Reverse contact name: ${reverseContactData['name']}');
              
              // Get the mutual contact's user data and location
              final mutualUserQuery = await _firestore
                  .collection('users')
                  .where('userId', isEqualTo: mutualOwnerId)
                  .limit(1)
                  .get();
              
              if (mutualUserQuery.docs.isNotEmpty) {
                final mutualUserData = mutualUserQuery.docs.first.data();
                
                if (mutualUserData['familySharingEnabled'] == true) {
                  print('  - Mutual contact has family sharing enabled');
                  
                  // Get their location
                  LocationData? mutualLocation;
                  try {
                    final locations = await _locationService.getLocationHistory(mutualOwnerId, limit: 1);
                    if (locations.isNotEmpty) {
                      mutualLocation = locations.first;
                      print('  - Mutual contact location found: ${mutualLocation.latitude}, ${mutualLocation.longitude}');
                    }
                  } catch (e) {
                    print('  - Error getting mutual contact location: $e');
                  }
                  
                  // Check for duplicates
                  final existingDevice = devices.firstWhere(
                    (device) => device['id'] == mutualOwnerId, 
                    orElse: () => <String, dynamic>{}
                  );
                  
                  if (existingDevice.isEmpty) {
                    devices.add({
                      'id': mutualOwnerId,
                      'name': reverseContactData['name'] ?? 'Mutual Contact',
                      'deviceType': 'family',
                      'isOnline': mutualUserData['isTracking'] ?? false,
                      'findMeEnabled': mutualUserData['findMeEnabled'] ?? false,
                      'lastLocation': mutualLocation,
                      'isCurrentDevice': false,
                      'relationship': 'Mutual Contact',
                    });
                    
                    print('  - ✅ Added mutual contact to devices list');
                  }
                }
              }
            } else {
              print('  - No reverse relationship found (one-way relationship only)');
            }
          }
        } catch (e) {
          print('Error in experimental mutual contact fix: $e');
        }
      }

      print('=== LOAD DEVICES DEBUG END ===');
      print('Total devices before validation: ${devices.length}');
      
      // Final validation: ensure no device shows wrong location data
      for (var device in devices) {
        final deviceId = device['id'];
        final deviceName = device['name'];
        final lastLocation = device['lastLocation'] as LocationData?;
        
        print('Validating device: $deviceName (ID: $deviceId)');
        
        if (lastLocation != null) {
          if (lastLocation.userId != deviceId) {
            print('❌ CRITICAL ERROR: Device $deviceName has location data from user ${lastLocation.userId} instead of $deviceId');
            // Remove the incorrect location data
            device['lastLocation'] = null;
            print('   Removed incorrect location data');
          } else {
            print('✅ Device location validation passed');
          }
        }
      }
      
      print('Total devices after validation: ${devices.length}');
      
      setState(() {
        _devices = devices;
        _loading = false;
      });
    } catch (e) {
      print('Error loading devices: $e');
      setState(() => _loading = false);
    }
  }

  String _getDeviceStatus(Map<String, dynamic> device) {
    if (!device['findMeEnabled']) {
      return 'FindMe Disabled';
    }
    
    if (device['isOnline']) {
      return 'Online';
    }
    
    final lastLocation = device['lastLocation'] as LocationData?;
    if (lastLocation != null) {
      final difference = DateTime.now().difference(lastLocation.timestamp);
      if (difference.inMinutes < 5) {
        return 'Online';
      } else if (difference.inMinutes < 60) {
        return 'Last seen ${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return 'Last seen ${difference.inHours}h ago';
      } else {
        return 'Last seen ${difference.inDays}d ago';
      }
    }
    
    return 'Location Unknown';
  }

  Color _getStatusColor(Map<String, dynamic> device) {
    if (!device['findMeEnabled']) {
      return Colors.grey;
    }
    
    if (device['isOnline']) {
      return Colors.green;
    }
    
    final lastLocation = device['lastLocation'] as LocationData?;
    if (lastLocation != null) {
      final difference = DateTime.now().difference(lastLocation.timestamp);
      if (difference.inMinutes < 5) {
        return Colors.green;
      } else if (difference.inHours < 1) {
        return Colors.orange;
      }
    }
    
    return Colors.red;
  }

  IconData _getDeviceIcon(String deviceType) {
    switch (deviceType) {
      case 'phone':
        return Icons.smartphone;
      case 'tablet':
        return Icons.tablet;
      case 'shared':
        return Icons.person_pin_circle;
      default:
        return Icons.device_unknown;
    }
  }

  void _showDeviceActions(Map<String, dynamic> device) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getDeviceIcon(device['deviceType'])),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device['name'],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _getDeviceStatus(device),
                        style: TextStyle(color: _getStatusColor(device)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            
            if (device['findMeEnabled']) ...[
              ListTile(
                leading: Icon(Icons.location_on, color: Colors.blue),
                title: Text('View on Map'),
                subtitle: Text('See current location and tracking history'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => LiveLocationTrackingScreen(
                        personId: device['id'],
                        personName: device['name'],
                      ),
                    ),
                  );
                },
              ),
              
              ListTile(
                leading: Icon(Icons.directions, color: Colors.green),
                title: Text('Get Directions'),
                subtitle: Text('Navigate to last known location'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement directions functionality
                },
              ),
            ] else ...[
              ListTile(
                leading: Icon(Icons.info, color: Colors.grey),
                title: Text('FindMe Not Enabled'),
                subtitle: Text('This device has not enabled FindMe feature'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Find My Devices'),
        backgroundColor: Color.fromARGB(255, 18, 32, 47),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadDevices,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDevices,
              child: _devices.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.devices, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No Devices Found',
                            style: TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                          Text(
                            'Enable FindMe to see your devices here',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(16),
                      itemCount: _devices.length,
                      itemBuilder: (context, index) {
                        final device = _devices[index];
                        final lastLocation = device['lastLocation'] as LocationData?;
                        
                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            leading: Stack(
                              children: [
                                Icon(
                                  _getDeviceIcon(device['deviceType']),
                                  size: 32,
                                  color: Colors.grey[700],
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(device),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    device['name'],
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                if (device['isCurrentDevice'])
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'This Device',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: 4),
                                Text(
                                  _getDeviceStatus(device),
                                  style: TextStyle(color: _getStatusColor(device)),
                                ),
                                if (lastLocation?.address != null) ...[
                                  SizedBox(height: 4),
                                  Text(
                                    lastLocation!.address!,
                                    style: TextStyle(fontSize: 12, color: Colors.grey),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (device['batteryLevel'] != null) ...[
                                  SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.battery_std, size: 16, color: Colors.grey),
                                      SizedBox(width: 4),
                                      Text(
                                        '${device['batteryLevel']}%',
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                            trailing: device['findMeEnabled']
                                ? Icon(Icons.more_vert)
                                : Icon(Icons.location_disabled, color: Colors.grey),
                            onTap: () => _showDeviceActions(device),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
