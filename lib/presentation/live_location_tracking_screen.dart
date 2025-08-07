import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/app_export.dart';
import '../models/location_model.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SimpleLocationService _locationService = SimpleLocationService();
  
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

  @override
  void initState() {
    super.initState();
    print('LiveLocationTrackingScreen initialized for user: ${widget.personId}');
    _startLocationTracking();
    _loadLocationHistory();
    _startStatusUpdates();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _statusUpdateTimer?.cancel();
    super.dispose();
  }

  void _startLocationTracking() {
    print('Starting location tracking for user: ${widget.personId}');
    
    // Listen to real-time location updates
    _locationSubscription = _firestore
        .collection('users')
        .doc(widget.personId)
        .collection('locations')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      try {
        print('Received location snapshot: ${snapshot.docs.length} documents');
        
        if (snapshot.docs.isNotEmpty) {
          final locationDoc = snapshot.docs.first;
          print('Location document data: ${locationDoc.data()}');
          
          final location = LocationData.fromSnapshot(locationDoc);
          print('Parsed location: ${location.latitude}, ${location.longitude} at ${location.timestamp}');
          
          _updateCurrentLocation(location);
        } else {
          print('No location documents found in snapshot');
          setState(() {
            _isLoading = false;
            _lastSeenStatus = 'No location data found';
          });
        }
      } catch (e) {
        print('Error processing location data: $e');
        setState(() {
          _isLoading = false;
          _lastSeenStatus = 'Error loading location: $e';
        });
      }
    }, onError: (error) {
      print('Error in location stream: $error');
      setState(() {
        _isLoading = false;
        _lastSeenStatus = 'Stream error: $error';
      });
    });
    
    print('Location tracking stream initialized');
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
    try {
      print('Loading location history for user: ${widget.personId}');
      final history = await _locationService.getLocationHistory(widget.personId, limit: 50);
      print('Loaded ${history.length} location records');
      
      setState(() {
        _locationHistory = history;
        _isLoading = false;
      });
      
      if (history.isNotEmpty) {
        print('Latest location: ${history.first.latitude}, ${history.first.longitude} at ${history.first.timestamp}');
        if (_currentLocation == null) {
          _updateCurrentLocation(history.first);
        }
      } else {
        print('No location history found');
        setState(() {
          _lastSeenStatus = 'No location history found';
        });
      }
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

  Future<void> _sendRemoteAction(String action) async {
    try {
      await _firestore
          .collection('users')
          .doc(widget.personId)
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
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _sendRemoteAction('play_sound');
                    },
                    icon: Icon(Icons.volume_up),
                    label: Text('Play Sound'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Open in maps app
                      // _openInMaps(_currentLocation!);
                    },
                    icon: Icon(Icons.directions),
                    label: Text('Directions'),
                  ),
                ),
              ],
            ),
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
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
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
              print('Refresh button tapped');
              setState(() {
                _isLoading = true;
                _lastSeenStatus = 'Refreshing location data...';
              });
              
              try {
                // Cancel existing subscription and restart
                _locationSubscription?.cancel();
                
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
                          print('Retry Loading button tapped');
                          setState(() {
                            _isLoading = true;
                            _lastSeenStatus = 'Retrying location load...';
                          });
                          
                          try {
                            // Cancel and restart everything
                            _locationSubscription?.cancel();
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
                      Row(
                        children: [
                          Expanded(
                            child: Card(
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
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Card(
                              child: InkWell(
                                onTap: () => _sendRemoteAction('play_sound'),
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.volume_up, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text(
                                        'Play Sound',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
