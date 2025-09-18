import '/core/app_export.dart';
import 'package:philippines_rpcmb/philippines_rpcmb.dart';
import 'package:intl/intl.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'dart:ui'; // Added import for ImageFilter
import 'dart:convert';
import 'package:crypto/crypto.dart';

class FillUpFormScreen extends StatefulWidget {
  const FillUpFormScreen({Key? key}) : super(key: key);
  @override
  FillUpForm createState() => FillUpForm();
}

// Add ValidationStatus enum for image validation
enum ValidationStatus {
  none,
  processing,
  error,
  warning,
  noHuman,
  humanDetected,
  success
}

class FillUpForm extends State<FillUpFormScreen> {
  bool hasOtherAddressReporting = false;
  bool hasOtherAddressVictim = false;
  bool isSubmitting = false;
  bool hasAcceptedPrivacyPolicy = false;
  bool isCheckingPrivacyStatus = true;
  
  // Add for copying address from reporting to victim
  bool sameAddressAsReporting = false;
  
  // Image handling variables
  File? _imageFile;
  Uint8List? _webImage;
  String? _selectedImageHash;
  final picker = ImagePicker();
  ValidationStatus _validationStatus = ValidationStatus.none;
  String _validationMessage = '';
  String _validationConfidence = '0.0';
  bool _isProcessingImage = false;
  
  // Add a ScrollController for the form
  final ScrollController _scrollController = ScrollController();
  // Map to hold GlobalKeys for required fields
  final Map<String, GlobalKey> _requiredFieldKeys = {};
  // Helper to register a key for a required field
  GlobalKey _getOrCreateKey(String label) {
    if (!_requiredFieldKeys.containsKey(label)) {
      _requiredFieldKeys[label] = GlobalKey();
    }
    return _requiredFieldKeys[label]!;
  }

  // Auto scroll to first invalid field
  Future<void> _scrollToFirstInvalidField() async {
    // List of required field controllers and their labels for scrolling
    final List<Map<String, dynamic>> requiredFields = [
      {'controller': _surnameReportingController, 'label': 'Reporting Person Surname'},
      {'controller': _firstNameReportingController, 'label': 'Reporting Person First Name'},
      {'controller': _middleNameReportingController, 'label': 'Reporting Person Middle Name'},
      {'controller': _citizenshipReportingController, 'label': 'Reporting Person Citizenship'},
      {'controller': _sexGenderReportingController, 'label': 'Reporting Person Gender'},
      {'controller': _civilStatusReportingController, 'label': 'Reporting Person Civil Status'},
      {'controller': _dateOfBirthReportingController, 'label': 'Reporting Person Date of Birth'},
      {'controller': _ageReportingController, 'label': 'Reporting Person Age'},
      {'controller': _placeOfBirthReportingController, 'label': 'Reporting Person Place of Birth'},
      {'controller': _mobilePhoneReportingController, 'label': 'Reporting Person Mobile Phone'},
      {'controller': _currentAddressReportingController, 'label': 'Reporting Person Current Address'},
      {'controller': _educationReportingController, 'label': 'Reporting Person Education'},
      {'controller': _occupationReportingController, 'label': 'Reporting Person Occupation'},
      {'controller': _emailReportingController, 'label': 'Reporting Person Email'},
      {'controller': _surnameVictimController, 'label': 'Missing Person Surname'},
      {'controller': _firstNameVictimController, 'label': 'Missing Person First Name'},
      {'controller': _middleNameVictimController, 'label': 'Missing Person Middle Name'},
      {'controller': _citizenshipVictimController, 'label': 'Missing Person Citizenship'},
      {'controller': _sexGenderVictimController, 'label': 'Missing Person Gender'},
      {'controller': _civilStatusVictimController, 'label': 'Missing Person Civil Status'},
      {'controller': _dateOfBirthVictimController, 'label': 'Missing Person Date of Birth'},
      {'controller': _ageVictimController, 'label': 'Missing Person Age'},
      {'controller': _placeOfBirthVictimController, 'label': 'Missing Person Place of Birth'},
      {'controller': _currentAddressVictimController, 'label': 'Missing Person Current Address'},
      {'controller': _educationVictimController, 'label': 'Missing Person Education'},
      {'controller': _occupationVictimController, 'label': 'Missing Person Occupation'},
      {'controller': _dateTimeIncidentController, 'label': 'Date and Time of Incident'},
      {'controller': _placeOfIncidentController, 'label': 'Place of Incident'},
      {'controller': _narrativeController, 'label': 'Narrative'},
    ];

    // Find the first empty required field
    for (final field in requiredFields) {
      final TextEditingController controller = field['controller'];
      final String label = field['label'];
      
      if (controller.text.trim().isEmpty) {
        // Get or create a key for this field
        final GlobalKey fieldKey = _getOrCreateKey(label);
        
        // Try to find the widget and scroll to it
        if (fieldKey.currentContext != null) {
          await Scrollable.ensureVisible(
            fieldKey.currentContext!,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            alignment: 0.1, // Show field near top of screen
          );
          break;
        }
      }
    }
    
    // If no specific field found, check for dropdown validation errors
    if (_educationReportingController.text.isEmpty || _educationVictimController.text.isEmpty) {
      final GlobalKey educationKey = _getOrCreateKey('Education Fields');
      if (educationKey.currentContext != null) {
        await Scrollable.ensureVisible(
          educationKey.currentContext!,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          alignment: 0.1,
        );
      }
    }
  }

  // Show image source selection dialog
  void _showImageSourceOptions() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with icon and title
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFF2A5298).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.add_photo_alternate,
                          color: Color(0xFF2A5298),
                          size: 28,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Select Image Source',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2A5298),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Choose how to upload your photo',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  
                  // Gallery option
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickImage(ImageSource.gallery);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Color(0xFF53C0FF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.photo_library_rounded,
                                color: Color(0xFF53C0FF),
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Choose from Gallery',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF424242),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Select an existing photo',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey.shade400,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 12),
                  
                  // Camera option
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).pop();
                        _pickImage(ImageSource.camera);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey.shade50,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Color(0xFF53C0FF).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                color: Color(0xFF53C0FF),
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Take a Photo',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF424242),
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Use your camera to capture',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.grey.shade400,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 20),
                  
                  // Cancel button
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  // Show dialog to ask if user wants to save reporting person data
  Future<void> _showSaveReportingPersonDataDialog() async {
    // Check if user already has saved data
    bool hasSavedData = await _irfService.hasSavedReportingPersonData();
    
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 16,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 40,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with gradient background
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF2A5298),
                        Color(0xFF4B89DC),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF2A5298).withOpacity(0.3),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    hasSavedData ? Icons.update_rounded : Icons.bookmark_add_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  hasSavedData ? 'Update Saved Information?' : 'Save Your Information?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Container(
                  width: 60,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF2A5298),
                        Color(0xFF4B89DC),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  hasSavedData 
                    ? 'Would you like to update your saved reporting person information with the details from this form? This will make future form submissions faster.'
                    : 'Would you like to save your reporting person information for future forms? This will automatically fill in your details next time, making reporting faster and easier.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Not Now',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF2A5298),
                              Color(0xFF4B89DC),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF2A5298).withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _saveReportingPersonData();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                hasSavedData ? Icons.update_rounded : Icons.save_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                hasSavedData ? 'Update' : 'Save',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Save reporting person data to Firebase
  Future<void> _saveReportingPersonData() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFF2A5298),
                        Color(0xFF4B89DC),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Saving Information...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please wait while we save your data',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      // Collect reporting person data from form
      Map<String, dynamic> reportingPersonData = {
        'surname': _surnameReportingController.text,
        'firstName': _firstNameReportingController.text,
        'middleName': _middleNameReportingController.text,
        'qualifier': _qualifierReportingController.text,
        'nickname': _nicknameReportingController.text,
        'citizenship': _citizenshipReportingController.text,
        'sexGender': _sexGenderReportingController.text,
        'civilStatus': _civilStatusReportingController.text,
        'dateOfBirth': _dateOfBirthReportingController.text,
        'age': _ageReportingController.text,
        'placeOfBirth': _placeOfBirthReportingController.text,
        'homePhone': _homePhoneReportingController.text,
        'mobilePhone': _mobilePhoneReportingController.text,
        'currentAddress': _currentAddressReportingController.text,
        'villageSitio': _villageSitioReportingController.text,
        'education': _educationReportingController.text,
        'occupation': _occupationReportingController.text,
        'idCardPresented': _idCardPresentedController.text,
        'email': _emailReportingController.text,
        // Address location data
        'regionName': reportingPersonRegion?.regionName,
        'provinceName': reportingPersonProvince?.name,
        'municipalityName': reportingPersonMunicipality?.name,
        'barangay': reportingPersonBarangay,
        // Date components for proper restoration
        'selectedDay': selectedDayReporting,
        'selectedMonth': selectedMonthReporting,
        'selectedYear': selectedYearReporting,
        // Other address data if applicable
        'hasOtherAddress': hasOtherAddressReporting,
        'otherRegionName': hasOtherAddressReporting ? reportingPersonOtherRegion?.regionName : null,
        'otherProvinceName': hasOtherAddressReporting ? reportingPersonOtherProvince?.name : null,
        'otherMunicipalityName': hasOtherAddressReporting ? reportingPersonOtherMunicipality?.name : null,
        'otherBarangay': hasOtherAddressReporting ? reportingPersonOtherBarangay : null,
      };

      // Check if data already exists and update accordingly
      bool hasSavedData = await _irfService.hasSavedReportingPersonData();
      bool success;
      
      if (hasSavedData) {
        success = await _irfService.updateSavedReportingPersonData(reportingPersonData);
      } else {
        success = await _irfService.saveReportingPersonData(reportingPersonData);
      }

      // Close loading dialog
      Navigator.of(context).pop();

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.check_circle, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hasSavedData ? 'Information updated successfully!' : 'Information saved successfully!',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to save information. Please try again.'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      print('Error saving reporting person data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Error saving information: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
  
  // Show dialog to confirm clearing saved reporting person data
  Future<void> _showClearSavedDataDialog() async {
    // First check if user has saved data
    bool hasSavedData = await _irfService.hasSavedReportingPersonData();
    
    if (!hasSavedData) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('No saved reporting person data found.'),
            ],
          ),
          backgroundColor: Colors.orange.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 16,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.red.withOpacity(0.1),
                  blurRadius: 40,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning icon with animated background
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade400,
                        Colors.red.shade600,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Clear Saved Information?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Container(
                  width: 60,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade400,
                        Colors.red.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'This action cannot be undone',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Are you sure you want to permanently delete your saved reporting person information? You will need to re-enter all details in future forms.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.red.shade500,
                              Colors.red.shade700,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _clearSavedReportingPersonData();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_forever_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Clear saved reporting person data
  Future<void> _clearSavedReportingPersonData() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.shade400,
                        Colors.red.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Clearing Information...',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please wait while we delete your data',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    try {
      bool success = await _irfService.clearSavedReportingPersonData();
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.check_circle, color: Colors.white, size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  'Saved information cleared successfully!',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('Failed to clear saved information. Please try again.'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      print('Error clearing saved reporting person data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Error clearing information: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // Load saved reporting person data into the form
  Future<void> _loadSavedReportingPersonData() async {
    try {
      Map<String, dynamic>? savedData = await _irfService.getSavedReportingPersonData();
      
      if (savedData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white),
                SizedBox(width: 8),
                Text('No saved reporting person data found.'),
              ],
            ),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        return;
      }

      // Show confirmation dialog before overwriting current data
      bool shouldLoad = await _showLoadSavedDataConfirmationDialog();
      if (!shouldLoad) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade400,
                          Colors.blue.shade600,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Loading Information...',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Please wait while we load your saved data',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Simulate loading delay for better UX
      await Future.delayed(Duration(milliseconds: 500));

      setState(() {
        _surnameReportingController.text = savedData['surname'] ?? '';
        _firstNameReportingController.text = savedData['firstName'] ?? '';
        _middleNameReportingController.text = savedData['middleName'] ?? '';
        _qualifierReportingController.text = savedData['qualifier'] ?? '';
        _nicknameReportingController.text = savedData['nickname'] ?? '';
        _citizenshipReportingController.text = savedData['citizenship'] ?? '';
        _sexGenderReportingController.text = savedData['sexGender'] ?? '';
        _civilStatusReportingController.text = savedData['civilStatus'] ?? '';
        _dateOfBirthReportingController.text = savedData['dateOfBirth'] ?? '';
        _ageReportingController.text = savedData['age'] ?? '';
        _placeOfBirthReportingController.text = savedData['placeOfBirth'] ?? '';
        _homePhoneReportingController.text = savedData['homePhone'] ?? '';
        _mobilePhoneReportingController.text = savedData['mobilePhone'] ?? '';
        _currentAddressReportingController.text = savedData['currentAddress'] ?? '';
        _villageSitioReportingController.text = savedData['villageSitio'] ?? '';
        _educationReportingController.text = savedData['education'] ?? '';
        _occupationReportingController.text = savedData['occupation'] ?? '';
        _idCardPresentedController.text = savedData['idCardPresented'] ?? '';
        _emailReportingController.text = savedData['email'] ?? '';
        
        // Restore date components
        selectedDayReporting = savedData['selectedDay'];
        selectedMonthReporting = savedData['selectedMonth'];
        selectedYearReporting = savedData['selectedYear'];
        
        // Restore address selection state
        hasOtherAddressReporting = savedData['hasOtherAddress'] ?? false;
      });

      _restoreLocationData(savedData);
      updateFormState();

      // Close loading dialog
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.check_circle, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Text(
                'Saved information loaded successfully!',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Close loading dialog if it's open
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      
      print('Error loading saved reporting person data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('Error loading saved information: $e')),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // Show confirmation dialog before loading saved data
  Future<bool> _showLoadSavedDataConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 16,
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 40,
                  offset: Offset(0, 16),
                ),
              ],
            ),
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with gradient background
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.cloud_download_rounded,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Load Saved Information?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 12),
                Container(
                  width: 60,
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.shade400,
                        Colors.blue.shade600,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Current form data will be replaced',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'This will replace any information currently filled in the reporting person section with your saved data. Are you sure you want to continue?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 1.5,
                          ),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(false);
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade500,
                              Colors.blue.shade700,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop(true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: const Color.fromARGB(0, 255, 255, 255),
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.download_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Load Data',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ) ?? false; // Return false if dialog is dismissed
  }
  
  // Calculate SHA-256 hash of image bytes
  String _calculateImageHash(Uint8List imageBytes) {
    var digest = sha256.convert(imageBytes);
    return digest.toString();
  }

  // Check if image hash already exists in Firebase
  Future<bool> _checkDuplicateImageHash(String imageHash) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('imageHashes')
          .where('hash', isEqualTo: imageHash)
          .limit(1)
          .get();
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking duplicate image hash: $e');
      return false;
    }
  }

  // Generate organized document ID for imageHashes collection
  Future<String> _generateImageHashDocId() async {
    final today = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(today);
    final idPrefix = 'IMG-$dateStr-';

    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('imageHashes')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: idPrefix + '0001')
          .where(FieldPath.documentId, isLessThanOrEqualTo: idPrefix + '9999')
          .get();

      int highestNumber = 0;
      for (final doc in querySnapshot.docs) {
        final String docId = doc.id;
        if (docId.startsWith(idPrefix) && docId.length > idPrefix.length) {
          final String suffix = docId.substring(idPrefix.length);
          final int? num = int.tryParse(suffix);
          if (num != null && num > highestNumber) highestNumber = num;
        }
      }

      final int nextNumber = highestNumber + 1;
      final String padded = nextNumber.toString().padLeft(4, '0');
      return '$idPrefix$padded';
    } catch (e) {
      // fallback
      return 'IMG-${DateFormat('yyyyMMdd').format(DateTime.now())}-0001';
    }
  }

  // Store image hash in Firebase using organized document ID and without userId
  Future<void> _storeImageHash(String imageHash, {String? irfId}) async {
    try {
      final docId = await _generateImageHashDocId();
      final Map<String, dynamic> data = {
        'hash': imageHash,
        'createdAt': FieldValue.serverTimestamp(),
      };
      if (irfId != null) {
        data['irfId'] = irfId;
      }
      await FirebaseFirestore.instance.collection('imageHashes').doc(docId).set(data);
    } catch (e) {
      print('Error storing image hash: $e');
    }
  }

  // Image picking and validation
  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isProcessingImage = true);
      
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        Uint8List imageBytes;
        
        // Get image bytes first
        if (kIsWeb) {
          imageBytes = await pickedFile.readAsBytes();
        } else {
          imageBytes = await File(pickedFile.path).readAsBytes();
        }
        
        // Calculate SHA-256 hash
        String imageHash = _calculateImageHash(imageBytes);
        // Check for duplicate hash in the database and block immediately if found
        bool isDuplicate = await _checkDuplicateImageHash(imageHash);
        if (isDuplicate) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('This image has already been uploaded previously. Please use a different image.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
          return;
        }
        // Keep selected image hash in memory; do not store it yet. It will be stored on successful form submission.
        _selectedImageHash = imageHash;
        
        // Set image data for display
        dynamic imageData;
        if (kIsWeb) {
          imageData = imageBytes;
          setState(() => _webImage = imageBytes);
        } else {
          final file = File(pickedFile.path);
          imageData = file;
          setState(() => _imageFile = file);
        }
        
        // Validate image using Google Vision service
        try {
          final validationResult = await _irfService.validateImageWithGoogleVision(imageData);
          
          setState(() {
            if (!validationResult['isValid']) {
              _validationMessage = 'Error validating image: ${validationResult['message']}';
              _validationStatus = ValidationStatus.error;
              // Clear image on validation error
              _imageFile = null;
              _webImage = null;
              _selectedImageHash = null;
            } else if (!validationResult['containsHuman']) {
              _imageFile = null;
              _webImage = null;
              _validationMessage = validationResult['message'] ?? 'No person detected in the image. Image has been removed.';
              _validationConfidence = (validationResult['confidence'] * 100).toStringAsFixed(1);
              _validationStatus = ValidationStatus.noHuman;
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Image removed - no reliable human detection (${_validationConfidence}% confidence)'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 4),
                ),
              );
            } else {
              _validationMessage = validationResult['message'] ?? 'Person detected in image!';
              _validationConfidence = (validationResult['confidence'] * 100).toStringAsFixed(1);
              _validationStatus = ValidationStatus.humanDetected;
              
              // Note: do NOT store the image hash here. It will be stored when the IRF form is submitted.
              // Keep the computed hash in memory so submit can perform duplicate-check and store it organized.
              _selectedImageHash = imageHash;
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Image uploaded and validated successfully! (${_validationConfidence}% confidence)'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          });
        } catch (e) {
          setState(() {
            _validationMessage = 'Image validation error: ${e.toString()}';
            _validationStatus = ValidationStatus.warning;
            // Clear image on validation error
            _imageFile = null;
            _webImage = null;
              _selectedImageHash = null;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error validating image: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accessing image: ${e.toString()}')),
      );
    } finally {
      setState(() => _isProcessingImage = false);
    }
  }

  // Helper methods for validation status display
  Color _getValidationStatusColor() {
    switch (_validationStatus) {
      case ValidationStatus.processing:
        return Colors.blue;
      case ValidationStatus.humanDetected:
      case ValidationStatus.success:
        return Colors.green;
      case ValidationStatus.noHuman:
        return Colors.orange;
      case ValidationStatus.error:
        return Colors.red;
      case ValidationStatus.warning:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getValidationStatusIcon() {
    switch (_validationStatus) {
      case ValidationStatus.processing:
        return Icons.hourglass_empty;
      case ValidationStatus.humanDetected:
      case ValidationStatus.success:
        return Icons.check_circle;
      case ValidationStatus.noHuman:
        return Icons.warning;
      case ValidationStatus.error:
        return Icons.error;
      case ValidationStatus.warning:
        return Icons.warning_amber;
      default:
        return Icons.info;
    }
  }

  String _getValidationStatusText() {
    switch (_validationStatus) {
      case ValidationStatus.processing:
        return 'Validating image...';
      case ValidationStatus.humanDetected:
        return 'Person detected ($_validationConfidence% confidence)';
      case ValidationStatus.success:
        return 'Image validated successfully';
      case ValidationStatus.noHuman:
        return 'No person detected';
      case ValidationStatus.error:
        return 'Validation error';
      case ValidationStatus.warning:
        return 'Validation warning';
      default:
        return 'Unknown status';
    }
  }
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Service for Firebase operations
  final IRFService _irfService = IRFService();
    // General information controllers (moved to narrative section)
  final TextEditingController _typeOfIncidentController = TextEditingController();
  final TextEditingController _dateTimeIncidentController = TextEditingController();
  final TextEditingController _placeOfIncidentController = TextEditingController();
  
  // ITEM A - Reporting Person controllers
  final TextEditingController _surnameReportingController = TextEditingController();
  final TextEditingController _firstNameReportingController = TextEditingController();
  final TextEditingController _middleNameReportingController = TextEditingController();
  final TextEditingController _qualifierReportingController = TextEditingController();
  final TextEditingController _nicknameReportingController = TextEditingController();
  final TextEditingController _citizenshipReportingController = TextEditingController();
  final TextEditingController _sexGenderReportingController = TextEditingController();
  final TextEditingController _civilStatusReportingController = TextEditingController();
  final TextEditingController _dateOfBirthReportingController = TextEditingController();
  final TextEditingController _ageReportingController = TextEditingController();
  final TextEditingController _placeOfBirthReportingController = TextEditingController();
  final TextEditingController _homePhoneReportingController = TextEditingController();
  final TextEditingController _mobilePhoneReportingController = TextEditingController();
  final TextEditingController _currentAddressReportingController = TextEditingController();
  final TextEditingController _villageSitioReportingController = TextEditingController();
  final TextEditingController _educationReportingController = TextEditingController();
  final TextEditingController _occupationReportingController = TextEditingController();
  final TextEditingController _idCardPresentedController = TextEditingController();
  final TextEditingController _emailReportingController = TextEditingController();
  
  // ITEM C - Victim controllers
  final TextEditingController _surnameVictimController = TextEditingController();
  final TextEditingController _firstNameVictimController = TextEditingController();
  final TextEditingController _middleNameVictimController = TextEditingController();
  final TextEditingController _qualifierVictimController = TextEditingController();
  final TextEditingController _nicknameVictimController = TextEditingController();
  final TextEditingController _citizenshipVictimController = TextEditingController();
  final TextEditingController _sexGenderVictimController = TextEditingController();
  final TextEditingController _civilStatusVictimController = TextEditingController();
  final TextEditingController _dateOfBirthVictimController = TextEditingController();
  final TextEditingController _ageVictimController = TextEditingController();
  final TextEditingController _placeOfBirthVictimController = TextEditingController();
  final TextEditingController _homePhoneVictimController = TextEditingController();
  final TextEditingController _mobilePhoneVictimController = TextEditingController();
  final TextEditingController _currentAddressVictimController = TextEditingController();
  final TextEditingController _villageSitioVictimController = TextEditingController();
  final TextEditingController _educationVictimController = TextEditingController();
  final TextEditingController _occupationVictimController = TextEditingController();
  final TextEditingController _idCardVictimController = TextEditingController();
  final TextEditingController _emailVictimController = TextEditingController();
  
  // ITEM D - Narrative controllers
  final TextEditingController _typeOfIncidentDController = TextEditingController();
  final TextEditingController _dateTimeIncidentDController = TextEditingController();
  final TextEditingController _placeOfIncidentDController = TextEditingController();
  final TextEditingController _narrativeController = TextEditingController();
  
  DateTime? dateTimeReported;
  DateTime? dateTimeIncident;

  static const String dropdownPlaceholder = CitizenshipOptions.placeholder;

  // Use the options from the constants file
  final List<String> citizenshipOptions = CitizenshipOptions.options;
  final List<String> genderOptions = [dropdownPlaceholder, 'Male', 'Female', 'Prefer Not to Say'];
  final List<String> civilStatusOptions = [dropdownPlaceholder, 'Single', 'Married', 'Widowed', 'Separated', 'Divorced'];
  
  // Add qualifier options
  final List<String> qualifierOptions = [dropdownPlaceholder, 'Jr.', 'Sr.', 'I', 'II', 'III', 'IV', 'V', 'None'];
  
  // Add education and occupation options
  final List<String> educationOptions = EducationOptions.options;
  final List<String> occupationOptions = OccupationOptions.options;

  // Selected values for education and occupation
  String? reportingPersonEducation;
  String? reportingPersonOccupation;
  String? suspectEducation;
  String? suspectOccupation;
  String? victimEducation;
  String? victimOccupation;

  int? reportingPersonAge;
  int? suspectAge;
  int? victimAge;

  Region? reportingPersonRegion;
  Province? reportingPersonProvince;
  Municipality? reportingPersonMunicipality;
  String? reportingPersonBarangay;
  
  Region? reportingPersonOtherRegion;
  Province? reportingPersonOtherProvince;
  Municipality? reportingPersonOtherMunicipality;
  String? reportingPersonOtherBarangay;
  
  Region? suspectRegion;
  Province? suspectProvince;
  Municipality? suspectMunicipality;
  String? suspectBarangay;
  
  Region? suspectOtherRegion;
  Province? suspectOtherProvince;
  Municipality? suspectOtherMunicipality;
  String? suspectOtherBarangay;
  
  Region? victimRegion;
  Province? victimProvince;
  Municipality? victimMunicipality;
  String? victimBarangay;
  Region? victimOtherRegion;
  Province? victimOtherProvince;
  Municipality? victimOtherMunicipality;
  String? victimOtherBarangay;

  // Date dropdown variables for reporting person date of birth
  int? selectedDayReporting;
  int? selectedMonthReporting;
  int? selectedYearReporting;
  
  // Date dropdown variables for victim date of birth
  int? selectedDayVictim;
  int? selectedMonthVictim;
  int? selectedYearVictim;
  
  // Date and time dropdown variables for incident date/time
  int? selectedDayIncident;
  int? selectedMonthIncident;
  int? selectedYearIncident;
  TimeOfDay? selectedTimeIncident;

  // Combined state for FormRowInputs
  Map<String, dynamic> formState = {};

  int calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    if (today.month < birthDate.month || 
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  // Update reporting person date controller from dropdown selections
  void _updateReportingDateFromDropdowns() {
    if (selectedDayReporting != null && selectedMonthReporting != null && selectedYearReporting != null) {
      final dateStr = "${selectedDayReporting!.toString().padLeft(2, '0')}/${selectedMonthReporting!.toString().padLeft(2, '0')}/${selectedYearReporting!}";
      _dateOfBirthReportingController.text = dateStr;
      
      // Calculate and update age automatically
      try {
        final birthDate = DateTime(selectedYearReporting!, selectedMonthReporting!, selectedDayReporting!);
        final age = calculateAge(birthDate);
        _ageReportingController.text = age.toString();
        reportingPersonAge = age;
      } catch (e) {
        print('Error calculating reporting person age: $e');
      }
    } else {
      _dateOfBirthReportingController.text = '';
      _ageReportingController.text = '';
      reportingPersonAge = null;
    }
    updateFormState();
  }
  
  // Update victim date controller from dropdown selections
  void _updateVictimDateFromDropdowns() {
    if (selectedDayVictim != null && selectedMonthVictim != null && selectedYearVictim != null) {
      final dateStr = "${selectedDayVictim!.toString().padLeft(2, '0')}/${selectedMonthVictim!.toString().padLeft(2, '0')}/${selectedYearVictim!}";
      _dateOfBirthVictimController.text = dateStr;
      
      // Calculate and update age automatically
      try {
        final birthDate = DateTime(selectedYearVictim!, selectedMonthVictim!, selectedDayVictim!);
        final age = calculateAge(birthDate);
        _ageVictimController.text = age.toString();
        victimAge = age;
      } catch (e) {
        print('Error calculating victim age: $e');
      }
    } else {
      _dateOfBirthVictimController.text = '';
      _ageVictimController.text = '';
      victimAge = null;
    }
    updateFormState();
  }
  
  // Update incident date and time controller from dropdown and time selections
  void _updateIncidentDateTimeFromDropdowns() {
    if (selectedDayIncident != null && selectedMonthIncident != null && selectedYearIncident != null && selectedTimeIncident != null) {
      try {
        final incidentDate = DateTime(
          selectedYearIncident!, 
          selectedMonthIncident!, 
          selectedDayIncident!,
          selectedTimeIncident!.hour,
          selectedTimeIncident!.minute,
        );
        
        // Update the dateTimeIncident variable and controllers
        setState(() {
          dateTimeIncident = incidentDate;
          _dateTimeIncidentController.text = _formatDateTime(incidentDate);
          _dateTimeIncidentDController.text = _formatDateTime(incidentDate);
        });
      } catch (e) {
        print('Error creating incident date time: $e');
      }
    } else {
      setState(() {
        dateTimeIncident = null;
        _dateTimeIncidentController.text = '';
        _dateTimeIncidentDController.text = '';
      });
    }
    updateFormState();
  }
  
  // Generate list of days based on selected month and year for reporting person
  List<int> _getDaysInMonthReporting() {
    if (selectedMonthReporting == null || selectedYearReporting == null) {
      return List.generate(31, (index) => index + 1);
    }
    
    int daysInMonth;
    switch (selectedMonthReporting!) {
      case 2: // February
        daysInMonth = (_isLeapYear(selectedYearReporting!) ? 29 : 28);
        break;
      case 4:
      case 6:
      case 9:
      case 11:
        daysInMonth = 30;
        break;
      default:
        daysInMonth = 31;
    }
    
    return List.generate(daysInMonth, (index) => index + 1);
  }
  
  // Generate list of days based on selected month and year for victim
  List<int> _getDaysInMonthVictim() {
    if (selectedMonthVictim == null || selectedYearVictim == null) {
      return List.generate(31, (index) => index + 1);
    }
    
    int daysInMonth;
    switch (selectedMonthVictim!) {
      case 2: // February
        daysInMonth = (_isLeapYear(selectedYearVictim!) ? 29 : 28);
        break;
      case 4:
      case 6:
      case 9:
      case 11:
        daysInMonth = 30;
        break;
      default:
        daysInMonth = 31;
    }
    
    return List.generate(daysInMonth, (index) => index + 1);
  }
  
  // Generate list of days based on selected month and year for incident
  List<int> _getDaysInMonthIncident() {
    if (selectedMonthIncident == null || selectedYearIncident == null) {
      return List.generate(31, (index) => index + 1);
    }
    
    int daysInMonth;
    switch (selectedMonthIncident!) {
      case 2: // February
        daysInMonth = (_isLeapYear(selectedYearIncident!) ? 29 : 28);
        break;
      case 4:
      case 6:
      case 9:
      case 11:
        daysInMonth = 30;
        break;
      default:
        daysInMonth = 31;
    }
    
    return List.generate(daysInMonth, (index) => index + 1);
  }
  
  bool _isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }
  @override
  void initState() {
    super.initState();
    // Initialize with current date and time
    dateTimeReported = DateTime.now();
    _typeOfIncidentController.text = "Missing Person";
    _typeOfIncidentDController.text = "Missing Person";
    if (dateTimeIncident != null) {
      _dateTimeIncidentDController.text = _formatDateTime(dateTimeIncident!);
    }
    updateFormState();
    checkScreenCompliance();
    _prefillUserDetails(); // Prefill user details in Item A
  }
  // Prefill user details in Item A (Reporting Person)
  Future<void> _prefillUserDetails() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return;
    try {
      // Only prefill if the form is empty
      if (_surnameReportingController.text.isNotEmpty || _firstNameReportingController.text.isNotEmpty) return;
      
      // First, try to get saved reporting person data (priority over user profile)
      Map<String, dynamic>? savedReportingData = await _irfService.getSavedReportingPersonData();
      
      if (savedReportingData != null) {
        // Use saved reporting person data
        setState(() {
          _surnameReportingController.text = savedReportingData['surname'] ?? '';
          _firstNameReportingController.text = savedReportingData['firstName'] ?? '';
          _middleNameReportingController.text = savedReportingData['middleName'] ?? '';
          _qualifierReportingController.text = savedReportingData['qualifier'] ?? '';
          _nicknameReportingController.text = savedReportingData['nickname'] ?? '';
          _citizenshipReportingController.text = savedReportingData['citizenship'] ?? '';
          _sexGenderReportingController.text = savedReportingData['sexGender'] ?? '';
          _civilStatusReportingController.text = savedReportingData['civilStatus'] ?? '';
          _dateOfBirthReportingController.text = savedReportingData['dateOfBirth'] ?? '';
          _ageReportingController.text = savedReportingData['age'] ?? '';
          _placeOfBirthReportingController.text = savedReportingData['placeOfBirth'] ?? '';
          _homePhoneReportingController.text = savedReportingData['homePhone'] ?? '';
          _mobilePhoneReportingController.text = savedReportingData['mobilePhone'] ?? '';
          _currentAddressReportingController.text = savedReportingData['currentAddress'] ?? '';
          _villageSitioReportingController.text = savedReportingData['villageSitio'] ?? '';
          _educationReportingController.text = savedReportingData['education'] ?? '';
          _occupationReportingController.text = savedReportingData['occupation'] ?? '';
          _idCardPresentedController.text = savedReportingData['idCardPresented'] ?? '';
          _emailReportingController.text = savedReportingData['email'] ?? '';
          
          // Restore date components
          selectedDayReporting = savedReportingData['selectedDay'];
          selectedMonthReporting = savedReportingData['selectedMonth'];
          selectedYearReporting = savedReportingData['selectedYear'];
          
          // Restore address selection state
          hasOtherAddressReporting = savedReportingData['hasOtherAddress'] ?? false;
          
          // Note: We'll need to handle region/province/municipality restoration separately
          // as these require async calls to the Philippines API
          _restoreLocationData(savedReportingData);
        });
        updateFormState();
        return; // Don't proceed to user profile data if saved data exists
      }
      
      // Fallback to user profile data if no saved reporting person data exists
      String? selectedIDType = await _irfService.getUserSelectedIDType();
      
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('userId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();
      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data();
        setState(() {
          _surnameReportingController.text = userData['lastName'] ?? '';
          _firstNameReportingController.text = userData['firstName'] ?? '';          
          _middleNameReportingController.text = userData['middleName'] ?? '';
          _emailReportingController.text = userData['email'] ?? '';
          _sexGenderReportingController.text = userData['gender'] ?? '';
          _ageReportingController.text = userData['age'] != null ? userData['age'].toString() : '';
          _idCardPresentedController.text = selectedIDType ?? '';
          
          // Handle birthday field for date of birth
          if (userData['birthday'] != null) {
            DateTime? dob;
            try {
              if (userData['birthday'] is Timestamp) {
                dob = userData['birthday'].toDate();
              } else if (userData['birthday'] is String) {
                String dobString = userData['birthday'];
                // Try different date formats
                dob = DateTime.tryParse(dobString);
                if (dob == null) {
                  // Try parsing MM/DD/YYYY format
                  List<String> parts = dobString.split('/');
                  if (parts.length == 3) {
                    int? month = int.tryParse(parts[0]);
                    int? day = int.tryParse(parts[1]);
                    int? year = int.tryParse(parts[2]);
                    if (day != null && month != null && year != null) {
                      dob = DateTime(year, month, day);
                    }
                  }
                  
                  // If MM/DD/YYYY failed, try DD/MM/YYYY format
                  if (dob == null && parts.length == 3) {
                    int? day = int.tryParse(parts[0]);
                    int? month = int.tryParse(parts[1]);
                    int? year = int.tryParse(parts[2]);
                    if (day != null && month != null && year != null) {
                      dob = DateTime(year, month, day);
                    }
                  }
                }
              } else {
                print('Unexpected birthday format: ${userData['birthday'].runtimeType}');
              }
              
              if (dob != null) {
                _dateOfBirthReportingController.text = "${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}";
                // Also set the dropdown values
                selectedDayReporting = dob.day;
                selectedMonthReporting = dob.month;
                selectedYearReporting = dob.year;
              }
            } catch (e) {
              print('Error parsing birthday: $e');
            }
          }
          _mobilePhoneReportingController.text = userData['phoneNumber'] ?? '';
          _citizenshipReportingController.text = userData['citizenship'] ?? '';
          _civilStatusReportingController.text = userData['civilStatus'] ?? '';
          _educationReportingController.text = userData['education'] ?? '';
          _occupationReportingController.text = userData['occupation'] ?? '';
          // Optionally prefill address fields if available
          _currentAddressReportingController.text = userData['currentAddress'] ?? '';
          _placeOfBirthReportingController.text = userData['placeOfBirth'] ?? '';
        });
        updateFormState();
      }
    } catch (e) {
      print('Error pre-filling user details: $e');
    }
  }

  // Helper method to restore location data from saved reporting person data
  Future<void> _restoreLocationData(Map<String, dynamic> savedData) async {
    try {
      // Get stored location names
      String? regionName = savedData['regionName'];
      String? provinceName = savedData['provinceName'];
      String? municipalityName = savedData['municipalityName'];
      String? barangay = savedData['barangay'];
      
      // Restore main address location data
      if (regionName != null) {
        // Find the region by name
        reportingPersonRegion = philippineRegions.firstWhere(
          (region) => region.regionName == regionName,
          orElse: () => philippineRegions.first,
        );
        
        if (provinceName != null && reportingPersonRegion != null) {
          // Find the province within the selected region
          reportingPersonProvince = reportingPersonRegion!.provinces.firstWhere(
            (province) => province.name == provinceName,
            orElse: () => reportingPersonRegion!.provinces.first,
          );
          
          if (municipalityName != null && reportingPersonProvince != null) {
            // Find the municipality within the selected province
            reportingPersonMunicipality = reportingPersonProvince!.municipalities.firstWhere(
              (municipality) => municipality.name == municipalityName,
              orElse: () => reportingPersonProvince!.municipalities.first,
            );
            
            // Set the barangay if it exists in the municipality
            if (barangay != null && reportingPersonMunicipality != null) {
              if (reportingPersonMunicipality!.barangays.contains(barangay)) {
                reportingPersonBarangay = barangay;
              }
            }
          }
        }
      }
      
      // Handle other address data
      if (savedData['hasOtherAddress'] == true) {
        hasOtherAddressReporting = true;
        
        String? otherRegionName = savedData['otherRegionName'];
        String? otherProvinceName = savedData['otherProvinceName'];
        String? otherMunicipalityName = savedData['otherMunicipalityName'];
        String? otherBarangay = savedData['otherBarangay'];
        
        if (otherRegionName != null) {
          // Find the other region by name
          reportingPersonOtherRegion = philippineRegions.firstWhere(
            (region) => region.regionName == otherRegionName,
            orElse: () => philippineRegions.first,
          );
          
          if (otherProvinceName != null && reportingPersonOtherRegion != null) {
            // Find the other province within the selected region
            reportingPersonOtherProvince = reportingPersonOtherRegion!.provinces.firstWhere(
              (province) => province.name == otherProvinceName,
              orElse: () => reportingPersonOtherRegion!.provinces.first,
            );
            
            if (otherMunicipalityName != null && reportingPersonOtherProvince != null) {
              // Find the other municipality within the selected province
              reportingPersonOtherMunicipality = reportingPersonOtherProvince!.municipalities.firstWhere(
                (municipality) => municipality.name == otherMunicipalityName,
                orElse: () => reportingPersonOtherProvince!.municipalities.first,
              );
              
              // Set the other barangay if it exists in the municipality
              if (otherBarangay != null && reportingPersonOtherMunicipality != null) {
                if (reportingPersonOtherMunicipality!.barangays.contains(otherBarangay)) {
                  reportingPersonOtherBarangay = otherBarangay;
                }
              }
            }
          }
        }
      }
      
      setState(() {}); // Trigger UI update
    } catch (e) {
      print('Error restoring location data: $e');
    }
  }

  // Check compliance for fill up form screen
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
      bool accepted = await authService.getScreenComplianceAccepted(currentUser.uid, ModalUtils.SCREEN_FILL_UP_FORM_COMPLIANCE);
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

  // Show both modals in sequence for fill up form
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
                await AuthService().updateScreenComplianceAccepted(currentUser.uid, ModalUtils.SCREEN_FILL_UP_FORM_COMPLIANCE, true);
                print('Fill up form compliance accepted in database');
              } catch (e) {
                print('Error updating fill up form compliance: $e');
              }
            } else if (!accepted && currentUser != null) {
              await AuthService().updateScreenComplianceAccepted(currentUser.uid, ModalUtils.SCREEN_FILL_UP_FORM_COMPLIANCE, false);
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
  
  // Update the combined form state to pass to FormRowInputs
  void updateFormState() {
    formState = {
      'reportingRegion': reportingPersonRegion,
      'reportingProvince': reportingPersonProvince,
      'reportingMunicipality': reportingPersonMunicipality,
      'reportingBarangay': reportingPersonBarangay,
      'reportingOtherRegion': reportingPersonOtherRegion,
      'reportingOtherProvince': reportingPersonOtherProvince,
      'reportingOtherMunicipality': reportingPersonOtherMunicipality,
      'reportingOtherBarangay': reportingPersonOtherBarangay,
      'suspectRegion': suspectRegion,
      'suspectProvince': suspectProvince,
      'suspectMunicipality': suspectMunicipality,
      'suspectBarangay': suspectBarangay,
      'suspectOtherRegion': suspectOtherRegion,
      'suspectOtherProvince': suspectOtherProvince,
      'suspectOtherMunicipality': suspectOtherMunicipality,
      'suspectOtherBarangay': suspectOtherBarangay,
      'victimRegion': victimRegion,
      'victimProvince': victimProvince,
      'victimMunicipality': victimMunicipality,
      'victimBarangay': victimBarangay,
      'victimOtherRegion': victimOtherRegion,
      'victimOtherProvince': victimOtherProvince,
      'victimOtherMunicipality': victimOtherMunicipality,
      'victimOtherBarangay': victimOtherBarangay,
      'reportingEducation': reportingPersonEducation,
      'reportingOccupation': reportingPersonOccupation,
      'suspectEducation': suspectEducation,
      'suspectOccupation': suspectOccupation,
      'victimEducation': victimEducation,
      'victimOccupation': victimOccupation,
      'reportingPersonCivilStatus': _civilStatusReportingController.text,
      'victimCivilStatus': _civilStatusVictimController.text,
    };
  }
  
  // Handle field changes from FormRowInputs
  void onFieldChange(String key, dynamic value) {
    setState(() {
      switch (key) {
        case 'reportingRegion':
          if (reportingPersonRegion != value) {
            reportingPersonProvince = null;
            reportingPersonMunicipality = null;
            reportingPersonBarangay = null;
          }
          reportingPersonRegion = value;
          break;
        case 'reportingProvince':
          if (reportingPersonProvince != value) {
            reportingPersonMunicipality = null;
            reportingPersonBarangay = null;
          }
          reportingPersonProvince = value;
          break;
        case 'reportingMunicipality':
          if (reportingPersonMunicipality != value) {
            reportingPersonBarangay = null;
          }
          reportingPersonMunicipality = value;
          break;
        case 'reportingBarangay':
          reportingPersonBarangay = value;
          break;
        // Add victim address field handlers
        case 'victimRegion':
          if (victimRegion != value) {
            victimProvince = null;
            victimMunicipality = null;
            victimBarangay = null;
          }
          victimRegion = value;
          break;
        case 'victimProvince':
          if (victimProvince != value) {
            victimMunicipality = null;
            victimBarangay = null;
          }
          victimProvince = value;
          break;
        case 'victimMunicipality':
          if (victimMunicipality != value) {
            victimBarangay = null;
          }
          victimMunicipality = value;
          break;
        case 'victimBarangay':
          victimBarangay = value;
          break;
        // Add missing reporting other address field handlers
        case 'reportingOtherRegion':
          if (reportingPersonOtherRegion != value) {
            reportingPersonOtherProvince = null;
            reportingPersonOtherMunicipality = null;
            reportingPersonOtherBarangay = null;
          }
          reportingPersonOtherRegion = value;
          break;
        case 'reportingOtherProvince':
          if (reportingPersonOtherProvince != value) {
            reportingPersonOtherMunicipality = null;
            reportingPersonOtherBarangay = null;
          }
          reportingPersonOtherProvince = value;
          break;
        case 'reportingOtherMunicipality':
          if (reportingPersonOtherMunicipality != value) {
            reportingPersonOtherBarangay = null;
          }
          reportingPersonOtherMunicipality = value;
          break;
        case 'reportingOtherBarangay':
          reportingPersonOtherBarangay = value;
          break;
        // Add missing victim other address field handlers  
        case 'victimOtherRegion':
          if (victimOtherRegion != value) {
            victimOtherProvince = null;
            victimOtherMunicipality = null;
            victimOtherBarangay = null;
          }
          victimOtherRegion = value;
          break;
        case 'victimOtherProvince':
          if (victimOtherProvince != value) {
            victimOtherMunicipality = null;
            victimOtherBarangay = null;
          }
          victimOtherProvince = value;
          break;
        case 'victimOtherMunicipality':
          if (victimOtherMunicipality != value) {
            victimOtherBarangay = null;
          }
          victimOtherMunicipality = value;
          break;
        case 'victimOtherBarangay':
          victimOtherBarangay = value;
          break;
          
        // Handle dropdown values
        case 'citizenshipReporting':
          _citizenshipReportingController.text = value;
          break;
        case 'sexGenderReporting':
          _sexGenderReportingController.text = value;
          break;
        case 'civilStatusReporting':
          _civilStatusReportingController.text = value;
          break;
        case 'civilStatusVictim':
          _civilStatusVictimController.text = value;
          break;
        case 'educationReporting':
          _educationReportingController.text = value;
          break;
        case 'occupationReporting':
          _occupationReportingController.text = value;
          break;
        case 'citizenshipVictim':
          _citizenshipVictimController.text = value;
          break;
        case 'sexGenderVictim':
          _sexGenderVictimController.text = value;
          break;
        case 'educationVictim':
          _educationVictimController.text = value;
          break;
        case 'occupationVictim':
          _occupationVictimController.text = value;
          break;
        case 'qualifierReporting':
          _qualifierReportingController.text = value;
          break;
        case 'qualifierVictim':
          _qualifierVictimController.text = value;
          break;
      }
      updateFormState();
    });
  }
  // Store original victim address fields for restoration when checkbox is unchecked
  Map<String, dynamic> _originalVictimAddress = {};
  
  // Helper to copy address fields from reporting person to victim
  void copyReportingAddressToVictim() {
    setState(() {
      // Store original values before copying
      _originalVictimAddress = {
        'currentAddress': _currentAddressVictimController.text,
        'villageSitio': _villageSitioVictimController.text,
        'region': victimRegion,
        'province': victimProvince,
        'municipality': victimMunicipality,
        'barangay': victimBarangay,
      };
      
      // Copy reporting person address to victim
      _currentAddressVictimController.text = _currentAddressReportingController.text;
      _villageSitioVictimController.text = _villageSitioReportingController.text;
      victimRegion = reportingPersonRegion;
      victimProvince = reportingPersonProvince;
      victimMunicipality = reportingPersonMunicipality;
      victimBarangay = reportingPersonBarangay;
      
      // Update formState for victim address fields
      updateFormState();
    });
  }
  
  // Helper to restore original victim address fields when checkbox is unchecked
  void restoreVictimAddress() {
    setState(() {
      // Restore original values if they exist
      _currentAddressVictimController.text = _originalVictimAddress['currentAddress'] ?? '';
      _villageSitioVictimController.text = _originalVictimAddress['villageSitio'] ?? '';
      victimRegion = _originalVictimAddress['region'];
      victimProvince = _originalVictimAddress['province'];
      victimMunicipality = _originalVictimAddress['municipality'];
      victimBarangay = _originalVictimAddress['barangay'];
      
      // Update formState for victim address fields
      updateFormState();
    });
  }
  @override
  void dispose() {
    // Dispose all controllers
    // General information controllers
    _typeOfIncidentController.dispose();
    _dateTimeIncidentController.dispose();
    _placeOfIncidentController.dispose();
    
    // ITEM A - Reporting Person controllers
    _surnameReportingController.dispose();
    _firstNameReportingController.dispose();
    _middleNameReportingController.dispose();
    _qualifierReportingController.dispose();
    _nicknameReportingController.dispose();
    _citizenshipReportingController.dispose();
    _sexGenderReportingController.dispose();
    _civilStatusReportingController.dispose();
    _dateOfBirthReportingController.dispose();
    _ageReportingController.dispose();
    _placeOfBirthReportingController.dispose();
    _homePhoneReportingController.dispose();
    _mobilePhoneReportingController.dispose();
    _currentAddressReportingController.dispose();
    _villageSitioReportingController.dispose();
    _educationReportingController.dispose();
    _occupationReportingController.dispose();
    _idCardPresentedController.dispose();
    _emailReportingController.dispose();
    
    // ITEM C - Victim controllers
    _surnameVictimController.dispose();
    _firstNameVictimController.dispose();
    _middleNameVictimController.dispose();
    _qualifierVictimController.dispose();
    _nicknameVictimController.dispose();
    _citizenshipVictimController.dispose();
    _sexGenderVictimController.dispose();
    _civilStatusVictimController.dispose();
    _dateOfBirthVictimController.dispose();
    _ageVictimController.dispose();
    _placeOfBirthVictimController.dispose();
    _homePhoneVictimController.dispose();
    _mobilePhoneVictimController.dispose();
    _currentAddressVictimController.dispose();
    _villageSitioVictimController.dispose();    _educationVictimController.dispose();
    _occupationVictimController.dispose();
    _idCardVictimController.dispose();
    _emailVictimController.dispose();
    
    // ITEM D - Narrative controllers
    _typeOfIncidentDController.dispose();
    _dateTimeIncidentDController.dispose();
    _placeOfIncidentDController.dispose();
    _narrativeController.dispose();
    
    super.dispose();
  }

  // Format date and time for display
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MM/dd/yyyy hh:mm a').format(dateTime);
  }

  // Date and time picker function
  Future<void> _pickDateTime(TextEditingController controller, DateTime? initialDateTime, 
      Function(DateTime) onDateTimeSelected) async {
    // Use current date or initialDateTime, but ensure it's not in the future
    DateTime now = DateTime.now();
    DateTime initialDate = initialDateTime ?? now;
    if (initialDate.isAfter(now)) {
      initialDate = now;
    }
    
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(), // Restrict to current date as the maximum
    );
    
    if (pickedDate != null) {
      // After selecting date, show time picker
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDateTime ?? DateTime.now()),
        // Note: Time picker doesn't have built-in max time restriction
      );
      
      if (pickedTime != null) {
        // Create the selected date time
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        
        // If selected date is today, validate that the time is not in the future
        if (pickedDate.year == now.year && 
            pickedDate.month == now.month && 
            pickedDate.day == now.day) {
          // If selected time is in the future, use current time instead
          if (selectedDateTime.isAfter(now)) {
            // Use the current time instead
            final currentTime = TimeOfDay.fromDateTime(now);
            final adjustedDateTime = DateTime(
              pickedDate.year,
              pickedDate.month,
              pickedDate.day,
              currentTime.hour,
              currentTime.minute,
            );
            
            onDateTimeSelected(adjustedDateTime);
            controller.text = _formatDateTime(adjustedDateTime);
            
            // Show a message to inform the user
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Future time not allowed. Using current time instead.'),
                duration: Duration(seconds: 2),
              ),
            );
            return;
          }
        }
        
        onDateTimeSelected(selectedDateTime);
        controller.text = _formatDateTime(selectedDateTime);
      }
    }
  }

  // Incident date and time picker function using dropdown date + time picker
  void _pickIncidentDateTime() {
    // Get initial values from current dateTimeIncident or use current date/time
    DateTime now = DateTime.now();
    DateTime initialDate = dateTimeIncident ?? now;
    if (initialDate.isAfter(now)) {
      initialDate = now;
    }
    
    // If we have an existing incident date, use its values as initial selection
    if (dateTimeIncident != null) {
      selectedDayIncident = dateTimeIncident!.day;
      selectedMonthIncident = dateTimeIncident!.month;
      selectedYearIncident = dateTimeIncident!.year;
      selectedTimeIncident = TimeOfDay.fromDateTime(dateTimeIncident!);
    } else {
      // Use current date/time as default
      selectedDayIncident = initialDate.day;
      selectedMonthIncident = initialDate.month;
      selectedYearIncident = initialDate.year;
      selectedTimeIncident = TimeOfDay.fromDateTime(initialDate);
    }
    
    // Show date+time picker dialog
    _showIncidentDateTimePickerDialog();
  }

  // Show date+time picker dialog for incident
  void _showIncidentDateTimePickerDialog() {
    // Track local state for the dialog
    int? localMonth = selectedMonthIncident;
    int? localDay = selectedDayIncident;
    int? localYear = selectedYearIncident;
    TimeOfDay? localTime = selectedTimeIncident;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              child: Container(
                width: 400,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(
                          Icons.event_note,
                          color: Color(0xFF0D47A1),
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Select Date & Time',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0D47A1),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    
                    // Date section
                    Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Date selection row
                    Row(
                      children: [
                        // Month dropdown
                        Expanded(
                          flex: 5,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonFormField<int>(
                              value: localMonth,
                              decoration: InputDecoration(
                                labelText: 'Month',
                                labelStyle: TextStyle(
                                  color: Color(0xFF0D47A1),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                isDense: true,
                              ),
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              items: List.generate(12, (index) {
                                int month = index + 1;
                                List<String> monthNames = [
                                  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                                ];
                                return DropdownMenuItem<int>(
                                  value: month,
                                  child: Text(
                                    '${month.toString().padLeft(2, '0')} - ${monthNames[index]}',
                                    style: TextStyle(fontSize: 12, color: Colors.black),
                                  ),
                                );
                              }),
                              onChanged: (int? newValue) {
                                setState(() {
                                  localMonth = newValue;
                                  // Reset day if current day is not valid for new month
                                  if (localDay != null && localYear != null && newValue != null) {
                                    int daysInMonth = _getDaysInSelectedMonth(newValue, localYear!);
                                    if (localDay! > daysInMonth) {
                                      localDay = daysInMonth;
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        
                        // Day dropdown
                        Expanded(
                          flex: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonFormField<int>(
                              value: localDay,
                              decoration: InputDecoration(
                                labelText: 'Day',
                                labelStyle: TextStyle(
                                  color: Color(0xFF0D47A1),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                isDense: true,
                              ),
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              items: localMonth != null && localYear != null ? 
                                List.generate(_getDaysInSelectedMonth(localMonth!, localYear!), (index) {
                                int day = index + 1;
                                return DropdownMenuItem<int>(
                                  value: day,
                                  child: Text(day.toString().padLeft(2, '0'), style: TextStyle(fontSize: 12, color: Colors.black)),
                                );
                              }) : [],
                              onChanged: (int? newValue) {
                                setState(() {
                                  localDay = newValue;
                                });
                              },
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        
                        // Year dropdown
                        Expanded(
                          flex: 4,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonFormField<int>(
                              value: localYear,
                              decoration: InputDecoration(
                                labelText: 'Year',
                                labelStyle: TextStyle(
                                  color: Color(0xFF0D47A1),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                isDense: true,
                              ),
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              items: List.generate(100, (index) {
                                int year = DateTime.now().year - index;
                                return DropdownMenuItem<int>(
                                  value: year,
                                  child: Text(year.toString(), style: TextStyle(fontSize: 12, color: Colors.black)),
                                );
                              }),
                              onChanged: (int? newValue) {
                                setState(() {
                                  localYear = newValue;
                                  // Reset day if current day is not valid for new year
                                  if (localDay != null && localMonth != null && newValue != null) {
                                    int daysInMonth = _getDaysInSelectedMonth(localMonth!, newValue);
                                    if (localDay! > daysInMonth) {
                                      localDay = daysInMonth;
                                    }
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Time section
                    Text(
                      'Time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Time picker button
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () async {
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: dialogContext,
                              initialTime: localTime ?? TimeOfDay.now(),
                            );
                            if (pickedTime != null) {
                              setState(() {
                                localTime = pickedTime;
                              });
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: Color(0xFF0D47A1),
                                  size: 20,
                                ),
                                SizedBox(width: 12),
                                Text(
                                  localTime != null 
                                    ? localTime!.format(context)
                                    : 'Select Time',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: localTime != null ? Colors.black87 : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Selected date and time preview
                    if (localMonth != null && localDay != null && localYear != null && localTime != null)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Color(0xFF0D47A1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFF0D47A1).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Date & Time:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0D47A1),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${localMonth.toString().padLeft(2, '0')}/${localDay.toString().padLeft(2, '0')}/$localYear ${localTime!.format(context)}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF0D47A1),
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    SizedBox(height: 24),
                    
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: (localMonth != null && localDay != null && localYear != null && localTime != null) ? () {
                            // Validate that the selected date/time is not in the future
                            final selectedDateTime = DateTime(
                              localYear!,
                              localMonth!,
                              localDay!,
                              localTime!.hour,
                              localTime!.minute,
                            );
                            
                            final now = DateTime.now();
                            if (selectedDateTime.isAfter(now)) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Future date/time not allowed. Please select a past date and time.'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                              return;
                            }
                            
                            // Update the actual values
                            this.setState(() {
                              selectedMonthIncident = localMonth;
                              selectedDayIncident = localDay;
                              selectedYearIncident = localYear;
                              selectedTimeIncident = localTime;
                            });
                            _updateIncidentDateTimeFromDropdowns();
                            Navigator.of(dialogContext).pop();
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0D47A1),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 2,
                          ),
                          child: Text(
                            'Confirm',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Helper to get days in a specific month and year (for dialog)
  int _getDaysInSelectedMonth(int month, int year) {
    switch (month) {
      case 2: // February
        return (_isLeapYear(year) ? 29 : 28);
      case 4:
      case 6:
      case 9:
      case 11:
        return 30;
      default:
        return 31;
    }
  }

  // Helper method to collect all form data  // Validate form data before collection
  bool validateEducationFields() {
    if (_educationReportingController.text.isEmpty || _educationVictimController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select education level for both reporting person and missing person'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }
  Map<String, dynamic> collectFormData() {
    Map<String, dynamic> formData = {
      // General information
      'typeOfIncident': _typeOfIncidentController.text,
      'dateTimeReported': dateTimeReported,
      'dateTimeIncident': dateTimeIncident,
      'placeOfIncident': _placeOfIncidentController.text,
      // Item A - Reporting Person
      'surnameA': _surnameReportingController.text,
      'firstNameA': _firstNameReportingController.text,
      'middleNameA': _middleNameReportingController.text,
      'qualifierA': _qualifierReportingController.text,
      'nicknameA': _nicknameReportingController.text,
      'citizenshipA': _citizenshipReportingController.text,
      'sexGenderA': _sexGenderReportingController.text,
      'civilStatusA': _civilStatusReportingController.text,
      'dateOfBirthA': _dateOfBirthReportingController.text,
      'ageA': _ageReportingController.text,
      'placeOfBirthA': _placeOfBirthReportingController.text,
      'homePhoneA': _homePhoneReportingController.text,
      'mobilePhoneA': _mobilePhoneReportingController.text,
      'currentAddressA': _currentAddressReportingController.text,
      'villageA': _villageSitioReportingController.text,
      'regionA': reportingPersonRegion?.regionName,
      'provinceA': reportingPersonProvince?.name,
      'townCityA': reportingPersonMunicipality?.name,
      'barangayA': reportingPersonBarangay,
      'otherAddressA': hasOtherAddressReporting ? 'Yes' : null,
      'otherVillageA': hasOtherAddressReporting ? reportingPersonOtherBarangay : null,
      'otherRegionA': hasOtherAddressReporting ? reportingPersonOtherRegion?.regionName : null,
      'otherProvinceA': hasOtherAddressReporting ? reportingPersonOtherProvince?.name : null,
      'otherTownCityA': hasOtherAddressReporting ? reportingPersonOtherMunicipality?.name : null,
      'otherBarangayA': hasOtherAddressReporting ? reportingPersonOtherBarangay : null,
      'highestEducationAttainmentA': _educationReportingController.text,
      'occupationA': _occupationReportingController.text,
      'idCardPresentedA': _idCardPresentedController.text,
      'emailAddressA': _emailReportingController.text,
      // Item B - Missing Person (Victim)
      'surnameB': _surnameVictimController.text,
      'firstNameB': _firstNameVictimController.text,
      'middleNameB': _middleNameVictimController.text,
      'qualifierB': _qualifierVictimController.text,
      'nicknameB': _nicknameVictimController.text,
      'citizenshipB': _citizenshipVictimController.text,
      'sexGenderB': _sexGenderVictimController.text,
      'civilStatusB': _civilStatusVictimController.text,
      'dateOfBirthB': _dateOfBirthVictimController.text,
      'ageB': _ageVictimController.text,
      'placeOfBirthB': _placeOfBirthVictimController.text,
      'homePhoneB': _homePhoneVictimController.text,
      'mobilePhoneB': _mobilePhoneVictimController.text,
      'currentAddressB': _currentAddressVictimController.text,
      'villageB': _villageSitioVictimController.text,
      'regionB': victimRegion?.regionName,
      'provinceB': victimProvince?.name,
      'townCityB': victimMunicipality?.name,
      'barangayB': victimBarangay,
      'otherAddressB': hasOtherAddressVictim ? 'Yes' : null,
      'otherVillageB': hasOtherAddressVictim ? victimOtherBarangay : null,
      'otherRegionB': hasOtherAddressVictim ? victimOtherRegion?.regionName : null,
      'otherProvinceB': hasOtherAddressVictim ? victimOtherProvince?.name : null,
      'otherTownCityB': hasOtherAddressVictim ? victimOtherMunicipality?.name : null,      'otherBarangayB': hasOtherAddressVictim ? victimOtherBarangay : null,
      'highestEducationAttainmentB': _educationVictimController.text,
      'occupationB': _occupationVictimController.text,
      'idCardB': _idCardVictimController.text,
      'emailAddressB': _emailVictimController.text,
      // Narrative
      'narrative': _narrativeController.text,
      'typeOfIncidentD': _typeOfIncidentDController.text,
      'dateTimeIncidentD': dateTimeIncident,
      'placeOfIncidentD': _placeOfIncidentDController.text,
    };
    return formData;
  }

  // Convert form data to IRFModel
  IRFModel createIRFModel() {
    // Parse date of birth strings to DateTime objects if present
    int? ageA = _ageReportingController.text.isNotEmpty ? int.tryParse(_ageReportingController.text) : null;
    int? ageC = _ageVictimController.text.isNotEmpty ? int.tryParse(_ageVictimController.text) : null;
    return IRFModel(
      // Incident Details
      createdAt: dateTimeReported,
      dateTimeOfIncident: dateTimeIncident,
      imageUrl: null, // Set if you have image upload logic
      incidentId: null, // Set if you have incidentId logic
      narrative: _narrativeController.text,
      placeOfIncident: _placeOfIncidentController.text,
      reportedAt: dateTimeReported,
      typeOfIncident: _typeOfIncidentController.text,
      // Item A
      ageA: ageA,
      barangayA: reportingPersonBarangay,
      citizenshipA: _citizenshipReportingController.text,
      civilStatusA: _civilStatusReportingController.text,
      currentAddressA: _currentAddressReportingController.text,
      dateOfBirthA: _dateOfBirthReportingController.text,
      educationA: _educationReportingController.text,
      emailA: _emailReportingController.text,
      familyNameA: _surnameReportingController.text,
      firstNameA: _firstNameReportingController.text,
      homePhoneA: _homePhoneReportingController.text,
      idCardA: _idCardPresentedController.text,
      middleNameA: _middleNameReportingController.text,
      mobilePhoneA: _mobilePhoneReportingController.text,
      nicknameA: _nicknameReportingController.text,
      occupationA: _occupationReportingController.text,
      otherAddressA: hasOtherAddressReporting ? 'Yes' : null,
      otherVillageA: hasOtherAddressReporting ? reportingPersonOtherBarangay : null,
      otherRegionA: hasOtherAddressReporting ? reportingPersonOtherRegion?.regionName : null,
      otherProvinceA: hasOtherAddressReporting ? reportingPersonOtherProvince?.name : null,
      otherTownCityA: hasOtherAddressReporting ? reportingPersonOtherMunicipality?.name : null,
      otherBarangayA: hasOtherAddressReporting ? reportingPersonOtherBarangay : null,
      placeOfBirthA: _placeOfBirthReportingController.text,
      provinceA: reportingPersonProvince?.name,
      qualifierA: _qualifierReportingController.text,
      sexGenderA: _sexGenderReportingController.text,
      townA: reportingPersonMunicipality?.name,
      villageSitioA: _villageSitioReportingController.text,
      // Item C
      ageC: ageC,
      barangayC: victimBarangay,
      citizenshipC: _citizenshipVictimController.text,
      civilStatusC: _civilStatusVictimController.text,
      currentAddressC: _currentAddressVictimController.text,
      dateOfBirthC: _dateOfBirthVictimController.text,
      educationC: _educationVictimController.text,
      emailC: _emailVictimController.text,
      familyNameC: _surnameVictimController.text,
      firstNameC: _firstNameVictimController.text,
      homePhoneC: _homePhoneVictimController.text,
      idCardC: _idCardVictimController.text,
      middleNameC: _middleNameVictimController.text,
      mobilePhoneC: _mobilePhoneVictimController.text,
      nicknameC: _nicknameVictimController.text,
      occupationC: _occupationVictimController.text,
      otherAddressC: hasOtherAddressVictim ? 'Yes' : null,
      otherVillageC: hasOtherAddressVictim ? victimOtherBarangay : null,
      otherRegionC: hasOtherAddressVictim ? victimOtherRegion?.regionName : null,
      otherProvinceC: hasOtherAddressVictim ? victimOtherProvince?.name : null,
      otherTownCityC: hasOtherAddressVictim ? victimOtherMunicipality?.name : null,
      otherBarangayC: hasOtherAddressVictim ? victimOtherBarangay : null,
      placeOfBirthC: _placeOfBirthVictimController.text,
      provinceC: victimProvince?.name,
      qualifierC: _qualifierVictimController.text,
      sexGenderC: _sexGenderVictimController.text,
      townC: victimMunicipality?.name,
      villageSitioC: _villageSitioVictimController.text,
      // Root fields
      pdfUrl: null, // Set if you have PDF upload logic
      status: null, // Set by service
      userId: null, // Set by service
    );
  }  // Validate phone fields to prevent submission with invalid phone numbers
  Future<bool> _validatePhoneFields() async {
    // Check reporting person mobile phone
    final reportingMobilePhone = _mobilePhoneReportingController.text.trim();
    if (reportingMobilePhone.isNotEmpty && reportingMobilePhone.length < 10) {
      await _scrollToFieldByController(_mobilePhoneReportingController);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fix the reporting person mobile phone field before submitting. Invalid number format.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    
    // Check victim mobile phone
    final victimMobilePhone = _mobilePhoneVictimController.text.trim();
    if (victimMobilePhone.isNotEmpty) {
      bool isInvalid = false;
      
      // Check for Philippine format with country code (+63)
      if (victimMobilePhone.startsWith('+63')) {
        if (victimMobilePhone.length != 13 || !RegExp(r'^\+63[9][0-9]{9}$').hasMatch(victimMobilePhone)) {
          isInvalid = true;
        }
      }
      // Check for local format (09)
      else if (victimMobilePhone.startsWith('0')) {
        if (victimMobilePhone.length != 11 || !RegExp(r'^09[0-9]{9}$').hasMatch(victimMobilePhone)) {
          isInvalid = true;
        }
      } 
      else {
        isInvalid = true;
      }
      
      if (isInvalid) {
        await _scrollToFieldByController(_mobilePhoneVictimController);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fix the missing person mobile phone field before submitting. Invalid number format.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    
    return true;
  }
  // Comprehensive validation for all required fields with auto-scroll
  Future<bool> _validateAllRequiredFields() async {
    // First check for phone validation errors that would prevent submission
    if (!(await _validatePhoneFields())) {
      return false;
    }
    // Reporting Person Section
    if (_surnameReportingController.text.trim().isEmpty) {
      await _scrollToSpecificField('SURNAME');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Surname (Reporting Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_firstNameReportingController.text.trim().isEmpty) {
      await _scrollToSpecificField('FIRST NAME');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('First Name (Reporting Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_middleNameReportingController.text.trim().isEmpty) {
      await _scrollToSpecificField('MIDDLE NAME');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Middle Name (Reporting Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_qualifierReportingController.text.isEmpty || _qualifierReportingController.text == dropdownPlaceholder) {
      await _scrollToSpecificField('QUALIFIER');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Qualifier (Reporting Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_nicknameReportingController.text.trim().isEmpty) {
      await _scrollToSpecificField('NICKNAME');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nickname (Reporting Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_citizenshipReportingController.text.isEmpty || _citizenshipReportingController.text == dropdownPlaceholder) {
      await _scrollToSpecificField('CITIZENSHIP');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Citizenship (Reporting Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_sexGenderReportingController.text.isEmpty || _sexGenderReportingController.text == dropdownPlaceholder) {
      await _scrollToSpecificField('SEX/GENDER');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sex/Gender (Reporting Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_civilStatusReportingController.text.isEmpty || _civilStatusReportingController.text == dropdownPlaceholder) {
      await _scrollToSpecificField('CIVIL STATUS');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select civil status for the reporting person.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    // Check date of birth dropdowns for reporting person
    if (selectedDayReporting == null || selectedMonthReporting == null || selectedYearReporting == null) {
      await _scrollToSpecificField('DATE OF BIRTH');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Date of Birth (Reporting Person) is required. Please select month, day, and year.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_ageReportingController.text.trim().isEmpty) {
      await _scrollToSpecificField('AGE');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Age (Reporting Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_placeOfBirthReportingController.text.trim().isEmpty) {
      await _scrollToSpecificField('PLACE OF BIRTH');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Place of Birth (Reporting Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_mobilePhoneReportingController.text.trim().isEmpty) {
      await _scrollToSpecificField('MOBILE PHONE');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mobile Phone (Reporting Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_currentAddressReportingController.text.trim().isEmpty) {
      await _scrollToSpecificField('CURRENT ADDRESS (HOUSE NUMBER/STREET)');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Current Address (Reporting Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_villageSitioReportingController.text.trim().isEmpty) {
      await _scrollToSpecificField('VILLAGE/SITIO');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Village/Sitio (Reporting Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (reportingPersonRegion == null || reportingPersonProvince == null || 
        reportingPersonMunicipality == null || (reportingPersonBarangay?.isEmpty ?? true)) {
      await _scrollToSpecificField('REGION REPORTING');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete all address fields for the reporting person.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_educationReportingController.text.isEmpty || _educationReportingController.text == dropdownPlaceholder) {
      await _scrollToSpecificField('HIGHEST EDUCATION ATTAINMENT');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select education level for the reporting person.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_occupationReportingController.text.isEmpty || _occupationReportingController.text == dropdownPlaceholder) {
      await _scrollToSpecificField('OCCUPATION');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Occupation (Reporting Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_idCardPresentedController.text.trim().isEmpty) {
      await _scrollToSpecificField('ID CARD PRESENTED');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ID Card Presented (Reporting Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    // Missing Person Section
    if (_surnameVictimController.text.trim().isEmpty) {
      await _scrollToSpecificField('SURNAME VICTIM');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Surname (Missing Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_firstNameVictimController.text.trim().isEmpty) {
      await _scrollToSpecificField('FIRST NAME VICTIM');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('First Name (Missing Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_middleNameVictimController.text.trim().isEmpty) {
      await _scrollToSpecificField('MIDDLE NAME VICTIM');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Middle Name (Missing Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_qualifierVictimController.text.isEmpty || _qualifierVictimController.text == dropdownPlaceholder) {
      await _scrollToSpecificField('QUALIFIER VICTIM');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Qualifier (Missing Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_nicknameVictimController.text.trim().isEmpty) {
      await _scrollToSpecificField('NICKNAME VICTIM');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nickname (Missing Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_citizenshipVictimController.text.isEmpty || _citizenshipVictimController.text == dropdownPlaceholder) {
      await _scrollToSpecificField('CITIZENSHIP VICTIM');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Citizenship (Missing Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_sexGenderVictimController.text.isEmpty || _sexGenderVictimController.text == dropdownPlaceholder) {
      await _scrollToSpecificField('SEX/GENDER VICTIM');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sex/Gender (Missing Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_civilStatusVictimController.text.isEmpty || _civilStatusVictimController.text == dropdownPlaceholder) {
      await _scrollToSpecificField('CIVIL STATUS VICTIM');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select civil status for the missing person.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    // Check date of birth dropdowns for victim
    if (selectedDayVictim == null || selectedMonthVictim == null || selectedYearVictim == null) {
      await _scrollToSpecificField('DATE OF BIRTH VICTIM');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Date of Birth (Missing Person) is required. Please select month, day, and year.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_ageVictimController.text.trim().isEmpty) {
      await _scrollToSpecificField('AGE VICTIM');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Age (Missing Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_placeOfBirthVictimController.text.trim().isEmpty) {
      await _scrollToSpecificField('PLACE OF BIRTH VICTIM');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Place of Birth (Missing Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_mobilePhoneVictimController.text.trim().isEmpty) {
      await _scrollToSpecificField('MOBILE PHONE VICTIM');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mobile Phone (Missing Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_currentAddressVictimController.text.trim().isEmpty) {
      await _scrollToSpecificField('CURRENT ADDRESS (HOUSE NUMBER/STREET) VICTIM');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Current Address (Missing Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_villageSitioVictimController.text.trim().isEmpty) {
      await _scrollToSpecificField('VILLAGE/SITIO VICTIM');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Village/Sitio (Missing Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (victimRegion == null || victimProvince == null || 
        victimMunicipality == null || (victimBarangay?.isEmpty ?? true)) {
      await _scrollToSpecificField('REGION VICTIM');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please complete all address fields for the missing person.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_educationVictimController.text.isEmpty || _educationVictimController.text == dropdownPlaceholder) {
      await _scrollToSpecificField('HIGHEST EDUCATION ATTAINMENT VICTIM');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select education level for the missing person.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_occupationVictimController.text.isEmpty || _occupationVictimController.text == dropdownPlaceholder) {
      await _scrollToSpecificField('OCCUPATION VICTIM');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Occupation (Missing Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_idCardVictimController.text.trim().isEmpty) {
      await _scrollToSpecificField('ID CARD PRESENTED VICTIM');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ID Card Presented (Missing Person) is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    // Incident Details Section
    if (_typeOfIncidentController.text.trim().isEmpty) {
      await _scrollToSpecificField('TYPE OF INCIDENT');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Type of Incident is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_dateTimeIncidentController.text.trim().isEmpty) {
      await _scrollToSpecificField('DATE/TIME OF INCIDENT');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Date/Time of Incident is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_placeOfIncidentController.text.trim().isEmpty) {
      await _scrollToSpecificField('PLACE OF INCIDENT');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Place of Incident is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    if (_narrativeController.text.trim().isEmpty) {
      await _scrollToSpecificField('NARRATIVE OF INCIDENT');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Narrative of Incident is required and cannot be empty.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return false;
    }
    return true;
  }
  // Helper method to scroll to a specific field by label
  Future<void> _scrollToSpecificField(String targetLabel) async {
    final GlobalKey? fieldKey = _requiredFieldKeys[targetLabel];
    if (fieldKey?.currentContext != null) {
      await Scrollable.ensureVisible(
        fieldKey!.currentContext!,
        duration: Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.1, // Show field near top of screen
      );
    } else {
      // Fallback to the existing scroll method if specific field not found
      await _scrollToFirstInvalidField();
    }
  }
  // Helper method to scroll to a field using its controller
  Future<void> _scrollToFieldByController(TextEditingController controller) async {
    // Find the controller in our mapping and get its label
    String? labelToFind;
      // Map controllers to their field labels
    final Map<TextEditingController, String> controllerToLabel = {
      // General information fields
      _typeOfIncidentController: 'TYPE OF INCIDENT',
      _dateTimeIncidentController: 'DATE AND TIME REPORTED',
      _placeOfIncidentController: 'DATE AND TIME REPORTED',
      
      // Reporting person fields      
      _surnameReportingController: 'SURNAME',
      _firstNameReportingController: 'FIRST NAME',
      _middleNameReportingController: 'MIDDLE NAME',
      _qualifierReportingController: 'QUALIFIER',
      _nicknameReportingController: 'NICKNAME',
      _citizenshipReportingController: 'CITIZENSHIP',
      _sexGenderReportingController: 'SEX/GENDER',
      _civilStatusReportingController: 'CIVIL STATUS',
      _dateOfBirthReportingController: 'DATE OF BIRTH',
      _ageReportingController: 'AGE',
      _placeOfBirthReportingController: 'PLACE OF BIRTH',
      _mobilePhoneReportingController: 'MOBILE PHONE',
      _currentAddressReportingController: 'CURRENT ADDRESS (HOUSE NUMBER/STREET)',
      _villageSitioReportingController: 'VILLAGE/SITIO',
      _educationReportingController: 'HIGHEST EDUCATION ATTAINMENT',
      _occupationReportingController: 'OCCUPATION',
      _idCardPresentedController: 'ID CARD PRESENTED',
      _emailReportingController: 'EMAIL ADDRESS',
      _surnameVictimController: 'SURNAME VICTIM',
      _firstNameVictimController: 'FIRST NAME VICTIM',
      _middleNameVictimController: 'MIDDLE NAME VICTIM',
      _qualifierVictimController: 'QUALIFIER VICTIM',
      _nicknameVictimController: 'NICKNAME VICTIM',
      _citizenshipVictimController: 'CITIZENSHIP VICTIM',
      _sexGenderVictimController: 'SEX/GENDER VICTIM',
      _civilStatusVictimController: 'CIVIL STATUS VICTIM',
      _dateOfBirthVictimController: 'DATE OF BIRTH VICTIM',      
      _ageVictimController: 'AGE VICTIM',
      _placeOfBirthVictimController: 'PLACE OF BIRTH VICTIM',
      _mobilePhoneVictimController: 'MOBILE PHONE VICTIM',      
      _currentAddressVictimController: 'CURRENT ADDRESS (HOUSE NUMBER/STREET) VICTIM',
      _villageSitioVictimController: 'VILLAGE/SITIO VICTIM',
      _educationVictimController: 'HIGHEST EDUCATION ATTAINMENT VICTIM',
      _occupationVictimController: 'OCCUPATION VICTIM',
      _idCardVictimController: 'ID CARD VICTIM',
      _emailVictimController: 'EMAIL VICTIM',
      _dateTimeIncidentController: 'DATE/TIME OF INCIDENT',
      _placeOfIncidentController: 'PLACE OF INCIDENT',
      _narrativeController: 'NARRATIVE OF INCIDENT',
    };
    
    labelToFind = controllerToLabel[controller];
    
    if (labelToFind != null) {
      await _scrollToSpecificField(labelToFind);
    } else {
      // Fallback to the generic scroll method
      await _scrollToFirstInvalidField();
    }
  }  // Submit form to Firebase
  Future<void> submitForm() async {
    // Image is required
    if ((!kIsWeb && _imageFile == null) || (kIsWeb && _webImage == null)) {
      // Auto-scroll to the image upload section
      await _scrollToSpecificField('NARRATIVE OF INCIDENT');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload an image. It is required.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate that reporting person is not reporting themselves
    if (!_validateReportingPersonNotSelf()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You cannot report yourself as a missing person. Please check the reporting person and missing person details.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    // Check for duplicate missing person
    if (await _checkDuplicateMissingPerson()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A form for this missing person already exists.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      isSubmitting = true;
    });

    try {
      // Check if user is authenticated first
      if (FirebaseAuth.instance.currentUser == null) {
        throw Exception('User not authenticated. Please log in again.');
      }
      
      // Create IRF model from form data
      IRFModel irfData = createIRFModel();
      
      // Before uploading image, ensure selected image hash isn't a duplicate in the DB
      if (_selectedImageHash != null) {
        bool isDuplicate = await _checkDuplicateImageHash(_selectedImageHash!);
        if (isDuplicate) {
          setState(() { isSubmitting = false; });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('This image has already been used in another report. Please choose a different image.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // Upload image and get URL
      String? imageUrl;
      if (kIsWeb && _webImage != null) {
        imageUrl = await _irfService.uploadImage(_webImage, DateTime.now().millisecondsSinceEpoch.toString());
      } else if (_imageFile != null) {
        imageUrl = await _irfService.uploadImage(_imageFile, DateTime.now().millisecondsSinceEpoch.toString());
      }
      if (imageUrl == null) {
        throw Exception('Image upload failed.');
      }
      irfData.imageUrl = imageUrl;
      
      // Submit to Firebase
      DocumentReference<Object?> docRef = await _irfService.submitIRF(irfData);
      
      // Get the document to retrieve the formal ID
      DocumentSnapshot doc = await docRef.get();
      String formalId = (doc.data() as Map<String, dynamic>)['incidentDetails']?['incidentId'] ?? docRef.id;
      // Store the image hash in the imageHashes collection now that the IRF has been successfully created
      if (_selectedImageHash != null) {
        await _storeImageHash(_selectedImageHash!, irfId: formalId);
      }
      
      // Show success message with formal ID
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Form submitted successfully! Reference #: $formalId'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Check if user wants to save reporting person data for future use
      await _showSaveReportingPersonDataDialog();
      
      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      print('Form submission error: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting form: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }
    // Validate that reporting person is not reporting themselves
  bool _validateReportingPersonNotSelf() {
    // Get reporting person data
    final reportingSurname = _surnameReportingController.text.trim().toLowerCase();
    final reportingFirstName = _firstNameReportingController.text.trim().toLowerCase();
    final reportingMiddleName = _middleNameReportingController.text.trim().toLowerCase();
    final reportingDob = _dateOfBirthReportingController.text.trim();
    
    // Get missing person data
    final victimSurname = _surnameVictimController.text.trim().toLowerCase();
    final victimFirstName = _firstNameVictimController.text.trim().toLowerCase();
    final victimMiddleName = _middleNameVictimController.text.trim().toLowerCase();
    final victimDob = _dateOfBirthVictimController.text.trim();
    
    // Check if required fields (surname, first name, and date of birth) are not empty
    // Middle name is optional so we don't require it to be filled
    if (reportingSurname.isNotEmpty && victimSurname.isNotEmpty &&
        reportingFirstName.isNotEmpty && victimFirstName.isNotEmpty &&
        reportingDob.isNotEmpty && victimDob.isNotEmpty) {
      
      // Check if key identifying information matches (including middle name comparison)
      if (reportingSurname == victimSurname &&
          reportingFirstName == victimFirstName &&
          reportingMiddleName == victimMiddleName && // This handles empty middle names correctly
          reportingDob == victimDob) {
        return false; // Same person - validation failed
      }
    }
    
    return true; // Different person - validation passed
  }

  // Check for duplicate missing person
  Future<bool> _checkDuplicateMissingPerson() async {
    final surname = _surnameVictimController.text.trim();
    final firstName = _firstNameVictimController.text.trim();
    final middleName = _middleNameVictimController.text.trim();
    final dob = _dateOfBirthVictimController.text.trim();
    
    // Only check for duplicates if required fields are filled
    // Middle name is optional, so we don't require it to be filled
    if (surname.isEmpty || firstName.isEmpty || dob.isEmpty) {
      return false;
    }

    try {
      // Build query based on available fields
      Query query = FirebaseFirestore.instance
          .collection('incidents')
          .where('itemC.familyName', isEqualTo: surname)
          .where('itemC.firstName', isEqualTo: firstName)
          .where('itemC.dateOfBirth', isEqualTo: dob);
      
      // Add middle name to query only if it's not empty
      if (middleName.isNotEmpty) {
        query = query.where('itemC.middleName', isEqualTo: middleName);
      }
      
      final querySnapshot = await query.limit(1).get();
      
      // Additional check for cases where middle name is empty in the form
      // but might exist in the database
      if (querySnapshot.docs.isEmpty && middleName.isEmpty) {
        // Check for records with empty or null middle name
        final emptyMiddleNameQuery = await FirebaseFirestore.instance
            .collection('incidents')
            .where('itemC.familyName', isEqualTo: surname)
            .where('itemC.firstName', isEqualTo: firstName)
            .where('itemC.dateOfBirth', isEqualTo: dob)
            .where('itemC.middleName', whereIn: ['', null])
            .limit(1)
            .get();
        
        return emptyMiddleNameQuery.docs.isNotEmpty;
      }
      
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking for duplicate missing person: $e');
      // In case of error, allow the form to proceed (don't block legitimate submissions)
      return false;
    }
  }

  @override  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "Incident Record Form",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Color(0xFF0D47A1),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              
            ),
            child: PopupMenuButton<String>(
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white.withOpacity(0.15),
                ),
                child: Icon(
                  Icons.more_vert_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onSelected: (String value) async {
                switch (value) {
                  case 'clear_saved_data':
                    await _showClearSavedDataDialog();
                    break;
                  case 'load_saved_data':
                    await _loadSavedReportingPersonData();
                    break;
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              color: Colors.white,
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'load_saved_data',
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.cloud_download_rounded,
                            color: Colors.blue.shade600,
                            size: 18,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Load Saved Info',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Text(
                                'Fill form with saved data',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'clear_saved_data',
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.delete_sweep_rounded,
                            color: Colors.red.shade600,
                            size: 18,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Clear Saved Info',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                              Text(
                                'Delete all saved data',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: isCheckingPrivacyStatus 
        ? Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.all(16),
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: 900),
              padding: EdgeInsets.all(16),   
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color.fromARGB(255, 255, 255, 255)),
                boxShadow: [BoxShadow(blurRadius: 6, color: Colors.black.withOpacity(0.1))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      SizedBox(height: 20),
                      SizedBox(height: 8),
                      Text(
                        "INCIDENT RECORD FORM",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 5),
                      Divider(
                        color: const Color.fromARGB(255, 214, 214, 214),
                        thickness: 1,
                      ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),

                  // Form Section
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [          
                        // Section title using the new component
                        SectionTitle(
                          title: 'REPORTING PERSON',
                          backgroundColor: Color(0xFF1E215A),
                        ),

                        SizedBox(height: 10),

                        SubsectionTitle(
                          title: 'Personal Information',
                          icon: Icons.person,
                        ),

                        SizedBox(height: 10),

                        KeyedSubtree(
                          key: _getOrCreateKey('SURNAME'),
                          child: FormRowInputs(
                            fields: [
                              {
                                'label': 'SURNAME',
                                'required': true,
                                'controller': _surnameReportingController,
                                'keyboardType': TextInputType.name,
                                'inputFormatters': [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                                'readOnly': true,
                              },
                              {
                                'label': 'FIRST NAME',
                                'required': true,
                                'controller': _firstNameReportingController,
                                'keyboardType': TextInputType.name,
                                'inputFormatters': [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                                'readOnly': true,
                              },
                              {
                                'label': 'MIDDLE NAME',
                                'required': true,
                                'controller': _middleNameReportingController,
                                'keyboardType': TextInputType.name,
                                'inputFormatters': [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                                'readOnly': true,
                              },
                            ],
                            formState: formState,
                            onFieldChange: onFieldChange,
                          ),
                        ),
                        
                        SizedBox(height: 10),
                          FormRowInputs(
                          fields: [
                            {
                              'label': 'QUALIFIER',
                              'required': true,
                              'controller': _qualifierReportingController,
                              'dropdownItems': qualifierOptions,
                              'typeField': 'dropdown',
                              'onChanged': (value) => onFieldChange('qualifierReporting', value),
                              'key': _getOrCreateKey('QUALIFIER'),
                            },
                            {
                              'label': 'NICKNAME',
                              'required': true,
                              'controller': _nicknameReportingController,
                              'keyboardType': TextInputType.text,
                              'key': _getOrCreateKey('NICKNAME'),
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),
                          FormRowInputs(
                          fields: [
                            {
                              'label': 'CITIZENSHIP',
                              'required': true,
                              'controller': _citizenshipReportingController,
                              'dropdownItems': citizenshipOptions,
                              'section': 'reporting',
                              'key': _getOrCreateKey('CITIZENSHIP'),
                            },
                            {
                              'label': 'SEX/GENDER',
                              'required': true,
                              'controller': _sexGenderReportingController,
                              'dropdownItems': genderOptions,
                              'typeField': 'dropdown',
                              'key': _getOrCreateKey('SEX/GENDER'),
                              'onChanged': (value) {
                                setState(() {
                                  _sexGenderReportingController.text = value ?? '';
                                });
                              },
                            },
                            {
                              'label': 'CIVIL STATUS',
                              'required': true,
                              'controller': _civilStatusReportingController,
                              'dropdownItems': civilStatusOptions,
                              'key': _getOrCreateKey('CIVIL STATUS'),
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),
                          FormRowInputs(
                          fields: [
                            {
                              'label': 'DATE OF BIRTH',
                              'required': true,
                              'controller': _dateOfBirthReportingController,
                              'key': _getOrCreateKey('DATE OF BIRTH'),
                              'isDateDropdown': true,
                              'section': 'reporting',
                              'context': context,
                              'selectedDay': selectedDayReporting,
                              'selectedMonth': selectedMonthReporting,
                              'selectedYear': selectedYearReporting,
                              'getDaysInMonth': _getDaysInMonthReporting,
                              'updateDateFromDropdowns': _updateReportingDateFromDropdowns,
                              'onDateFieldChange': (String key, dynamic value) {
                                setState(() {
                                  switch (key) {
                                    case 'selectedDayReporting':
                                      selectedDayReporting = value;
                                      break;
                                    case 'selectedMonthReporting':
                                      selectedMonthReporting = value;
                                      break;
                                    case 'selectedYearReporting':
                                      selectedYearReporting = value;
                                      break;
                                  }
                                });
                              },
                            },
                            {
                              'label': 'AGE',
                              'required': true,
                              'controller': _ageReportingController,
                              'readOnly': true,
                              'key': _getOrCreateKey('AGE'),
                            },
                            {
                              'label': 'PLACE OF BIRTH',
                              'required': true,
                              'controller': _placeOfBirthReportingController,
                              'keyboardType': TextInputType.text,
                              'key': _getOrCreateKey('PLACE OF BIRTH'),
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                          SizedBox(height: 10),                        
                        
                        SubsectionTitle(
                          title: 'Contact Information',
                          icon: Icons.phone,
                        ),

                        SizedBox(height: 10),
                        
                        FormRowInputs(
                          fields: [
                            {
                              'label': 'HOME PHONE (If Any)',
                              'required': false,
                              'controller': _homePhoneReportingController,
                              'keyboardType': TextInputType.text,
                              'hintText': 'Enter Home Phone Number or leave empty',
                              'key': _getOrCreateKey('HOME PHONE'),
                            },
                            {
                              'label': 'MOBILE PHONE',
                              'required': true,
                              'controller': _mobilePhoneReportingController,
                              'keyboardType': TextInputType.phone,
                              'hintText': 'Enter Phone Number',
                              'key': _getOrCreateKey('MOBILE PHONE'),
                              'inputFormatters': [FilteringTextInputFormatter.digitsOnly],
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),
                        
                        SubsectionTitle(
                          title: 'Address Information',
                          icon: Icons.location_on,
                        ),

                        SizedBox(height: 10),
                        
                        FormRowInputs(
                          fields: [
                            {
                              'label': 'CURRENT ADDRESS (HOUSE NUMBER/STREET)',
                              'required': true,
                              'controller': _currentAddressReportingController,
                              'keyboardType': TextInputType.text,
                              'key': _getOrCreateKey('CURRENT ADDRESS (HOUSE NUMBER/STREET)'),
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),
                        
                        FormRowInputs(
                          fields: [
                            {
                              'label': 'VILLAGE/SITIO',
                              'required': true,
                              'controller': _villageSitioReportingController,
                              'keyboardType': TextInputType.text,
                              'key': _getOrCreateKey('VILLAGE/SITIO'),
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),
                        
                        Divider(
                          color: const Color.fromARGB(255, 119, 119, 119),
                          thickness: 2,
                        ),
                        
                        SizedBox(height: 5),
                          FormRowInputs(
                          fields: [
                            {
                              'label': 'REGION',
                              'required': true,
                              'section': 'reporting',
                              'key': _getOrCreateKey('REGION REPORTING'),
                            },
                            {
                              'label': 'PROVINCE',
                              'required': true,
                              'section': 'reporting',
                              'key': _getOrCreateKey('PROVINCE REPORTING'),
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),
                          FormRowInputs(
                          fields: [
                            {
                              'label': 'TOWN/CITY',
                              'required': true,
                              'section': 'reporting',
                              'key': _getOrCreateKey('TOWN/CITY REPORTING'),
                            },
                            {
                              'label': 'BARANGAY',
                              'required': true,
                              'section': 'reporting',
                              'key': _getOrCreateKey('BARANGAY REPORTING'),
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),

                        CheckboxListTile(
                          title: Text("Do you have another address?", style: TextStyle(fontSize: 15, color: Colors.black)),
                          value: hasOtherAddressReporting,
                          onChanged: (bool? value) {
                            setState(() {
                              hasOtherAddressReporting = value ?? false;
                            });
                          },
                        ),
                        
                        if (hasOtherAddressReporting) ...[
                          FormRowInputs(
                            fields: [
                              {
                                'label': 'OTHER ADDRESS (HOUSE NUMBER/STREET)',
                                'required': true,
                                'keyboardType': TextInputType.text,
                              },
                            ],
                            formState: formState,
                            onFieldChange: onFieldChange,
                          ),
                             
                          SizedBox(height: 10),
                          
                          FormRowInputs(
                            fields: [
                              {
                                'label': 'VILLAGE/SITIO',
                                'required': true,
                                'keyboardType': TextInputType.text,
                              },
                            ],
                            formState: formState,
                            onFieldChange: onFieldChange,
                          ),
                          
                          SizedBox(height: 10),
                          
                          Divider(
                            color: const Color.fromARGB(255, 119, 119, 119),
                            thickness: 2,
                          ),
                          
                          SizedBox(height: 5),
                          
                          FormRowInputs(
                            fields: [
                              {
                                'label': 'REGION',
                                'required': true,
                                'section': 'reportingOther',
                              },
                              {
                                'label': 'PROVINCE',
                                'required': true,
                                'section': 'reportingOther',
                              },
                            ],
                            formState: formState,
                            onFieldChange: onFieldChange,
                          ),
                          
                          SizedBox(height: 10),
                          
                          FormRowInputs(
                            fields: [
                              {
                                'label': 'TOWN/CITY',
                                'required': true,
                                'section': 'reportingOther',
                              },
                              {
                                'label': 'BARANGAY',
                                'required': true,
                                'section': 'reportingOther',
                              },
                            ],
                            formState: formState,
                            onFieldChange: onFieldChange,
                          ),
                          
                          SizedBox(height: 10),
                        ],

                        SizedBox(height: 10),
                                    FormRowInputs(
                          fields: [
                            {
                              'label': 'HIGHEST EDUCATION ATTAINMENT',
                              'required': true,
                              'controller': _educationReportingController,
                              'dropdownItems': educationOptions,
                              'section': 'reporting',
                              'key': _getOrCreateKey('HIGHEST EDUCATION ATTAINMENT'),
                            },
                            {
                              'label': 'OCCUPATION',
                              'required': true,
                              'controller': _occupationReportingController,
                              'dropdownItems': occupationOptions,
                              'section': 'reporting',
                              'key': _getOrCreateKey('OCCUPATION'),
                              'onChanged': (value) {
                                setState(() {
                                  _occupationReportingController.text = value ?? '';
                                  reportingPersonOccupation = value;
                                });
                              },
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),
                        
                        FormRowInputs(
                          fields: [
                            {
                              'label': 'ID CARD PRESENTED',
                              'required': true,
                              'controller': _idCardPresentedController,
                              'keyboardType': TextInputType.text,
                            },
                            {
                              'label': 'EMAIL ADDRESS (If Any)',
                              'required': false,
                              'controller': _emailReportingController,
                              'keyboardType': TextInputType.emailAddress,
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),

                        SectionTitle(
                          title: "MISSING PERSON'S DATA",
                          backgroundColor: Color(0xFF1E215A),
                        ),
                        
                        SizedBox(height: 10),
                        
                        SubsectionTitle(
                          title: 'Personal Information',
                          icon: Icons.person_search,
                        ),

                        SizedBox(height: 10),
                        
                        FormRowInputs(
                          fields: [
                            {
                              'label': 'SURNAME',
                              'required': true,
                              'controller': _surnameVictimController,
                              'keyboardType': TextInputType.name,
                              'inputFormatters': [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                              'key': _getOrCreateKey('SURNAME VICTIM'),
                            },
                            {
                              'label': 'FIRST NAME',
                              'required': true,
                              'controller': _firstNameVictimController,
                              'keyboardType': TextInputType.name,
                              'inputFormatters': [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                              'key': _getOrCreateKey('FIRST NAME VICTIM'),
                            },
                            {
                              'label': 'MIDDLE NAME',
                              'required': true,
                              'controller': _middleNameVictimController,
                              'keyboardType': TextInputType.name,
                              'inputFormatters': [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                              'key': _getOrCreateKey('MIDDLE NAME VICTIM'),
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),
                          KeyedSubtree(
                          key: _getOrCreateKey('QUALIFIER VICTIM'),
                          child: FormRowInputs(
                            fields: [
                              {
                                'label': 'QUALIFIER',
                                'required': true,
                                'controller': _qualifierVictimController,
                                'dropdownItems': qualifierOptions,
                                'typeField': 'dropdown',
                                'onChanged': (value) {
                                  setState(() {
                                    _qualifierVictimController.text = value ?? '';
                                  });
                                },
                              },
                              {
                                'label': 'NICKNAME',
                                'required': true,
                                'controller': _nicknameVictimController,
                                'keyboardType': TextInputType.text,
                                'key': _getOrCreateKey('NICKNAME VICTIM'),
                              },
                            ],
                            formState: formState,
                            onFieldChange: onFieldChange,
                          ),
                        ),
                        
                        SizedBox(height: 10),
                          FormRowInputs(
                          fields: [
                            {
                              'label': 'CITIZENSHIP',
                              'required': true,
                              'controller': _citizenshipVictimController,
                              'dropdownItems': citizenshipOptions,
                              'section': 'victim',
                              'key': _getOrCreateKey('CITIZENSHIP VICTIM'),
                            },
                            {
                              'label': 'SEX/GENDER',
                              'required': true,
                              'controller': _sexGenderVictimController,
                              'dropdownItems': genderOptions,
                              'typeField': 'dropdown',
                              'key': _getOrCreateKey('SEX/GENDER VICTIM'),
                              'onChanged': (value) {
                                setState(() {
                                  _sexGenderVictimController.text = value ?? '';
                                });
                              },
                            },
                            {
                              'label': 'CIVIL STATUS',
                              'required': true,
                              'controller': _civilStatusVictimController,
                              'dropdownItems': civilStatusOptions,
                              'key': _getOrCreateKey('CIVIL STATUS VICTIM'),
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),
                          FormRowInputs(
                          fields: [
                            {
                              'label': 'DATE OF BIRTH',
                              'required': true,
                              'controller': _dateOfBirthVictimController,
                              'key': _getOrCreateKey('DATE OF BIRTH VICTIM'),
                              'isDateDropdown': true,
                              'section': 'victim',
                              'context': context,
                              'selectedDay': selectedDayVictim,
                              'selectedMonth': selectedMonthVictim,
                              'selectedYear': selectedYearVictim,
                              'getDaysInMonth': _getDaysInMonthVictim,
                              'updateDateFromDropdowns': _updateVictimDateFromDropdowns,
                              'onDateFieldChange': (String key, dynamic value) {
                                setState(() {
                                  switch (key) {
                                    case 'selectedDayVictim':
                                      selectedDayVictim = value;
                                      break;
                                    case 'selectedMonthVictim':
                                      selectedMonthVictim = value;
                                      break;
                                    case 'selectedYearVictim':
                                      selectedYearVictim = value;
                                      break;
                                  }
                                });
                              },
                            },
                            {
                              'label': 'AGE',
                              'required': true,
                              'controller': _ageVictimController,
                              'readOnly': true,
                              'key': _getOrCreateKey('AGE VICTIM'),
                            },
                            {
                              'label': 'PLACE OF BIRTH',
                              'required': true,
                              'controller': _placeOfBirthVictimController,
                              'keyboardType': TextInputType.text,
                              'key': _getOrCreateKey('PLACE OF BIRTH VICTIM'),
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),
                        
                        SubsectionTitle(
                          title: 'Contact Information',
                          icon: Icons.phone,
                        ),

                        SizedBox(height: 10),
                        
                        FormRowInputs(
                          fields: [
                            {
                              'label': 'HOME PHONE (If Any)',
                              'required': false,
                              'controller': _homePhoneVictimController,
                              'keyboardType': TextInputType.text,
                              'hintText': 'Enter Home Phone Number or leave empty',
                              'key': _getOrCreateKey('HOME PHONE VICTIM'),
                            },
                            {
                              'label': 'MOBILE PHONE',
                              'required': true,
                              'controller': _mobilePhoneVictimController,
                              'keyboardType': TextInputType.phone,
                              'hintText': 'Enter Phone Number',
                              'key': _getOrCreateKey('MOBILE PHONE VICTIM'),
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SubsectionTitle(
                          title: 'Address Information',
                          icon: Icons.location_on,
                        ),

                        SizedBox(height: 10),
                        
                        // Checkbox for copying address from reporting person
                        CheckboxListTile(
                          title: Text("Same address as reporting person?", style: TextStyle(fontSize: 15, color: Colors.black)),
                          value: sameAddressAsReporting,
                          onChanged: (bool? value) {
                            setState(() {
                              sameAddressAsReporting = value ?? false;
                              if (sameAddressAsReporting) {
                                copyReportingAddressToVictim();
                              } else {
                                restoreVictimAddress();
                              }
                            });
                          },
                        ),
                        
                        SizedBox(height: 10),
                          FormRowInputs(
                          fields: [
                            {
                              'label': 'CURRENT ADDRESS (HOUSE NUMBER/STREET)',
                              'required': true,
                              'controller': _currentAddressVictimController,
                              'keyboardType': TextInputType.text,
                              'key': _getOrCreateKey('CURRENT ADDRESS (HOUSE NUMBER/STREET) VICTIM'),
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),
                        
                        FormRowInputs(
                          fields: [
                            {
                              'label': 'VILLAGE/SITIO',
                              'required': true,
                              'controller': _villageSitioVictimController,
                              'keyboardType': TextInputType.text,
                              'key': _getOrCreateKey('VILLAGE/SITIO VICTIM'),
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),
                        
                        Divider(
                          color: const Color.fromARGB(255, 119, 119, 119),
                          thickness: 2,
                        ),
                        
                        SizedBox(height: 5),
                          FormRowInputs(
                          fields: [
                            {
                              'label': 'REGION',
                              'required': true,
                              'section': 'victim',
                              'key': _getOrCreateKey('REGION VICTIM'),
                            },
                            {
                              'label': 'PROVINCE',
                              'required': true,
                              'section': 'victim',
                              'key': _getOrCreateKey('PROVINCE VICTIM'),
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),
                          FormRowInputs(
                          fields: [
                            {
                              'label': 'TOWN/CITY',
                              'required': true,
                              'section': 'victim',
                              'key': _getOrCreateKey('TOWN/CITY VICTIM'),
                            },
                            {
                              'label': 'BARANGAY',
                              'required': true,
                              'section': 'victim',
                              'key': _getOrCreateKey('BARANGAY VICTIM'),
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),

                        CheckboxListTile(
                          title: Text("Do you have another address?", style: TextStyle(fontSize: 15, color: Colors.black)),
                          value: hasOtherAddressVictim,
                          onChanged: (bool? value) {
                            setState(() {
                              hasOtherAddressVictim = value ?? false;
                            });
                          },
                        ),
                        
                        if (hasOtherAddressVictim) ...[
                          FormRowInputs(
                            fields: [
                              {
                                'label': 'OTHER ADDRESS (HOUSE NUMBER/STREET)',
                                'required': true,
                                'keyboardType': TextInputType.text,
                              },
                            ],
                            formState: formState,
                            onFieldChange: onFieldChange,
                          ),
                             
                          SizedBox(height: 10),
                          
                          FormRowInputs(
                            fields: [
                              {
                                'label': 'VILLAGE/SITIO',
                                'required': true,
                                'keyboardType': TextInputType.text,
                              },
                            ],
                            formState: formState,
                            onFieldChange: onFieldChange,
                          ),
                          
                          SizedBox(height: 10),
                          
                          Divider(
                            color: const Color.fromARGB(255, 119, 119, 119),
                            thickness: 2,
                          ),
                          
                          SizedBox(height: 5),
                          
                          FormRowInputs(
                            fields: [
                              {
                                'label': 'REGION',
                                'required': true,
                                'section': 'victimOther',
                              },
                              {
                                'label': 'PROVINCE',
                                'required': true,
                                'section': 'victimOther',
                              },
                            ],
                            formState: formState,
                            onFieldChange: onFieldChange,
                          ),
                          
                          SizedBox(height: 10),
                          
                          FormRowInputs(
                            fields: [
                              {
                                'label': 'TOWN/CITY',
                                'required': true,
                                'section': 'victimOther',
                              },
                              {
                                'label': 'BARANGAY',
                                'required': true,
                                'section': 'victimOther',
                              },
                            ],
                            formState: formState,
                            onFieldChange: onFieldChange,
                          ),
                          
                          SizedBox(height: 10),
                        ],                        FormRowInputs(
                          fields: [
                            {
                              'label': 'HIGHEST EDUCATION ATTAINMENT',
                              'required': true,
                              'controller': _educationVictimController,
                              'dropdownItems': educationOptions,
                              'section': 'victim',
                              'key': _getOrCreateKey('HIGHEST EDUCATION ATTAINMENT VICTIM'),
                            },
                            {
                              'label': 'OCCUPATION',
                              'required': true,
                              'controller': _occupationVictimController,
                              'dropdownItems': occupationOptions,
                              'section': 'victim',
                              'key': _getOrCreateKey('OCCUPATION VICTIM'),
                              'onChanged': (value) {
                                setState(() {
                                  _occupationVictimController.text = value ?? '';
                                  victimOccupation = value;
                                });
                              },
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),                        FormRowInputs(
                          fields: [
                            {
                              'label': 'ID CARD PRESENTED',
                              'required': true,
                              'controller': _idCardVictimController,
                              'keyboardType': TextInputType.text,
                              'key': _getOrCreateKey('ID CARD PRESENTED VICTIM'),
                            },
                            {
                              'label': 'EMAIL ADDRESS (If Any)',
                              'required': false,
                              'controller': _emailVictimController,
                              'keyboardType': TextInputType.emailAddress,
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),

                        SectionTitle(
                          title: 'NARRATIVE OF INCIDENT',
                          backgroundColor: Color(0xFF1E215A),
                        ),
                        
                        SizedBox(height: 10),
                        
                        SubsectionTitle(
                          title: 'Incident Details',
                          icon: Icons.info_outline,
                        ),

                        SizedBox(height: 10),
                        
                        // Type of Incident, Date/Time of Incident, Place of Incident moved here
                        FormRowInputs(
                          fields: [
                            {
                              'label': 'TYPE OF INCIDENT',
                              'required': true,
                              'controller': _typeOfIncidentController,
                              'readOnly': true,
                              'backgroundColor': Color(0xFFF0F0F0),
                              'key': _getOrCreateKey('TYPE OF INCIDENT'),
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),
                        
                        FormRowInputs(
                          fields: [
                            {
                              'label': 'DATE/TIME OF INCIDENT',
                              'required': true,
                              'isIncidentDateTime': true,
                              'key': _getOrCreateKey('DATE/TIME OF INCIDENT'),
                              'displayText': dateTimeIncident != null 
                                ? _formatDateTime(dateTimeIncident!)
                                : 'Select',
                              'onTap': () {
                                _pickIncidentDateTime();
                              },
                            },
                            {
                              'label': 'PLACE OF INCIDENT',
                              'required': true,
                              'controller': _placeOfIncidentController,
                              'keyboardType': TextInputType.text,
                              'key': _getOrCreateKey('PLACE OF INCIDENT'),
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),
                        
                        SubsectionTitle(
                          title: 'Narrative Description',
                          icon: Icons.description,
                        ),

                        SizedBox(height: 10),
                        
                        KeyedSubtree(
                          key: _getOrCreateKey('NARRATIVE OF INCIDENT'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '* ',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        "ENTER IN DETAIL THE NARRATIVE OF INCIDENT OR EVENT, ANSWERING THE WHO, WHAT, WHEN, WHERE, WHY AND HOW OF REPORTING",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 11,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                TextFormField(
                                  controller: _narrativeController,
                                  maxLines: 10,
                                  style: TextStyle(fontSize: 15, color: Colors.black),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.black),
                                    ),
                                    contentPadding: EdgeInsets.all(8),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Narrative is required';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16),
                                Center(
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
                                            // Validation status indicator
                                            if (_validationStatus != ValidationStatus.none) ...[
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: _getValidationStatusColor(),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      _getValidationStatusIcon(),
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      _getValidationStatusText(),
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                            ],
                                            if (_isProcessingImage) ...[
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      width: 12,
                                                      height: 12,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                      ),
                                                    ),
                                                    SizedBox(width: 8),
                                                    Text(
                                                      'Processing image...',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 8),
                                            ],
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
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      bottomNavigationBar: SubmitButton(
        formKey: _formKey,
        onSubmit: () async {
          if (!(await _validateAllRequiredFields())) {
            return;
          }
          await submitForm();
        },
        isSubmitting: isSubmitting,
      ),
    );
  }
}

// Modified SubmitButton to show loading state
class SubmitButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final Function()? onSubmit;
  final bool isSubmitting;

  const SubmitButton({
    Key? key,
    required this.formKey,
    this.onSubmit,
    this.isSubmitting = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.white,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF0D47A1),
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: isSubmitting ? null : onSubmit,
        child: isSubmitting 
          ? SizedBox(
              height: 20, 
              width: 20, 
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              )
            )
          : Text(
              'SUBMIT',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
      ),
    );
  }
}