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

      // Load current user's device
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      List<Map<String, dynamic>> devices = [];

      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        
        // Get latest location
        LocationData? lastLocation;
        try {
          final locations = await _locationService.getLocationHistory(user.uid, limit: 1);
          if (locations.isNotEmpty) {
            lastLocation = locations.first;
          }
        } catch (e) {
          print('Error getting location: $e');
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
          .collection('users')
          .doc(user.uid)
          .collection('trustedContacts')
          .where('canAccessLocation', isEqualTo: true)
          .where('isVerified', isEqualTo: true)
          .get();

      for (var contactDoc in trustedContactsQuery.docs) {
        final contactData = contactDoc.data();
        final contactUserId = contactData['contactUserId'];

        try {
          // Get contact's user data
          final contactUserDoc = await _firestore
              .collection('users')
              .doc(contactUserId)
              .get();

          if (contactUserDoc.exists) {
            final contactUserData = contactUserDoc.data() as Map<String, dynamic>;
            
            // Only show if family sharing is enabled
            if (contactUserData['familySharingEnabled'] == true) {
              // Get contact's latest location
              LocationData? contactLocation;
              try {
                final locations = await _locationService.getLocationHistory(contactUserId, limit: 1);
                if (locations.isNotEmpty) {
                  contactLocation = locations.first;
                }
              } catch (e) {
                print('Error getting contact location: $e');
              }

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
            }
          }
        } catch (e) {
          print('Error loading contact device: $e');
        }
      }

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

  Future<void> _sendRemoteAction(String deviceId, String action) async {
    try {
      await _firestore
          .collection('users')
          .doc(deviceId)
          .collection('remote_actions')
          .add({
        'action': action,
        'requestedBy': _auth.currentUser?.uid,
        'requestedAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$action request sent to device')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending request: $e')),
      );
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
              
              if (device['isCurrentDevice']) ...[
                ListTile(
                  leading: Icon(Icons.volume_up, color: Colors.orange),
                  title: Text('Play Sound'),
                  subtitle: Text('Make device play a loud sound'),
                  onTap: () {
                    Navigator.pop(context);
                    _sendRemoteAction(device['id'], 'play_sound');
                  },
                ),
                
                ListTile(
                  leading: Icon(Icons.lock, color: Colors.red),
                  title: Text('Mark as Lost'),
                  subtitle: Text('Enable lost mode and lock device'),
                  onTap: () {
                    Navigator.pop(context);
                    _showLostModeDialog(device);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: Icon(Icons.volume_up, color: Colors.orange),
                  title: Text('Request Sound'),
                  subtitle: Text('Ask contact to play device sound'),
                  onTap: () {
                    Navigator.pop(context);
                    _sendRemoteAction(device['id'], 'play_sound');
                  },
                ),
              ],
              
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

  void _showLostModeDialog(Map<String, dynamic> device) {
    final messageController = TextEditingController();
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Mark as Lost'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your device will be locked and display a custom message. You can still track its location.',
              ),
              SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: InputDecoration(
                  labelText: 'Message to display',
                  hintText: 'This device is lost. Please call...',
                ),
                maxLines: 2,
              ),
              SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Contact phone number',
                  hintText: '+63 9XX XXX XXXX',
                ),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _enableLostMode(
                device['id'],
                messageController.text,
                phoneController.text,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Enable Lost Mode'),
          ),
        ],
      ),
    );
  }

  Future<void> _enableLostMode(String deviceId, String message, String phone) async {
    try {
      await _firestore.collection('users').doc(deviceId).update({
        'lostMode': {
          'enabled': true,
          'message': message,
          'contactPhone': phone,
          'enabledAt': FieldValue.serverTimestamp(),
          'enabledBy': _auth.currentUser?.uid,
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lost mode enabled'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error enabling lost mode: $e')),
      );
    }
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
