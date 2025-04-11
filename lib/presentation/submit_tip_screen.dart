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
import 'utils/modal_utils.dart'; // Import the new modal utils

class SubmitTipScreen extends StatefulWidget {
  final MissingPerson person;

  const SubmitTipScreen({Key? key, required this.person}) : super(key: key);

  @override
  _SubmitTipScreenState createState() => _SubmitTipScreenState();
}

class _SubmitTipScreenState extends State<SubmitTipScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController(); // Add scroll controller
  
  // Create a map to store keys for form fields
  final Map<String, GlobalKey<FormFieldState>> _fieldKeys = {
    'name': GlobalKey<FormFieldState>(),
    'phone': GlobalKey<FormFieldState>(),
    'dateLastSeen': GlobalKey<FormFieldState>(),
    'timeLastSeen': GlobalKey<FormFieldState>(),
    'gender': GlobalKey<FormFieldState>(),
    'age': GlobalKey<FormFieldState>(),
    'clothing': GlobalKey<FormFieldState>(),
    'features': GlobalKey<FormFieldState>(),
    'height': GlobalKey<FormFieldState>(),
    'hairColor': GlobalKey<FormFieldState>(),
    'eyeColor': GlobalKey<FormFieldState>(),
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

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dateLastSeenController = TextEditingController();
  final TextEditingController _timeLastSeenController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _clothingController = TextEditingController();
  final TextEditingController _featuresController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _hairColorController = TextEditingController();
  final TextEditingController _eyeColorController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _customEyeColorController = TextEditingController();
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
  String? selectedEyeColor;

  final List<String> genderOptions = ['Male', 'Female', 'Prefer not to say'];
  final List<String> hairColors = [
    'Black', 'Brown', 'Blonde', 'Red', 'Gray', 'White',
    'Dark Brown', 'Light Brown', 'Auburn', 'Strawberry Blonde'
  ];
  final List<String> eyeColors = [
    'Brown', 'Blue', 'Green', 'Hazel', 'Gray',
    'Amber', 'Black', 'Other'
  ];

  Map<String, String> tipData = {
    'name': '',
    'phone': '',
    'dateLastSeen': '',
    'timeLastSeen': '',
    'gender': '',
    'age': '',
    'clothing': '',
    'features': '',
    'height': '',
    'hairColor': '',
    'eyeColor': '',
    'description': '',
    'image': '',
    'longitude': '',
    'latitude': '',
    'userId': '',
  };

  GoogleMapController? mapController;
  Set<Marker> markers = {};
  LatLng? selectedLocation;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    
    // Check if user has already accepted the privacy policy
    checkPrivacyPolicyAcceptance();
  }
  
  // Method to check privacy policy acceptance
  Future<void> checkPrivacyPolicyAcceptance() async {
    setState(() {
      isCheckingPrivacyStatus = true;
    });
    
    try {
      bool accepted = await ModalUtils.checkPrivacyPolicyAcceptance(
        screenType: ModalUtils.SCREEN_SUBMIT_TIP
      );
      
      setState(() {
        hasAcceptedPrivacyPolicy = accepted;
      });
      
      if (!accepted) {
        // Show legal disclaimer followed by privacy policy
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showCompliance();
        });
      }
    } catch (e) {
      print('Error checking privacy policy acceptance: $e');
    } finally {
      setState(() {
        isCheckingPrivacyStatus = false;
      });
    }
  }
  
  // Method to show both modals in sequence
  void showCompliance() {
    ModalUtils.showLegalDisclaimerModal(
      context,
      onAccept: () {
        // Show privacy policy after legal disclaimer is accepted
        ModalUtils.showPrivacyPolicyModal(
          context,
          screenType: ModalUtils.SCREEN_SUBMIT_TIP,
          onAcceptanceUpdate: (accepted) {
            setState(() {
              hasAcceptedPrivacyPolicy = accepted;
            });
            
            // If user disagrees, navigate back
            if (!accepted) {
              Navigator.of(context).pop();
            }
          },
          onCancel: () {
            // Navigate back if user cancels
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
          }

          // Get address when location is updated
          _getAddressFromCoordinates();
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

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return 'Please enter phone number';
    if (value.length != 11) return 'Phone number must be 11 digits';
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Only numbers are allowed';
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) return 'Please enter name';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) return 'Only letters are allowed';
    return null;
  }

  String? _validateAge(String? value) {
    if (value == null || value.isEmpty) return 'Please enter age';
    int? age = int.tryParse(value);
    if (age == null) return 'Please enter a valid number';
    if (age < 0 || age > 120) return 'Please enter a valid age (0-120)';
    return null;
  }

  String? _validateHeight(String? value) {
    if (value == null || value.isEmpty) return 'Please enter height';
    
    // Accept various height formats
    
    // Format: feet and inches (5'7, 5 7, 5ft 7in, etc.)
    RegExp feetInchesRegex = RegExp(r"^(\d{1,2})(?:'|\s|ft\.?\s*)(?:(\d{1,2})(?:''|\s|in\.?)?)?$");
    
    // Format: centimeters (170cm, 170 cm)
    RegExp centimeterRegex = RegExp(r"^(\d{2,3})(?:\s*cm)?$");
    
    // Format: meters (1.7m, 1.7 m)
    RegExp meterRegex = RegExp(r"^(\d{1})\.(\d{1,2})(?:\s*m)?$");
    
    if (feetInchesRegex.hasMatch(value)) {
      // Extract feet and inches
      Match match = feetInchesRegex.firstMatch(value)!;
      int? feet = int.tryParse(match.group(1) ?? '0');
      int? inches = int.tryParse(match.group(2) ?? '0');
      
      // Validate feet is reasonable (2-8 feet)
      if (feet! < 2 || feet > 8) 
        return 'Please enter a valid height (2-8 feet)';
      
      // If inches provided, validate (0-11 inches)
      if (inches != null && inches > 0 && (inches < 0 || inches > 11))
        return 'Inches must be between 0 and 11';
      
      return null;
    }
    
    // Check centimeter format
    if (centimeterRegex.hasMatch(value)) {
      int? cm = int.tryParse(centimeterRegex.firstMatch(value)!.group(1) ?? '0');
      
      // Validate reasonable height range (60cm-250cm)
      if (cm! < 60 || cm > 250)
        return 'Please enter a valid height (60-250 cm)';
        
      return null;
    }
    
    // Check meter format
    if (meterRegex.hasMatch(value)) {
      Match match = meterRegex.firstMatch(value)!;
      double meters = double.tryParse('${match.group(1)}.${match.group(2)}') ?? 0;
      
      // Validate reasonable height range (0.6m-2.5m)
      if (meters < 0.6 || meters > 2.5)
        return 'Please enter a valid height (0.6-2.5 meters)';
        
      return null;
    }
    
    // If it doesn't match any acceptable format
    return 'Enter height as feet\'inches (5\'7), centimeters (170cm), or meters (1.7m)';
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

  /// Enhanced image picker with better permission handling
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
        if (kIsWeb) {
          // Handle web platform
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImage = bytes;
            tipData['image'] = base64Encode(bytes); // Store as base64 for web
          });
        } else {
          // Handle mobile platforms
          setState(() {
            _imageFile = File(pickedFile.path);
            tipData['image'] = pickedFile.path;
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
        } else if (selectedHairColor == null) {
          firstErrorKey = _fieldKeys['hairColor'];
        } else if (selectedEyeColor == null || 
                 (selectedEyeColor == 'Other' && _customEyeColorController.text.isEmpty)) {
          firstErrorKey = _fieldKeys['eyeColor'];
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
    }

    if (_formKey.currentState?.validate() ?? false) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return Center(
              child: CircularProgressIndicator(),
            );
          },
        );

        final TipService tipService = TipService();
        
        // Get current user ID - ensure this is never null at this point
        String userId = _auth.currentUser!.uid;
        
        print("Submitting tip with userId: $userId");
        
        // Submit tip with the new field structure
        await tipService.submitTip(
          name: _nameController.text,
          phone: _phoneController.text,
          dateLastSeen: _dateLastSeenController.text,
          timeLastSeen: _timeLastSeenController.text,
          gender: selectedGender ?? '',
          age: _ageController.text,
          height: _heightController.text,
          hairColor: selectedHairColor ?? '',
          eyeColor: selectedEyeColor == 'Other' 
              ? _customEyeColorController.text 
              : (selectedEyeColor ?? ''),
          clothing: _clothingController.text,
          features: _featuresController.text,
          description: _descriptionController.text,
          lat: double.parse(_latitudeController.text),
          lng: double.parse(_longitudeController.text),
          userId: userId,
          address: _addressController.text, // Add address to the tip submission
        );

        // Remove loading indicator
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tip submitted successfully!')),
        );
        
        // Navigate back to the missing person screen
        Navigator.pushReplacementNamed(context, AppRoutes.missingPerson);

        // Clear form fields (these will only execute if navigation fails or is delayed)
        _formKey.currentState?.reset();
        _nameController.clear();
        _phoneController.clear();
        _dateLastSeenController.clear();
        _timeLastSeenController.clear();
        _genderController.clear();
        _ageController.clear();
        _clothingController.clear();
        _featuresController.clear();
        _heightController.clear();
        _hairColorController.clear();
        _eyeColorController.clear();
        _descriptionController.clear();
        _customEyeColorController.clear();
        _longitudeController.clear();
        _latitudeController.clear();
        _coordinatesController.clear();
        setState(() {
          _imageFile = null;
          _webImage = null;
        });
      } catch (e) {
        // Remove loading indicator
        Navigator.pop(context);
        
        print('Error saving tip: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
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
                    myLocationEnabled: true,
                    onTap: (LatLng position) {
                      setState(() {
                        selectedLocation = position;
                        _updateMarkerAndControllers();
                        _getAddressFromCoordinates(); // Get address when map is tapped
                      });
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
          "Submit Report",
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
                        _buildSectionHeader("Contact Information"),
                        _buildTextField(_nameController, "Name", icon: Icons.person),
                        _buildTextField(_phoneController, "Phone", icon: Icons.phone),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
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
                        _buildTextField(_ageController, "Age", icon: Icons.cake),
                        _buildTextField(_heightController, "Height", icon: Icons.height),
                        _buildDropdownField(
                          "Hair Color",
                          selectedHairColor,
                          hairColors,
                          (value) => setState(() => selectedHairColor = value),
                          Icons.face,
                        ),
                        _buildEyeColorField(),
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
                  SizedBox(height: 16),
                  _buildCard(
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
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submitTip,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 15),
                      child: Text(
                        "SUBMIT TIP",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(100, 0, 39, 76),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
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
      color: const Color.fromARGB(255, 218, 218, 218), // Add light background color
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
      case "Phone":
        formatters = [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(11),
        ];
        validator = _validatePhone;
        keyboardType = TextInputType.phone;
        break;

      case "Name":
        formatters = [
          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
        ];
        validator = _validateName;
        keyboardType = TextInputType.name;
        break;

      case "Date Last Seen":
        controller.text = controller.text.isEmpty ? 
          _dateFormatter.format(DateTime.now()) : controller.text;
        return InkWell(
          onTap: () async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now().subtract(Duration(days: 365)),
              lastDate: DateTime.now(),
            );
            if (picked != null) {
              controller.text = _dateFormatter.format(picked);
            }
          },
          child: IgnorePointer(
            child: TextFormField(
              key: _fieldKeys['dateLastSeen'], // Assign key to field
              controller: controller,
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontWeight: FontWeight.w600), // Updated text style
              decoration: _getInputDecoration(label, icon),
              validator: (value) => value?.isEmpty ?? true ? 'Please select date' : null,
            ),
          ),
        );

      case "Time Last Seen":
        controller.text = controller.text.isEmpty ? 
          _timeFormatter.format(DateTime.now()) : controller.text;
        return InkWell(
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (picked != null) {
              controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
            }
          },
          child: IgnorePointer(
            child: TextFormField(
              key: _fieldKeys['timeLastSeen'], // Assign key to field
              controller: controller,
              style: TextStyle(color: Color.fromARGB(255, 0, 0, 0), fontWeight: FontWeight.w600), // Updated text style
              decoration: _getInputDecoration(label, icon),
              validator: (value) => value?.isEmpty ?? true ? 'Please select time' : null,
            ),
          ),
        );

      case "Age":
        formatters = [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ];
        validator = _validateAge;
        keyboardType = TextInputType.number;
        break;

      case "Height":
        formatters = [
          // Updated formatter to only allow numbers, apostrophes, periods, and spaces
          FilteringTextInputFormatter.allow(RegExp(r"[0-9.' ]")),
          LengthLimitingTextInputFormatter(10),
        ];
        validator = _validateHeight;
        keyboardType = TextInputType.text;
        return Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: TextFormField(
            key: _fieldKeys['height'], // Assign key to field
            controller: controller,
            style: TextStyle(color: Colors.black87),
            decoration: _getInputDecoration(label, icon).copyWith(
              hintText: "e.g. 5'7, 170, or 1.7", 
              helperText: "Formats: feet'inches (5'7), centimeters (170), meters (1.7)",
              helperStyle: TextStyle(
                color: Colors.black54, 
                fontSize: 12,
                overflow: TextOverflow.ellipsis, // Add text overflow handling
              ),
              helperMaxLines: 2, // Allow helper text to take up to 2 lines before truncating
            ),
            inputFormatters: formatters,
            validator: validator,
            keyboardType: keyboardType,
          ),
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

  Widget _buildEyeColorField() {
    return Column(
      children: [
        _buildDropdownField(
          "Eye Color",
          selectedEyeColor,
          eyeColors,
          (value) => setState(() => selectedEyeColor = value),
          Icons.remove_red_eye,
        ),
        if (selectedEyeColor == 'Other')
          Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: TextFormField(
              key: _fieldKeys['eyeColor'], // Assign key to field
              controller: _customEyeColorController,
              decoration: _getInputDecoration("Specify Eye Color", Icons.remove_red_eye),
              validator: (value) => 
                value?.isEmpty ?? true ? 'Please specify eye color' : null,
              style: TextStyle(color: Colors.black87),
            ),
          ),
      ],
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
}