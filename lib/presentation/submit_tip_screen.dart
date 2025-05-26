import '../core/app_export.dart';
import 'dart:convert';
import 'dart:io';
export 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:geocoding/geocoding.dart'; // Add this import for geocoding
import 'package:http/http.dart' as http; // Add HTTP package for API calls
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class SubmitTipScreen extends StatefulWidget {
  final MissingPerson person;

  const SubmitTipScreen({Key? key, required this.person}) : super(key: key);

  @override
  _SubmitTipScreenState createState() => _SubmitTipScreenState();
}

// Add this enum for validation status states
enum ValidationStatus {
  none,
  processing,
  error,
  warning,
  noHuman,
  humanDetected,
  success
}

class _SubmitTipScreenState extends State<SubmitTipScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController(); // Add scroll controller
  
  // Key for validation section for scrolling
  final GlobalKey _validationSectionKey = GlobalKey();
  
  // Validation state variables
  bool _isSubmitting = false;
  ValidationStatus _validationStatus = ValidationStatus.none;
  String _validationMessage = '';
  String _validationConfidence = '0.0';
  
  // Variables for nearby tips feature
  bool _isCheckingNearbyTips = false;
  List<Map<String, dynamic>> _nearbyTips = [];
  final double _nearbyTipsRadius = 100; 
  bool _hasNearbyTips = false;
  
  // Create a map to store keys for form fields
  final Map<String, GlobalKey<FormFieldState>> _fieldKeys = {
    'dateLastSeen': GlobalKey<FormFieldState>(),
    'timeLastSeen': GlobalKey<FormFieldState>(),
    'gender': GlobalKey<FormFieldState>(),
    'ageRange': GlobalKey<FormFieldState>(),
    'heightRange': GlobalKey<FormFieldState>(),
    'clothing': GlobalKey<FormFieldState>(),
    'features': GlobalKey<FormFieldState>(),
    'hairColor': GlobalKey<FormFieldState>(),
    'description': GlobalKey<FormFieldState>(),
    'longitude': GlobalKey<FormFieldState>(),
    'latitude': GlobalKey<FormFieldState>(),
  };

  // Track privacy policy acceptance
  bool hasAcceptedPrivacyPolicy = false;
  bool isCheckingPrivacyStatus = true;

  File? _imageFile;
  Uint8List? _webImage;
  final picker = ImagePicker();
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;

  final TextEditingController _dateLastSeenController = TextEditingController();
  final TextEditingController _timeLastSeenController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _clothingController = TextEditingController();
  final TextEditingController _featuresController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _hairColorController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _longitudeController = TextEditingController();
  final TextEditingController _latitudeController = TextEditingController();
  final TextEditingController _coordinatesController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isGettingAddress = false;
  String _addressError = '';

  final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd');
  final DateFormat _timeFormatter = DateFormat('HH:mm');

  String? selectedGender;
  String? selectedHairColor;
  String? selectedAgeRange;
  String? selectedHeightRange; // Add selected height range

  final List<String> genderOptions = ['Male', 'Female', 'Prefer not to say'];
  final List<String> hairColors = [
    'Black', 'Brown', 'Blonde', 'Red', 'Gray', 'White',
    'Dark Brown', 'Light Brown', 'Auburn', 'Strawberry Blonde', 'Unknown'
  ];
  
  // Define age range options
  final List<String> ageRanges = [
    'Under 12', '12-17', '18-24', '25-34', '35-44', 
    '45-54', '55-64', '65 and older', 'Unknown'
  ];
  
  // Define height range options
  final List<String> heightRanges = [
    'Under 4\' (< 122cm)',
    '4\' - 4\'6" (122-137cm)', 
    '4\'7" - 5\' (140-152cm)',
    '5\'1" - 5\'6" (155-168cm)', 
    '5\'7" - 6\' (170-183cm)',
    '6\'1" - 6\'6" (185-198cm)', 
    'Over 6\'6" (> 198cm)',
    'Unknown'
  ];

  Map<String, String> tipData = {
    'dateLastSeen': '',
    'timeLastSeen': '',
    'gender': '',
    'ageRange': '',
    'heightRange': '', // Add height range to tipData
    'clothing': '',
    'features': '',
    'hairColor': '',
    'description': '',
    'image': '',
    'longitude': '',
    'latitude': '',
    'userId': '',
  };

  GoogleMapController? mapController;
  Set<Marker> markers = {};
  LatLng? selectedLocation;

  static const String SCREEN_SUBMIT_TIP_COMPLIANCE = 'submitTipComplianceAccepted';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    checkScreenCompliance();
  }

  // Check compliance for submit tip screen
  Future<void> checkScreenCompliance() async {
    setState(() {
      isCheckingPrivacyStatus = true;
    });
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        setState(() {
          hasAcceptedPrivacyPolicy = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showCompliance();
        });
        return;
      }
      final authService = AuthService();
      bool accepted = await authService.getScreenComplianceAccepted(currentUser.uid, ModalUtils.SCREEN_SUBMIT_TIP_COMPLIANCE);
      setState(() {
        hasAcceptedPrivacyPolicy = accepted;
      });
      if (!accepted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showCompliance();
        });
      }
    } catch (e) {
      print('Error checking compliance acceptance: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showCompliance();
      });
    } finally {
      setState(() {
        isCheckingPrivacyStatus = false;
      });
    }
  }

  // Show both modals in sequence for submit tip
  void showCompliance() {
    final currentUser = _auth.currentUser;
    if (hasAcceptedPrivacyPolicy) return;
    ModalUtils.showLegalDisclaimerModal(
      context,
      onAccept: () async {
        ModalUtils.showPrivacyPolicyModal(
          context,
          onAcceptanceUpdate: (accepted) async {
            setState(() {
              hasAcceptedPrivacyPolicy = accepted;
            });
            if (accepted && currentUser != null) {
              try {
                await AuthService().updateScreenComplianceAccepted(currentUser.uid, ModalUtils.SCREEN_SUBMIT_TIP_COMPLIANCE, true);
                print('Submit tip compliance accepted in database');
              } catch (e) {
                print('Error updating submit tip compliance: $e');
              }
            } else if (!accepted && currentUser != null) {
              await AuthService().updateScreenComplianceAccepted(currentUser.uid, ModalUtils.SCREEN_SUBMIT_TIP_COMPLIANCE, false);
            }
            if (!accepted) {
              Navigator.of(context).pop();
            }
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Show loading indicator
      setState(() {
        _isGettingAddress = true;
      });

      // If we don't have a selected location yet, set a default one
      // This ensures the map shows something even if permissions fail
      if (selectedLocation == null) {
        setState(() {
          // Default to a common location (e.g. central London)
          selectedLocation = LatLng(51.509865, -0.118092);
          _updateMarkerAndControllers();
          print("Setting default location as permission not yet granted");
        });
      }

      // Request location permission
      final status = await Permission.location.request();
      print("Location permission status: $status");
      
      if (status.isGranted) {
        // Get current position if permission is granted
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        setState(() {
          selectedLocation = LatLng(position.latitude, position.longitude);
          _updateMarkerAndControllers();
          
          // If we have a map controller, animate to the new position
          if (mapController != null) {
            mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(
                  target: selectedLocation!,
                  zoom: 15,
                ),
              ),
            );
          }          // Get address when location is updated
          _getAddressFromCoordinates();
          
          // Check for nearby tips with the current location
          _checkForNearbyTips();
        });
      } else {
        // Show error message if permission is denied
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permission is required to show your location on the map')),
        );
        setState(() {
          _isGettingAddress = false;
        });
      }
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location. Please try again.')),
      );
      setState(() {
        _isGettingAddress = false;
      });
    }
  }
  void _updateMarkerAndControllers() {
    if (selectedLocation != null) {
      markers.clear();
      markers.add(
        Marker(
          markerId: MarkerId('selected_location'),
          position: selectedLocation!,
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              selectedLocation = newPosition;
              _longitudeController.text = newPosition.longitude.toString();
              _latitudeController.text = newPosition.latitude.toString();
              _getAddressFromCoordinates(); // Get address when marker is dragged
            });
            // Check for nearby tips when marker is dragged
            _checkForNearbyTips();
          },
        ),
      );
      _longitudeController.text = selectedLocation!.longitude.toString();
      _latitudeController.text = selectedLocation!.latitude.toString();
    }
  }

  // Add new method to get address from coordinates
  Future<void> _getAddressFromCoordinates() async {
    if (selectedLocation == null) return;

    setState(() {
      _isGettingAddress = true;
      _addressError = '';
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        selectedLocation!.latitude,
        selectedLocation!.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = '';
        
        // Build address string from components
        if (place.street != null && place.street!.isNotEmpty) {
          address += place.street!;
        }
        
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address += address.isEmpty ? place.subLocality! : ", ${place.subLocality}";
        }
        
        if (place.locality != null && place.locality!.isNotEmpty) {
          address += address.isEmpty ? place.locality! : ", ${place.locality}";
        }
        
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          address += address.isEmpty ? place.postalCode! : ", ${place.postalCode}";
        }
        
        if (place.country != null && place.country!.isNotEmpty) {
          address += address.isEmpty ? place.country! : ", ${place.country}";
        }
        
        setState(() {
          _addressController.text = address;
          _isGettingAddress = false;
        });
      } else {
        setState(() {
          _addressController.text = "Address not found";
          _isGettingAddress = false;
          _addressError = "Could not determine address for this location";
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        _addressController.text = "Error retrieving address";
        _isGettingAddress = false;
        _addressError = "Error: $e";
      });
    }
  }

  String? _validateCoordinate(String? value, String type) {
    if (value == null || value.isEmpty) return 'Please enter $type';
    if (!RegExp(r'^-?\d*\.?\d*$').hasMatch(value)) return 'Invalid $type format';
    double? coord = double.tryParse(value);
    if (coord == null) return 'Invalid $type';
    if (type == 'longitude' && (coord < -180 || coord > 180)) {
      return 'Longitude must be between -180 and 180';
    }
    if (type == 'latitude' && (coord < -90 || coord > 90)) {
      return 'Latitude must be between -90 and 90';
    }
    return null;
  }

  /// Enhanced image picker with better permission handling and immediate validation
  Future<void> _pickImage(ImageSource source) async {
    try {
      // Handle camera permission differently - check permission status first
      if (source == ImageSource.camera) {
        PermissionStatus cameraStatus = await Permission.camera.status;
        
        if (cameraStatus.isDenied) {
          // Request permission if it's denied
          cameraStatus = await Permission.camera.request();
        }
        
        if (cameraStatus.isPermanentlyDenied) {
          // Show dialog to open app settings if permanently denied
          showDialog(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: Text("Camera Permission Required"),
              content: Text(
                "Camera permission is needed to take photos. Please enable it in your device settings.",
              ),
              actions: [
                TextButton(
                  child: Text("Cancel"),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: Text("Open Settings"),
                  onPressed: () {
                    Navigator.pop(context);
                    openAppSettings();
                  },
                ),
              ],
            ),
          );
          return;
        }
        
        if (!cameraStatus.isGranted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Camera permission is required to take photos'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: openAppSettings,
              ),
            ),
          );
          return;
        }
      }
      
      // If we got here, permission is granted or we're using gallery
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        // Show loading state while processing the image
        setState(() {
          _validationMessage = "Processing image...";
          _validationStatus = ValidationStatus.processing;
        });
        
        // Prepare image data based on platform
        dynamic imageData;
        if (kIsWeb) {
          // Handle web platform
          final bytes = await pickedFile.readAsBytes();
          imageData = bytes;
          setState(() {
            _webImage = bytes;
            tipData['image'] = base64Encode(bytes); // Store as base64 for web
          });
        } else {
          // Handle mobile platforms
          final file = File(pickedFile.path);
          imageData = file;
          setState(() {
            _imageFile = file;
            tipData['image'] = pickedFile.path;
          });
        }
        
        // Immediately validate the image with Google Vision
        try {
          final TipService tipService = TipService();
          Map<String, dynamic> validationResult = await tipService.validateImageWithGoogleVision(imageData);
          
          if (!validationResult['isValid']) {
            setState(() {
              _validationMessage = 'Error validating image: ${validationResult['message']}';
              _validationStatus = ValidationStatus.error;
            });
          } else if (!validationResult['containsHuman']) {
            // If no human is detected, clear the image and show notification
            setState(() {
              _imageFile = null;
              _webImage = null;
              tipData['image'] = '';
              _validationMessage = 'No person detected in the image. Image has been automatically removed.';
              _validationConfidence = (validationResult['confidence'] * 100).toStringAsFixed(1);
              _validationStatus = ValidationStatus.noHuman;
            });
            
            // Show a snackbar notification
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image removed - no person detected'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            // Human detected - keep the image and show confirmation
            setState(() {
              _validationMessage = 'Person detected in image!';
              _validationConfidence = (validationResult['confidence'] * 100).toStringAsFixed(1);
              _validationStatus = ValidationStatus.humanDetected;
            });
          }
        } catch (e) {
          print('Error during image validation: $e');
          setState(() {
            _validationMessage = 'Image validation error: ${e.toString()}';
            _validationStatus = ValidationStatus.warning;
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accessing camera: ${e.toString()}')),
      );
    }
  }

  /// Submit tip data with validation
  Future<void> _submitTip() async {
    // Check if user is authenticated first
    if (_auth.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must be logged in to submit a tip.'),
          action: SnackBarAction(
            label: 'Sign In',
            onPressed: () {
              // Navigate to login screen
              Navigator.pushNamed(context, '/login');
            },
          ),
        ),
      );
      return;
    }
    
    // Debug: Print auth info to verify authentication
    print("Current user: ${_auth.currentUser?.uid}");
    print("Current user email: ${_auth.currentUser?.email}");
    print("Is user anonymous: ${_auth.currentUser?.isAnonymous}");

    // Check form validation state
    final bool isValid = _formKey.currentState?.validate() ?? false;
    
    if (!isValid) {
      // Find the first field with an error and scroll to it
      GlobalKey<FormFieldState>? firstErrorKey;
      
      for (final entry in _fieldKeys.entries) {
        final fieldState = entry.value.currentState;
        if (fieldState != null && !fieldState.isValid) {
          firstErrorKey = entry.value;
          print("Found error in field: ${entry.key}");
          break;
        }
      }
      
      // Additional validation for dropdown fields that might not have keys
      if (firstErrorKey == null) {
        if (selectedGender == null) {
          firstErrorKey = _fieldKeys['gender'];
        } else if (selectedAgeRange == null) {
          firstErrorKey = _fieldKeys['ageRange'];
        } else if (selectedHeightRange == null) {
          firstErrorKey = _fieldKeys['heightRange']; 
        } else if (selectedHairColor == null) {
          firstErrorKey = _fieldKeys['hairColor'];
        }
      }
      
      // Scroll to the first field with an error
      if (firstErrorKey != null) {
        Scrollable.ensureVisible(
          firstErrorKey.currentContext!,
          duration: Duration(milliseconds: 500),
          alignment: 0.2, // Align error near the top but not at the very top
          curve: Curves.easeInOut,
        );
      }
      
      // Show error message to user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fix the highlighted errors in the form"),
          backgroundColor: Colors.red.shade700,
          duration: Duration(seconds: 2),
        ),
      );
      
      return;
    }    // Check for duplicate tip for the same missing person within 100 meters
    // This matches the logic from SubmitReport.jsx
    final double lat = double.tryParse(_latitudeController.text) ?? 0.0;
    final double lng = double.tryParse(_longitudeController.text) ?? 0.0;
    final String personName = widget.person.name;
    
    print("DEBUG: Checking for duplicates for person: $personName at location: $lat, $lng");
    
    final bool duplicateExists = await _hasDuplicateTipForPersonNearby(personName, lat, lng, 100);
    if (duplicateExists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A tip for "${personName}" already exists within 100 meters of this location.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Update UI to show loading state
        setState(() {
          _isSubmitting = true;
          _validationMessage = "Processing your submission...";
          _validationStatus = ValidationStatus.processing;
        });

        final TipService tipService = TipService();
        
        // Get current user ID - ensure this is never null at this point
        String userId = _auth.currentUser!.uid;
        
        print("Submitting tip with userId: $userId");
        
        // Prepare the image data to pass to TipService
        dynamic imageData;
        if (kIsWeb) {
          imageData = _webImage; // Uint8List for web
        } else if (_imageFile != null) {
          imageData = _imageFile; // File for mobile
        }
        
        // Update validation status for submission
        setState(() {
          _validationMessage = "Submitting tip...";
          _validationStatus = ValidationStatus.processing;
        });
        
        // Submit tip with the image data
        await tipService.submitTip(
          dateLastSeen: _dateLastSeenController.text,
          timeLastSeen: _timeLastSeenController.text,
          gender: selectedGender ?? '',
          ageRange: selectedAgeRange ?? 'Unknown',
          heightRange: selectedHeightRange ?? 'Unknown',
          hairColor: selectedHairColor ?? '',
          clothing: _clothingController.text,
          features: _featuresController.text,
          description: _descriptionController.text,
          lat: double.parse(_latitudeController.text),
          lng: double.parse(_longitudeController.text),
          userId: userId,
          address: _addressController.text,
          imageData: imageData, // Pass the image data to the service
          validateImage: false, // Disable second validation since we already validated
          caseId: widget.person.caseId, // Pass the caseId for missing person name lookup
          missingPersonName: widget.person.name, // Pass the name from the UI
        );

        // Update UI to show success
        setState(() {
          _isSubmitting = false;
          _validationMessage = "Tip submitted successfully!";
          _validationStatus = ValidationStatus.success;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tip submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Wait a moment for the user to see the success message
        await Future.delayed(Duration(seconds: 2));
        
        // Navigate back to the missing person screen
        Navigator.pushReplacementNamed(context, AppRoutes.missingPerson);

      } catch (e) {
        print('Error saving tip: $e');
        
        // Update UI to show error
        setState(() {
          _isSubmitting = false;
          
          // Show user-friendly error message based on the exception
          if (e.toString().contains('No human detected in the image')) {
            _validationMessage = 'No person detected in the image. Image has been automatically removed.';
            _validationStatus = ValidationStatus.noHuman;
            // Clear the image
            _imageFile = null;
            _webImage = null;
            tipData['image'] = '';
          } else {
            _validationMessage = 'Error: ${e.toString()}';
            _validationStatus = ValidationStatus.error;
          }
        });
        
        _scrollToValidationSection();
      }
    }
  }
  
  // Helper method to scroll to validation section
  void _scrollToValidationSection() {
    if (_validationSectionKey.currentContext != null) {
      Scrollable.ensureVisible(
        _validationSectionKey.currentContext!,
        duration: Duration(milliseconds: 500),
        alignment: 0.2,
      );
    }
  }
  
  // Method to try again with a different image
  void _tryDifferentImage() {
    setState(() {
      _imageFile = null;
      _webImage = null;
      _validationStatus = ValidationStatus.none;
      _validationMessage = '';
    });
    _showImageSourceOptions();
  }
  
  // Method to submit without image
  void _submitWithoutImage() {
    setState(() {
      _imageFile = null;
      _webImage = null;
      _validationStatus = ValidationStatus.none;
      _validationMessage = '';
    });
    _submitTip();
  }

  Widget _buildMapSection() {
    // Add debug prints to identify platform and location status
    print("Platform is web: ${kIsWeb}");
    print("Selected location: $selectedLocation");
    
    // Show a placeholder on web if there are issues with Google Maps
    if (kIsWeb) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader("Select Location on Map"),
          Container(
            height: 300,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
              color: Colors.grey.shade200,
            ),
            child: selectedLocation == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text("Loading map...", style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  )
                : Stack(
                    children: [
                      Center(
                        child: Text(
                          "Map View\n\nAddress: ${_addressController.text}",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: FloatingActionButton(
                          onPressed: _getCurrentLocation,
                          child: Icon(Icons.my_location),
                          backgroundColor: Color(0xFF0D47A1),
                        ),
                      ),
                    ],
                  ),
          ),
          SizedBox(height: 16),
          // Add address field below the map
          _buildTextField(
            _addressController,
            "Address",
            icon: Icons.location_on,
            maxLines: 2,
            enabled: false, // Make it read-only
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _getCurrentLocation,
                  icon: Icon(Icons.my_location),
                  label: Text("Use My Location"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF0D47A1),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    // Normal Google Maps implementation for mobile
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("Select Location on Map"),
        Container(
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: selectedLocation == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 8),
                        Text("Determining location...", 
                          style: TextStyle(color: Colors.black54)),
                      ],
                    ),
                  )
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: selectedLocation!,
                      zoom: 15,
                    ),
                    onMapCreated: (GoogleMapController controller) {
                      mapController = controller;
                    },
                    markers: markers,
                    myLocationButtonEnabled: true,
                    myLocationEnabled: true,                    onTap: (LatLng position) {
                      setState(() {
                        selectedLocation = position;
                        _updateMarkerAndControllers();
                        _getAddressFromCoordinates(); // Get address when map is tapped
                      });
                      // Check for nearby tips when a new location is tapped
                      _checkForNearbyTips();
                    },
                  ),
          ),
        ),
        SizedBox(height: 16),
        // Add address field below the map
        _buildTextField(
          _addressController,
          "Address",
          icon: Icons.location_on,
          maxLines: 2,
          enabled: false, // Make it read-only
        ),
        if (_isGettingAddress)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                SizedBox(
                  height: 12,
                  width: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text(
                  "Getting address...",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        if (_addressError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _addressError,
              style: TextStyle(
                color: Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _getCurrentLocation,
                icon: Icon(Icons.my_location),
                label: Text("Use My Location"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF0D47A1),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Report a Sighting",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        elevation: 0,
        backgroundColor: Color(0xFF0D47A1),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D47A1), Colors.blue.shade100],
            stops: [0.0, 50],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              controller: _scrollController, // Assign the scroll controller
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader("Sighting Details"),
                        _buildTextField(_dateLastSeenController, "Date Last Seen", icon: Icons.calendar_today),
                        SizedBox(height: 16), // Added extra spacing here
                        _buildTextField(_timeLastSeenController, "Time Last Seen", icon: Icons.access_time),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader("Physical Description"),
                        _buildDropdownField(
                          "Gender",
                          selectedGender,
                          genderOptions,
                          (value) => setState(() => selectedGender = value),
                          Icons.person_outline,
                        ),
                        // Add age range dropdown
                        _buildDropdownField(
                          "Age Range",
                          selectedAgeRange,
                          ageRanges,
                          (value) => setState(() => selectedAgeRange = value),
                          Icons.cake,
                        ),
                        // Replace height text field with dropdown
                        _buildDropdownField(
                          "Height Range",
                          selectedHeightRange,
                          heightRanges,
                          (value) => setState(() => selectedHeightRange = value),
                          Icons.height,
                        ),
                        _buildDropdownField(
                          "Hair Color",
                          selectedHairColor,
                          hairColors,
                          (value) => setState(() => selectedHairColor = value),
                          Icons.face,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader("Additional Details (Optional)"),
                        _buildTextField(_clothingController, "Clothing Description", required: false, icon: Icons.checkroom),
                        _buildTextField(_featuresController, "Distinguishing Features", required: false, icon: Icons.face_retouching_natural),
                        _buildTextField(_descriptionController, "Additional Description",
                            maxLines: 3, required: false, icon: Icons.description),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader("Photo Evidence"),
                        _buildImagePicker(),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildCard(
                    child: _buildMapSection(),
                  ),
                  // Add validation feedback UI below the maps
                  if (_validationStatus != ValidationStatus.none)
                    Padding(
                      padding: EdgeInsets.only(top: 16),
                      child: _buildCard(
                        child: _buildValidationFeedback(),
                      ),
                    ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitTip,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0D47A1),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 15),
                    ),
                    child: Text(
                      "Submit Sighting",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: const Color.fromARGB(255, 0, 0, 0),
        ),
      ),
    );
  }
  Widget _buildCard({required Widget child}) {
    return Card(
      elevation: 4,
      color: Colors.grey.shade200, // Light background color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: child,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool required = true,
    int maxLines = 1,
    IconData? icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true, // Add enabled parameter
  }) {
    List<TextInputFormatter>? formatters;
    // Get the field key
    final fieldKey = _fieldKeys[label.toLowerCase().replaceAll(' ', '')];

    // Set specific formatting and validation per field
    switch (label) {
      case "Date Last Seen":
        // Remove auto-initialization with current date
        return TextFormField(
          key: _fieldKeys['dateLastSeen'],
          controller: controller,
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontWeight: FontWeight.w600),
          decoration: _getInputDecoration(label, icon).copyWith(
            suffixIcon: IconButton(
              icon: Icon(Icons.calendar_today, color: Color(0xFF0D47A1)),
              onPressed: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000), // Allow dates from year 2000
                  lastDate: DateTime.now(), // Up to current date only
                );
                if (picked != null) {
                  controller.text = _dateFormatter.format(picked);
                }
              },
            ),
            hintText: 'YYYY-MM-DD',
          ),
          keyboardType: TextInputType.datetime,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter date';
            }
            
            // Try to parse the date
            try {
              final enteredDate = _dateFormatter.parse(value);
              final now = DateTime.now();
              
              // Check if date is in the future
              if (enteredDate.isAfter(DateTime(now.year, now.month, now.day))) {
                return 'Cannot enter future dates';
              }
              
              return null;
            } catch (e) {
              return 'Invalid date format (YYYY-MM-DD)';
            }
          },
          inputFormatters: [
            // Allow only digits and hyphens for date format
            FilteringTextInputFormatter.allow(RegExp(r'[\d-]')),
            // Format as YYYY-MM-DD
            LengthLimitingTextInputFormatter(10),
          ],
        );

      case "Time Last Seen":
        // Remove auto-initialization with current time
        return TextFormField(
          key: _fieldKeys['timeLastSeen'],
          controller: controller,
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontWeight: FontWeight.w600),
          decoration: _getInputDecoration(label, icon).copyWith(
            suffixIcon: IconButton(
              icon: Icon(Icons.access_time, color: Color(0xFF0D47A1)),
              onPressed: () async {
                final TimeOfDay? picked = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                  builder: (BuildContext context, Widget? child) {
                    return MediaQuery(
                      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                      child: child!,
                    );
                  },
                );
                if (picked != null) {
                  controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                }
              },
            ),
            hintText: 'HH:MM (24-hour format)',
          ),
          keyboardType: TextInputType.datetime,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter time';
            }
            
            // Check time format
            final timeRegex = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');
            if (!timeRegex.hasMatch(value)) {
              return 'Invalid time format (HH:MM)';
            }
            
            // If date is today, check if time is in the future
            final dateValue = _dateLastSeenController.text;
            try {
              final enteredDate = _dateFormatter.parse(dateValue);
              final now = DateTime.now();
              
              if (enteredDate.year == now.year && 
                  enteredDate.month == now.month && 
                  enteredDate.day == now.day) {
                
                // Parse the time
                final parts = value.split(':');
                final hour = int.parse(parts[0]);
                final minute = int.parse(parts[1]);
                
                // Check if time is in the future
                if (hour > now.hour || (hour == now.hour && minute > now.minute)) {
                  return 'Cannot enter future times for today';
                }
              }
              
              return null;
            } catch (e) {
              // If there's an error parsing the date, just validate the time format
              return null;
            }
          },
          inputFormatters: [
            // Allow only digits and colon for time format
            FilteringTextInputFormatter.allow(RegExp(r'[\d:]')),
            // Format as HH:MM
            LengthLimitingTextInputFormatter(5),
          ],
        );

      case "Clothing Description":
      case "Distinguishing Features":
      case "Additional Description":
        // Make these fields optional by setting custom validator that always returns null
        required = false;
        validator = (value) => null; // Optional field
        break;

      default:
        validator = (value) {
          if (required && (value == null || value.isEmpty)) {
            return 'Please enter $label';
          }
          return null;
        };
    }

    // Rest of the method remains the same
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: TextFormField(
        key: fieldKey, // Use generic key for other fields
        controller: controller,
        style: TextStyle(color: Colors.black87),
        decoration: _getInputDecoration(label, icon),
        inputFormatters: formatters,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        enabled: enabled, // Add this parameter to control editability
      ),
    );
  }

  InputDecoration _getInputDecoration(String label, IconData? icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.black54),
      prefixIcon: icon != null ? Icon(icon, color: Color(0xFF0D47A1)) : null,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Color(0xFF0D47A1), width: 2),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      // Add custom error styling
      errorStyle: TextStyle(
        color: Colors.red.shade800,  // Deeper red color
        fontWeight: FontWeight.bold, // Bold text for emphasis
        fontSize: 13.0,              // Slightly larger for visibility
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade700, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.red.shade700, width: 2),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
    IconData icon,
  ) {
    final fieldKey = _fieldKeys[label.toLowerCase().replaceAll(' ', '')];
    
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        key: fieldKey, // Assign key to dropdown field
        value: value,
        decoration: _getInputDecoration(label, icon),
        items: items.map((String item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Please select $label' : null,
        style: TextStyle(color: Colors.black87),
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildImagePicker() {
    return Center(
      child: (kIsWeb ? _webImage != null : _imageFile != null)
          ? Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb
                      ? Image.memory(
                          _webImage!,
                          height: 200,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          _imageFile!,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      onPressed: _showImageSourceOptions,
                      icon: Icon(Icons.edit, color: Color(0xFF0D47A1)),
                      label: Text('Change Image', style: TextStyle(color: Color(0xFF0D47A1))),
                    ),
                    SizedBox(width: 16),
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _imageFile = null;
                        _webImage = null;
                        tipData['image'] = '';
                      }),
                      icon: Icon(Icons.delete, color: Colors.red),
                      label: Text('Remove', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              ],
            )
          : InkWell(
              onTap: _showImageSourceOptions,
              child: Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 48, color: Color(0xFF0D47A1)),
                    SizedBox(height: 8),
                    Text(
                      'Add Photo',
                      style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Take a photo or select from gallery',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Add a method to show image source options
  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Select Image Source",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
            SizedBox(height: 16),
            if (!kIsWeb) // Show camera option only on mobile platforms
              ListTile(
                leading: Icon(Icons.camera_alt, color: Color(0xFF0D47A1)),
                title: Text(
                  "Take Photo",
                  style: TextStyle(
                    color: Color(0xFF0D47A1),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ListTile(
              leading: Icon(Icons.photo_library, color: Color(0xFF0D47A1)),
              title: Text(
                "Choose from Gallery",
                style: TextStyle(
                  color: Color(0xFF0D47A1),
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Build validation feedback UI section
  Widget _buildValidationFeedback() {
    return Container(
      key: _validationSectionKey,
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getValidationBorderColor(),
          width: 2,
        ),
        color: _getValidationBackgroundColor(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getValidationIcon(),
                color: _getValidationIconColor(),
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getValidationTitle(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _getValidationIconColor(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _validationMessage,
            style: TextStyle(fontSize: 14, color: Colors.black), // Changed text color to black
          ),
          if (_validationStatus == ValidationStatus.processing)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_getValidationIconColor()),
                ),
              ),
            ),
          if (_validationStatus == ValidationStatus.humanDetected)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                "Confidence score: $_validationConfidence%",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                  color: Colors.black, // Changed text color to black
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper methods for validation UI
  IconData _getValidationIcon() {
    switch (_validationStatus) {
      case ValidationStatus.processing:
        return Icons.hourglass_top;
      case ValidationStatus.error:
        return Icons.error_outline;
      case ValidationStatus.warning:
        return Icons.warning_amber;
      case ValidationStatus.noHuman:
        return Icons.person_off;
      case ValidationStatus.humanDetected:
        return Icons.person;
      case ValidationStatus.success:
        return Icons.check_circle_outline;
      default:
        return Icons.info_outline;
    }
  }

  Color _getValidationIconColor() {
    switch (_validationStatus) {
      case ValidationStatus.processing:
        return Colors.blue;
      case ValidationStatus.error:
        return Colors.red;
      case ValidationStatus.warning:
        return Colors.orange;
      case ValidationStatus.noHuman:
        return Colors.orange;
      case ValidationStatus.humanDetected:
        return Colors.green;
      case ValidationStatus.success:
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Color _getValidationBorderColor() {
    switch (_validationStatus) {
      case ValidationStatus.processing:
        return Colors.blue.shade300;
      case ValidationStatus.error:
        return Colors.red.shade300;
      case ValidationStatus.warning:
        return Colors.orange.shade300;
      case ValidationStatus.noHuman:
        return Colors.orange.shade300;
      case ValidationStatus.humanDetected:
        return Colors.green.shade300;
      case ValidationStatus.success:
        return Colors.green.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  Color _getValidationBackgroundColor() {
    switch (_validationStatus) {
      case ValidationStatus.processing:
        return Colors.blue.shade50;
      case ValidationStatus.error:
        return Colors.red.shade50;
      case ValidationStatus.warning:
        return Colors.orange.shade50;
      case ValidationStatus.noHuman:
        return Colors.orange.shade50;
      case ValidationStatus.humanDetected:
        return Colors.green.shade50;
      case ValidationStatus.success:
        return Colors.green.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  String _getValidationTitle() {
    switch (_validationStatus) {
      case ValidationStatus.processing:
        return "Processing...";
      case ValidationStatus.error:
        return "Error";
      case ValidationStatus.warning:
        return "Warning";
      case ValidationStatus.noHuman:
        return "No Person Detected";
      case ValidationStatus.humanDetected:
        return "Person Detected";
      case ValidationStatus.success:
        return "Success";
      default:
        return "Information";
    }
  }
  /// Check for existing tip for the same person within specified radius (matches SubmitReport.jsx logic)
  Future<bool> _hasDuplicateTipForPersonNearby(String personName, double lat, double lng, double radiusMeters) async {
    try {
      print("DEBUG: Querying reports collection for person: $personName");
      
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('reports')
          .where('name', isEqualTo: personName)
          .get();
      
      print("DEBUG: Found ${snapshot.docs.length} reports for person: $personName");
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        print("DEBUG: Checking report ${doc.id} with data: ${data['name']} at coordinates: ${data['coordinates']}");
        
        if (data.containsKey('coordinates')) {
          final coord = data['coordinates'];
          double? tipLat;
          double? tipLng;
          
          // Handle GeoPoint format (new format)
          if (coord is GeoPoint) {
            tipLat = coord.latitude;
            tipLng = coord.longitude;
          }
          // Handle legacy Map format
          else if (coord is Map) {
            tipLat = coord['lat'] is double ? coord['lat'] : double.tryParse(coord['lat'].toString());
            tipLng = coord['lng'] is double ? coord['lng'] : double.tryParse(coord['lng'].toString());
          }
          // Handle string format: "[lat° N, lng° E]" (old format)
          else if (coord is String) {
            final regex = RegExp(r'([\d.\-]+)°\s*N,\s*([\d.\-]+)°\s*E');
            final match = regex.firstMatch(coord);
            if (match != null) {
              tipLat = double.tryParse(match.group(1)!);
              tipLng = double.tryParse(match.group(2)!);
            }
          }
          
          if (tipLat != null && tipLng != null) {
            final double distance = _calculateDistance(lat, lng, tipLat, tipLng);
            print("DEBUG: Distance to report ${doc.id}: ${distance.toStringAsFixed(2)} meters");
              // This matches the React logic: same name AND within radius
            final bool nameMatch = data['name'].toString().toLowerCase() == personName.toLowerCase();
            final bool withinRadius = distance <= radiusMeters;
            final bool isDuplicate = withinRadius && nameMatch;
            
            print("DEBUG: Report ${doc.id} analysis:");
            print("  - Name in DB: '${data['name']}' vs Target: '$personName'");
            print("  - Name match: $nameMatch");
            print("  - Distance: ${distance.toStringAsFixed(2)}m <= ${radiusMeters}m = $withinRadius");
            print("  - isDuplicate: $isDuplicate");
            
            if (isDuplicate) {
              print("DEBUG: *** DUPLICATE FOUND! Blocking submission. ***");
              return true;
            }
          } else {
            print("DEBUG: Could not parse coordinates for report ${doc.id}");
          }
        } else {
          print("DEBUG: Report ${doc.id} has no coordinates");
        }
      }
      
      print("DEBUG: No duplicates found for $personName within ${radiusMeters}m");
      return false;
    } catch (e) {
      print('Error checking duplicate tip: $e');
      return false;
    }
  }

  // Helper method to calculate distance between two points using the Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    final double lat1Rad = lat1 * (3.141592653589793 / 180);
    final double lon1Rad = lon1 * (3.141592653589793 / 180);
    final double lat2Rad = lat2 * (3.141592653589793 / 180);
    final double lon2Rad = lon2 * (3.141592653589793 / 180);
    final double dLat = lat2Rad - lat1Rad;
    final double dLon = lon2Rad - lon1Rad;
    final double a = 
        (sin(dLat/2) * sin(dLat/2)) +
        (cos(lat1Rad) * cos(lat2Rad) * sin(dLon/2) * sin(dLon/2));
    final double c = 2 * atan2(sqrt(a), sqrt(1-a));
    return earthRadius * c;
  }

  // Add new method to check for nearby tips
  Future<void> _checkForNearbyTips() async {
    if (selectedLocation == null) return;
    
    setState(() {
      _isCheckingNearbyTips = true;
      _nearbyTips = [];
      _hasNearbyTips = false;
    });
    
    try {
      final TipService tipService = TipService();
      final nearbyTips = await tipService.findNearbyTips(
        selectedLocation!.latitude,
        selectedLocation!.longitude,
        _nearbyTipsRadius
      );
      
      setState(() {
        _isCheckingNearbyTips = false;
        _nearbyTips = nearbyTips;
        _hasNearbyTips = nearbyTips.isNotEmpty;
      });      // Debug logging only - no user notifications
      if (_hasNearbyTips) {
        final String personName = widget.person.name;
        int samePersonCount = 0;
        int otherPersonCount = 0;
        
        for (var tip in _nearbyTips) {
          if (tip['name']?.toString().toLowerCase() == personName.toLowerCase()) {
            samePersonCount++;
          } else {
            otherPersonCount++;
          }
        }
        
        // Debug logging only
        print("DEBUG: Nearby tips analysis for $personName:");
        print("  - Same person tips: $samePersonCount");
        print("  - Other person tips: $otherPersonCount");
      }
    } catch (e) {
      print('Error checking for nearby tips: $e');
      setState(() {
        _isCheckingNearbyTips = false;
      });
    }
  }
}