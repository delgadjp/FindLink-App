import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_export.dart';
import '../models/location_model.dart';
import '../core/network/trusted_contacts_service.dart';
import 'dart:async';

class LiveLocationTrackingScreen extends StatefulWidget {
  final String personId;
  final String personName;

  const LiveLocationTrackingScreen({
    Key? key,
    required this.personId,
    required this.personName,
  }) : super(key: key);

  @override
  _LiveLocationTrackingScreenState createState() => _LiveLocationTrackingScreenState();
}

class _LiveLocationTrackingScreenState extends State<LiveLocationTrackingScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TrustedContactsService _trustedContactsService = TrustedContactsService();
  
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LocationData> _locationHistory = [];
  LocationData? _currentLocation;
  StreamSubscription<QuerySnapshot>? _locationSubscription;
  Timer? _statusUpdateTimer;
  
  bool _isLoading = true;
  bool _isPersonOnline = false;
  String _lastSeenStatus = 'Checking...';
  bool _showLocationHistory = false;
  bool _followLocation = true;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    print('LiveLocationTrackingScreen initialized for user: ${widget.personId}');
    _checkPermissionAndStartTracking();
  }

  Future<void> _checkPermissionAndStartTracking() async {
    try {
      setState(() {
        _isLoading = true;
        _lastSeenStatus = 'Checking access permissions...';
      });

      // Check if current user can access location data for this person
      final hasAccess = await _trustedContactsService.canAccessLocationData(widget.personId);
      
      setState(() {
        _hasPermission = hasAccess;
      });

      if (hasAccess) {
        print('Permission granted, starting location tracking');
        setState(() {
          _lastSeenStatus = 'Loading location data...';
        });
        _startLocationTracking();
        _loadLocationHistory();
        _startStatusUpdates();
      } else {
        print('Permission denied for accessing ${widget.personId} location data');
        setState(() {
          _isLoading = false;
          _lastSeenStatus = 'No permission to access location data';
        });
      }
    } catch (e) {
      print('Error checking permissions: $e');
      setState(() {
        _isLoading = false;
        _hasPermission = false;
        _lastSeenStatus = 'Error checking permissions: $e';
      });
    }
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _statusUpdateTimer?.cancel();
    super.dispose();
  }

  void _startLocationTracking() {
    if (!_hasPermission) {
      print('Cannot start location tracking: No permission');
      return;
    }

    print('Starting location tracking for user: ${widget.personId}');
    
    // Instead of directly querying another user's location data (which security rules prevent),
    // we'll create a periodic check that validates permissions and gets the latest shared location
    _startPeriodicLocationCheck();
  }

  void _startPeriodicLocationCheck() {
    // Check for location updates every 30 seconds
    _statusUpdateTimer = Timer.periodic(Duration(seconds: 30), (timer) async {
      await _checkAndUpdateLocation();
    });
    
    // Also do an immediate check
    _checkAndUpdateLocation();
  }

  Future<void> _checkAndUpdateLocation() async {
    try {
      // First verify we still have permission
      final stillHasAccess = await _trustedContactsService.canAccessLocationData(widget.personId);
      if (!stillHasAccess) {
        print('Permission revoked during location tracking');
        setState(() {
          _hasPermission = false;
          _lastSeenStatus = 'Permission revoked';
        });
        _locationSubscription?.cancel();
        _statusUpdateTimer?.cancel();
        return;
      }

      // Get the user's last known location from their user document
      final userQuery = await _firestore
          .collection('users')
          .where('userId', isEqualTo: widget.personId)
          .limit(1)
          .get();
      
      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        final lastKnownLocation = userData['lastKnownLocation'];
        
        if (lastKnownLocation != null && lastKnownLocation is Map<String, dynamic>) {
          // Create a LocationData object from the user's last known location
          try {
            final locationData = LocationData(
              id: 'shared_${DateTime.now().millisecondsSinceEpoch}',
              userId: widget.personId,
              latitude: (lastKnownLocation['latitude'] as num).toDouble(),
              longitude: (lastKnownLocation['longitude'] as num).toDouble(),
              timestamp: lastKnownLocation['timestamp'] != null 
                  ? (lastKnownLocation['timestamp'] as Timestamp).toDate()
                  : DateTime.now(),
              accuracy: lastKnownLocation['accuracy']?.toDouble(),
              address: lastKnownLocation['address'],
            );
            
            print('Got shared location: ${locationData.latitude}, ${locationData.longitude}');
            _updateCurrentLocation(locationData);
          } catch (e) {
            print('Error parsing shared location data: $e');
          }
        } else {
          print('No shared location data found in user document');
          setState(() {
            _lastSeenStatus = 'No location data shared';
          });
        }
      } else {
        print('User document not found');
        setState(() {
          _lastSeenStatus = 'User not found';
        });
      }
    } catch (e) {
      print('Error checking shared location: $e');
      setState(() {
        _lastSeenStatus = 'Error getting location: $e';
      });
    }
  }

  void _updateCurrentLocation(LocationData location) {
    setState(() {
      _currentLocation = location;
      _isPersonOnline = DateTime.now().difference(location.timestamp).inMinutes < 5;
      _lastSeenStatus = _isPersonOnline 
          ? 'Online now'
          : 'Last seen ${_formatTimeAgo(location.timestamp)}';
      _isLoading = false;
    });

    _updateMapLocation(location);
    
    // Add to location history
    if (_locationHistory.isEmpty || _locationHistory.first.id != location.id) {
      setState(() {
        _locationHistory.insert(0, location);
        if (_locationHistory.length > 100) {
          _locationHistory = _locationHistory.take(100).toList();
        }
      });
      _updateLocationTrail();
    }
  }

  void _updateMapLocation(LocationData location) {
    final position = LatLng(location.latitude, location.longitude);
    
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: MarkerId('current_location'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _isPersonOnline ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
          ),
          infoWindow: InfoWindow(
            title: widget.personName,
            snippet: _isPersonOnline ? 'Currently here' : 'Last seen here',
          ),
        ),
      );
    });

    if (_followLocation && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: position, zoom: 16),
        ),
      );
    }
  }

  void _updateLocationTrail() {
    if (_showLocationHistory && _locationHistory.length > 1) {
      List<LatLng> points = _locationHistory
          .map((loc) => LatLng(loc.latitude, loc.longitude))
          .toList();

      setState(() {
        _polylines.clear();
        _polylines.add(
          Polyline(
            polylineId: PolylineId('location_trail'),
            points: points,
            color: Colors.blue,
            width: 3,
            patterns: [PatternItem.dash(20), PatternItem.gap(10)],
          ),
        );

        // Add markers for significant locations
        for (int i = 1; i < _locationHistory.length && i < 10; i++) {
          final loc = _locationHistory[i];
          _markers.add(
            Marker(
              markerId: MarkerId('history_$i'),
              position: LatLng(loc.latitude, loc.longitude),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              alpha: 0.7,
              infoWindow: InfoWindow(
                title: 'Previous location',
                snippet: _formatTimeAgo(loc.timestamp),
              ),
            ),
          );
        }
      });
    } else {
      setState(() {
        _polylines.clear();
        // Remove history markers, keep only current location
        _markers.removeWhere((marker) => marker.markerId.value.startsWith('history_'));
      });
    }
  }

  Future<void> _loadLocationHistory() async {
    if (!_hasPermission) {
      print('Cannot load location history: No permission');
      setState(() {
        _isLoading = false;
        _lastSeenStatus = 'No permission to access location data';
      });
      return;
    }

    try {
      print('Loading location history for user: ${widget.personId}');
      
      // Instead of using the SimpleLocationService which queries directly,
      // we'll check if we have permission first through trusted contacts service
      final canAccess = await _trustedContactsService.canAccessLocationData(widget.personId);
      if (!canAccess) {
        print('Permission check failed during location history load');
        setState(() {
          _isLoading = false;
          _hasPermission = false;
          _lastSeenStatus = 'Permission revoked or expired';
        });
        return;
      }

      // Since we have permission, we can try to get location data
      // For now, we'll rely on the real-time stream, but you could implement
      // a server-side function or admin-only query for historical data
      setState(() {
        _isLoading = false;
        _lastSeenStatus = 'Waiting for location updates...';
      });
      
      print('Location history loading completed (using real-time stream)');
    } catch (e) {
      print('Error loading location history: $e');
      setState(() {
        _isLoading = false;
        _lastSeenStatus = 'Error loading location history: $e';
      });
    }
  }

  void _startStatusUpdates() {
    _statusUpdateTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (_currentLocation != null) {
        setState(() {
          _isPersonOnline = DateTime.now().difference(_currentLocation!.timestamp).inMinutes < 5;
          _lastSeenStatus = _isPersonOnline 
              ? 'Online now'
              : 'Last seen ${_formatTimeAgo(_currentLocation!.timestamp)}';
        });
      }
    });
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showLocationDetails() {
    if (_currentLocation == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Location Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            _buildDetailRow('Status', _lastSeenStatus),
            _buildDetailRow('Latitude', _currentLocation!.latitude.toStringAsFixed(6)),
            _buildDetailRow('Longitude', _currentLocation!.longitude.toStringAsFixed(6)),
            if (_currentLocation!.accuracy != null)
              _buildDetailRow('Accuracy', '±${_currentLocation!.accuracy!.toStringAsFixed(0)}m'),
            if (_currentLocation!.address != null)
              _buildDetailRow('Address', _currentLocation!.address!),
            _buildDetailRow('Updated', _formatDateTime(_currentLocation!.timestamp)),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    int hour = dateTime.hour;
    String amPm = hour >= 12 ? 'PM' : 'AM';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${hour}:${dateTime.minute.toString().padLeft(2, '0')} $amPm';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.personName),
            Text(
              _lastSeenStatus,
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Color.fromARGB(255, 18, 32, 47),
        actions: [
          IconButton(
            icon: Icon(_followLocation ? Icons.my_location : Icons.location_disabled),
            onPressed: () {
              setState(() => _followLocation = !_followLocation);
              if (_followLocation && _currentLocation != null) {
                _updateMapLocation(_currentLocation!);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () async {
              if (!_hasPermission) {
                await _checkPermissionAndStartTracking();
                return;
              }
              
              print('Refresh button tapped');
              setState(() {
                _isLoading = true;
                _lastSeenStatus = 'Refreshing location data...';
              });
              
              try {
                // Cancel existing timers and restart
                _locationSubscription?.cancel();
                _statusUpdateTimer?.cancel();
                
                // Clear current data
                setState(() {
                  _currentLocation = null;
                  _locationHistory = [];
                  _markers.clear();
                  _polylines.clear();
                });
                
                // Reload everything
                await _loadLocationHistory();
                _startLocationTracking();
                
                print('Refresh completed');
              } catch (e) {
                print('Error during refresh: $e');
                setState(() {
                  _isLoading = false;
                  _lastSeenStatus = 'Refresh failed: $e';
                });
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: _showLocationDetails,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading location data...'),
                  Text('For user: ${widget.personName}', 
                       style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            )
          : !_hasPermission
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.block, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'Access Denied',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You don\'t have permission to view ${widget.personName}\'s location.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'You need to be added as a trusted contact with location access.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _checkPermissionAndStartTracking(),
                        icon: Icon(Icons.refresh),
                        label: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _currentLocation == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No Location Data',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        _lastSeenStatus,
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (!_hasPermission) {
                            await _checkPermissionAndStartTracking();
                            return;
                          }
                          
                          print('Refresh Location button tapped');
                          setState(() {
                            _isLoading = true;
                            _lastSeenStatus = 'Refreshing location data...';
                          });
                          
                          try {
                            await _loadLocationHistory();
                          } catch (e) {
                            print('Error during manual refresh: $e');
                            setState(() {
                              _isLoading = false;
                              _lastSeenStatus = 'Refresh failed: $e';
                            });
                          }
                        },
                        icon: Icon(Icons.refresh),
                        label: Text('Refresh Location'),
                      ),
                      SizedBox(height: 8),
                      TextButton(
                        onPressed: () async {
                          if (!_hasPermission) {
                            await _checkPermissionAndStartTracking();
                            return;
                          }
                          
                          print('Retry Loading button tapped');
                          setState(() {
                            _isLoading = true;
                            _lastSeenStatus = 'Retrying location load...';
                          });
                          
                          try {
                            // Cancel and restart everything
                            _locationSubscription?.cancel();
                            _statusUpdateTimer?.cancel();
                            await _loadLocationHistory();
                            _startLocationTracking();
                          } catch (e) {
                            print('Error during retry: $e');
                            setState(() {
                              _isLoading = false;
                              _lastSeenStatus = 'Retry failed: $e';
                            });
                          }
                        },
                        child: Text('Retry Loading'),
                      ),
                    ],
                  ),
                )
              : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentLocation != null
                        ? LatLng(_currentLocation!.latitude, _currentLocation!.longitude)
                        : LatLng(14.5995, 120.9842), // Manila default
                    zoom: 16,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                    if (_currentLocation != null) {
                      _updateMapLocation(_currentLocation!);
                    }
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                ),
                
                // Status card
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: _isPersonOnline ? Colors.green : Colors.red,
                            radius: 6,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _lastSeenStatus,
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          if (_currentLocation != null)
                            Text(
                              _formatDateTime(_currentLocation!.timestamp),
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Control buttons
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Card(
                        child: InkWell(
                          onTap: () => setState(() {
                            _showLocationHistory = !_showLocationHistory;
                            _updateLocationTrail();
                          }),
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _showLocationHistory ? Icons.timeline : Icons.timeline_outlined,
                                  color: _showLocationHistory ? Colors.blue : Colors.grey,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  _showLocationHistory ? 'Hide Trail' : 'Show Trail',
                                  style: TextStyle(
                                    color: _showLocationHistory ? Colors.blue : Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
