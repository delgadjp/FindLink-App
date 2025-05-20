import '/core/app_export.dart';
import 'package:philippines_rpcmb/philippines_rpcmb.dart';
import 'package:intl/intl.dart';
import '../core/network/irf_service.dart';
import '../models/irf_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'dart:ui'; // Added import for ImageFilter

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
  bool isSavingDraft = false;
  bool hasAcceptedPrivacyPolicy = false;
  bool isCheckingPrivacyStatus = true;
  
  // Image handling variables
  File? _imageFile;
  Uint8List? _webImage;
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

  // Show image source selection dialog
  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt),
            title: Text('Take Photo'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library),
            title: Text('Choose from Gallery'),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    );
  }
  
  // Image picking and validation
  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isProcessingImage = true);
      
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null) {
        dynamic imageData;
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          imageData = bytes;
          setState(() => _webImage = bytes);
        } else {
          final file = File(pickedFile.path);
          imageData = file;
          setState(() => _imageFile = file);
        }
        
        // Validate image using service
        try {
          final validationResult = await _irfService.validateImageWithGoogleVision(imageData);
          
          setState(() {
            if (!validationResult['isValid']) {
              _validationMessage = 'Error validating image: ${validationResult['message']}';
              _validationStatus = ValidationStatus.error;
            } else if (!validationResult['containsHuman']) {
              _imageFile = null;
              _webImage = null;
              _validationMessage = 'No person detected in the image. Image has been removed.';
              _validationConfidence = (validationResult['confidence'] * 100).toStringAsFixed(1);
              _validationStatus = ValidationStatus.noHuman;
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Image removed - no person detected'),
                  backgroundColor: Colors.orange,
                ),
              );
            } else {
              _validationMessage = 'Person detected in image!';
              _validationConfidence = (validationResult['confidence'] * 100).toStringAsFixed(1);
              _validationStatus = ValidationStatus.humanDetected;
            }
          });
        } catch (e) {
          setState(() {
            _validationMessage = 'Image validation error: ${e.toString()}';
            _validationStatus = ValidationStatus.warning;
          });
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
  
  // Reference to Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  // Service for Firebase operations
  final IRFService _irfService = IRFService();
  
  // General information controllers
  final TextEditingController _typeOfIncidentController = TextEditingController();
  final TextEditingController _copyForController = TextEditingController();
  final TextEditingController _dateTimeReportedController = TextEditingController();
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

  @override
  void initState() {
    super.initState();
    // Initialize with current date and time
    dateTimeReported = DateTime.now();
    _dateTimeReportedController.text = _formatDateTime(dateTimeReported!);
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
      
      // Get selected ID type from IRFService
      String? selectedIDType = await _irfService.getUserSelectedIDType();
      
      final userQuery = await FirebaseFirestore.instance
          .collection('users-app')
          .where('userId', isEqualTo: currentUser.uid)
          .limit(1)
          .get();
      if (userQuery.docs.isNotEmpty) {
        final userData = userQuery.docs.first.data() as Map<String, dynamic>;
        setState(() {
          _surnameReportingController.text = userData['lastName'] ?? '';
          _firstNameReportingController.text = userData['firstName'] ?? '';          _middleNameReportingController.text = userData['middleName'] ?? '';
          _emailReportingController.text = userData['email'] ?? '';
          _sexGenderReportingController.text = userData['gender'] ?? '';
          _ageReportingController.text = userData['age'] != null ? userData['age'].toString() : '';
          _idCardPresentedController.text = selectedIDType ?? '';
          if (userData['dateOfBirth'] != null) {
            DateTime dob;
            if (userData['dateOfBirth'] is Timestamp) {
              dob = (userData['dateOfBirth'] as Timestamp).toDate();
            } else if (userData['dateOfBirth'] is String) {
              dob = DateTime.tryParse(userData['dateOfBirth']) ?? DateTime.now();
            } else {
              dob = DateTime.now();
            }
            _dateOfBirthReportingController.text = "${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}";
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
          
        // Add missing victim address field handlers
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
        case 'civilStatusVictim':
          _civilStatusVictimController.text = value;
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

  @override
  void dispose() {
    // Dispose all controllers
    // General information controllers
    _typeOfIncidentController.dispose();
    _copyForController.dispose();
    _dateTimeReportedController.dispose();
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
      'copyFor': _copyForController.text,
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
  }
    // Submit form to Firebase
  Future<void> submitForm() async {
    if (!_formKey.currentState!.validate()) {
      // Show validation error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields correctly'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Additional validation for education fields
    if (_educationReportingController.text.isEmpty || _educationVictimController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select education level for both reporting person and missing person'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Image is required
    if ((!kIsWeb && _imageFile == null) || (kIsWeb && _webImage == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload an image. It is required.'),
          backgroundColor: Colors.red,
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
      
      // Show success message with formal ID
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Form submitted successfully! Reference #: $formalId'),
          backgroundColor: Colors.green,
        ),
      );
      
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
  
  // Check for duplicate missing person
  Future<bool> _checkDuplicateMissingPerson() async {
    final surname = _surnameVictimController.text.trim().toLowerCase();
    final firstName = _firstNameVictimController.text.trim().toLowerCase();
    final middleName = _middleNameVictimController.text.trim().toLowerCase();
    final dob = _dateOfBirthVictimController.text.trim();
    if (surname.isEmpty || firstName.isEmpty || middleName.isEmpty || dob.isEmpty) {
      return false;
    }
    final query = await FirebaseFirestore.instance
        .collection('incidents')
        .where('itemC.familyName', isEqualTo: surname)
        .where('itemC.firstName', isEqualTo: firstName)
        .where('itemC.middleName', isEqualTo: middleName)
        .where('itemC.dateOfBirth', isEqualTo: dob)
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  }

  @override  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0D47A1),
        actions: [
          // ...existing code...
        ],
      ),
      drawer: AppDrawer(),
      body: isCheckingPrivacyStatus 
        ? Center(child: CircularProgressIndicator()) // Show loading while checking privacy status
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
                        // --- Wrap each required field in a KeyedSubtree for scrolling ---
                        KeyedSubtree(
                          key: _getOrCreateKey('TYPE OF INCIDENT'),
                          child: FormRowInputs(
                            fields: [
                              {
                                'label': 'TYPE OF INCIDENT',
                                'required': true,
                                'keyboardType': TextInputType.text,
                                'controller': _typeOfIncidentController,
                                'readOnly': true, // Make it read-only
                                'backgroundColor': Color(0xFFF0F0F0), // Light gray background to indicate fixed field
                              },
                              {
                                'label': 'COPY FOR',
                                'required': true,
                                'controller': _copyForController,
                              },
                            ],
                            formState: formState,
                            onFieldChange: onFieldChange,
                          ),
                        ),
                        
                        SizedBox(height: 10),
                         
                        KeyedSubtree(
                          key: _getOrCreateKey('DATE AND TIME REPORTED'),
                          child: FormRowInputs(
                            fields: [
                              {
                                'label': 'DATE AND TIME REPORTED',
                                'required': true,
                                'controller': _dateTimeReportedController,
                                'readOnly': true,
                              },
                              {
                                'label': 'DATE AND TIME OF INCIDENT',
                                'required': true,
                                'controller': _dateTimeIncidentController,
                                'readOnly': true,
                                'onTap': () {
                                  _pickDateTime(
                                    _dateTimeIncidentController,
                                    dateTimeIncident,
                                    (DateTime selectedDateTime) {
                                      setState(() {
                                        dateTimeIncident = selectedDateTime;
                                        // Sync with Item D dateTime
                                        _dateTimeIncidentDController.text = _formatDateTime(selectedDateTime);
                                      });
                                    },
                                  );
                                },
                              },
                              {
                                'label': 'PLACE OF INCIDENT',
                                'required': true,
                                'controller': _placeOfIncidentController,
                                'keyboardType': TextInputType.text,
                              },
                            ],
                            formState: formState,
                            onFieldChange: onFieldChange,
                          ),
                        ),
                        
                        SizedBox(height: 10),

                        // Section title using the new component
                        SectionTitle(
                          title: 'REPORTING PERSON',
                          backgroundColor: Color(0xFF1E215A),
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
                              },
                              {
                                'label': 'FIRST NAME',
                                'required': true,
                                'controller': _firstNameReportingController,
                                'keyboardType': TextInputType.name,
                                'inputFormatters': [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                              },
                              {
                                'label': 'MIDDLE NAME',
                                'required': true,
                                'controller': _middleNameReportingController,
                                'keyboardType': TextInputType.name,
                                'inputFormatters': [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                              },
                            ],
                            formState: formState,
                            onFieldChange: onFieldChange,
                          ),
                        ),
                        
                        SizedBox(height: 10),
                        
                        KeyedSubtree(
                          key: _getOrCreateKey('QUALIFIER'),
                          child: FormRowInputs(
                            fields: [
                              {
                                'label': 'QUALIFIER',
                                'required': true,
                                'controller': _qualifierReportingController,
                                'dropdownItems': qualifierOptions,
                                'typeField': 'dropdown',
                                'onChanged': (value) => onFieldChange('qualifierReporting', value),
                              },
                              {
                                'label': 'NICKNAME',
                                'required': true,
                                'controller': _nicknameReportingController,
                                'keyboardType': TextInputType.text,
                              },
                            ],
                            formState: formState,
                            onFieldChange: onFieldChange,
                          ),
                        ),
                        
                        SizedBox(height: 10),
                        
                        KeyedSubtree(
                          key: _getOrCreateKey('CITIZENSHIP'),
                          child: FormRowInputs(
                            fields: [
                              {
                                'label': 'CITIZENSHIP',
                                'required': true,
                                'controller': _citizenshipReportingController,
                                'dropdownItems': citizenshipOptions,
                                'section': 'reporting',
                              },
                              {
                                'label': 'SEX/GENDER',
                                'required': true,
                                'controller': _sexGenderReportingController,
                                'dropdownItems': genderOptions,
                              },
                              {
                                'label': 'CIVIL STATUS',
                                'required': true,
                                'controller': _civilStatusReportingController,
                                'dropdownItems': civilStatusOptions,
                              },
                            ],
                            formState: formState,
                            onFieldChange: onFieldChange,
                          ),
                        ),
                        
                        SizedBox(height: 10),
                        
                        KeyedSubtree(
                          key: _getOrCreateKey('DATE OF BIRTH'),
                          child: FormRowInputs(
                            fields: [
                              {
                                'label': 'DATE OF BIRTH',
                                'required': true,
                                'controller': _dateOfBirthReportingController,
                                'readOnly': true,
                                'onTap': () async {
                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(1950),
                                    lastDate: DateTime.now(),
                                  );
                                  if (pickedDate != null) {
                                    setState(() {
                                      _dateOfBirthReportingController.text = 
                                          "${pickedDate.day.toString().padLeft(2, '0')}/"
                                          "${pickedDate.month.toString().padLeft(2, '0')}/"
                                          "${pickedDate.year}";
                                      reportingPersonAge = calculateAge(pickedDate);
                                      _ageReportingController.text = reportingPersonAge.toString();
                                    });
                                  }
                                },
                              },
                              {
                                'label': 'AGE',
                                'required': true,
                                'controller': _ageReportingController,
                                'readOnly': true,
                              },
                              {
                                'label': 'PLACE OF BIRTH',
                                'required': true,
                                'controller': _placeOfBirthReportingController,
                                'keyboardType': TextInputType.text,
                              },
                            ],
                            formState: formState,
                            onFieldChange: onFieldChange,
                          ),
                        ),
                        
                        SizedBox(height: 10),
                        
                        FormRowInputs(
                          fields: [                            {
                              'label': 'HOME PHONE',
                              'required': true,
                              'controller': _homePhoneReportingController,
                              'keyboardType': TextInputType.text,
                              'hintText': 'Enter phone number or N/A',
                              'validator': (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                if (value.toLowerCase() == 'n/a' || value.toLowerCase() == 'none') return null;
                                if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Enter valid number or N/A';
                                return null;
                              },
                            },
                            {
                              'label': 'MOBILE PHONE',
                              'required': true,
                              'controller': _mobilePhoneReportingController,
                              'keyboardType': TextInputType.phone,
                              'inputFormatters': [FilteringTextInputFormatter.digitsOnly],
                              'validator': (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                if (value.length < 10) return 'Invalid phone number';
                                return null;
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
                              'label': 'CURRENT ADDRESS (HOUSE NUMBER/STREET)',
                              'required': true,
                              'controller': _currentAddressReportingController,
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
                              'controller': _villageSitioReportingController,
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
                              'section': 'reporting',
                            },
                            {
                              'label': 'PROVINCE',
                              'required': true,
                              'section': 'reporting',
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
                            },
                            {
                              'label': 'BARANGAY',
                              'required': true,
                              'section': 'reporting',
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
                            },
                            {
                              'label': 'OCCUPATION',
                              'required': true,
                              'controller': _occupationReportingController,
                              'dropdownItems': occupationOptions,
                              'section': 'reporting',
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

                        KeyedSubtree(
                          key: _getOrCreateKey('SURNAME VICTIM'),
                          child: FormRowInputs(
                            fields: [
                              {
                                'label': 'SURNAME',
                                'required': true,
                                'controller': _surnameVictimController,
                                'keyboardType': TextInputType.name,
                                'inputFormatters': [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                              },
                              {
                                'label': 'FIRST NAME',
                                'required': true,
                                'controller': _firstNameVictimController,
                                'keyboardType': TextInputType.name,
                                'inputFormatters': [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                              },
                              {
                                'label': 'MIDDLE NAME',
                                'required': true,
                                'controller': _middleNameVictimController,
                                'keyboardType': TextInputType.name,
                                'inputFormatters': [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                              },
                            ],
                            formState: formState,
                            onFieldChange: onFieldChange,
                          ),
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
                              },
                            ],
                            formState: formState,
                            onFieldChange: onFieldChange,
                          ),
                        ),
                        
                        SizedBox(height: 10),
                        
                        KeyedSubtree(
                          key: _getOrCreateKey('CITIZENSHIP VICTIM'),
                          child: FormRowInputs(
                            fields: [
                              {
                                'label': 'CITIZENSHIP',
                                'required': true,
                                'controller': _citizenshipVictimController,
                                'dropdownItems': citizenshipOptions,
                                'section': 'victim',
                            },
                            {
                              'label': 'SEX/GENDER',
                              'required': true,
                              'controller': _sexGenderVictimController,
                              'dropdownItems': genderOptions,
                              'typeField': 'dropdown',
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
                            },
                            ],
                            formState: formState,
                            onFieldChange: onFieldChange,
                          ),
                        ),
                        
                        SizedBox(height: 10),
                        
                        KeyedSubtree(
                          key: _getOrCreateKey('DATE OF BIRTH VICTIM'),
                          child: FormRowInputs(
                            fields: [
                              {
                                'label': 'DATE OF BIRTH',
                                'required': true,
                                'controller': _dateOfBirthVictimController,
                                'readOnly': true,
                                'onTap': () async {
                                  DateTime? pickedDate = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now(),
                                    firstDate: DateTime(1950),
                                    lastDate: DateTime.now(),
                                  );
                                  if (pickedDate != null) {
                                    setState(() {
                                      _dateOfBirthVictimController.text = 
                                          "${pickedDate.day.toString().padLeft(2, '0')}/"
                                          "${pickedDate.month.toString().padLeft(2, '0')}/"
                                          "${pickedDate.year}";
                                      victimAge = calculateAge(pickedDate);
                                      _ageVictimController.text = victimAge.toString();
                                    });
                                  }
                                },
                              },
                              {
                                'label': 'AGE',
                                'required': true,
                                'controller': _ageVictimController,
                                'readOnly': true,
                              },
                              {
                                'label': 'PLACE OF BIRTH',
                                'required': true,
                                'controller': _placeOfBirthVictimController,
                                'keyboardType': TextInputType.text,
                              },
                            ],
                            formState: formState,
                            onFieldChange: onFieldChange,
                          ),
                        ),
                        
                        SizedBox(height: 10),

                        FormRowInputs(
                          fields: [                            {
                              'label': 'HOME PHONE',
                              'required': true,
                              'controller': _homePhoneVictimController,
                              'keyboardType': TextInputType.text,
                              'hintText': 'Enter phone number or N/A',
                              'validator': (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                if (value.toLowerCase() == 'n/a' || value.toLowerCase() == 'none') return null;
                                if (!RegExp(r'^[0-9]+$').hasMatch(value)) return 'Enter valid number or N/A';
                                return null;
                              },
                            },                            {
                              'label': 'MOBILE PHONE',
                              'required': true,
                              'controller': _mobilePhoneVictimController,
                              'keyboardType': TextInputType.phone,
                              'hintText': 'e.g. 09123456789 or +639123456789',
                              'validator': (value) {
                                if (value == null || value.isEmpty) return 'Required';
                                
                                // Remove any whitespace
                                value = value.trim();
                                
                                // Check for Philippine format with country code (+63)
                                if (value.startsWith('+63')) {
                                  if (value.length != 13) return 'Invalid number format';
                                  if (!RegExp(r'^\+63[9][0-9]{9}$').hasMatch(value)) {
                                    return 'Invalid PH mobile number';
                                  }
                                }
                                // Check for local format (09)
                                else if (value.startsWith('0')) {
                                  if (value.length != 11) return 'Invalid number format';
                                  if (!RegExp(r'^09[0-9]{9}$').hasMatch(value)) {
                                    return 'Invalid PH mobile number';
                                  }
                                } 
                                else {
                                  return 'Must start with 09 or +63';
                                }
                                return null;
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
                              'label': 'CURRENT ADDRESS (HOUSE NUMBER/STREET)',
                              'required': true,
                              'controller': _currentAddressVictimController,
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
                              'controller': _villageSitioVictimController,
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
                              'section': 'victim',
                            },
                            {
                              'label': 'PROVINCE',
                              'required': true,
                              'section': 'victim',
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
                            },
                            {
                              'label': 'BARANGAY',
                              'required': true,
                              'section': 'victim',
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
                            },
                            {
                              'label': 'OCCUPATION',
                              'required': true,
                              'controller': _occupationVictimController,
                              'dropdownItems': occupationOptions,
                              'section': 'victim',
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
                        
                        SizedBox(height: 10),
                          FormRowInputs(
                          fields: [
                            {
                              'label': 'ID CARD PRESENTED',
                              'required': true,
                              'controller': _idCardVictimController,
                              'keyboardType': TextInputType.text,
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
                        
                        FormRowInputs(
                          fields: [
                            {
                              'label': 'TYPE OF INCIDENT',
                              'required': true,
                              'controller': _typeOfIncidentDController,
                              'keyboardType': TextInputType.text,
                              'readOnly': true, // Make it read-only
                              'backgroundColor': Color(0xFFF0F0F0), // Light gray background to indicate fixed field
                            },
                            {
                              'label': 'DATE/TIME OF INCIDENT',
                              'required': true,
                              'controller': _dateTimeIncidentDController,
                              'readOnly': true,

                              'onTap': () {
                                _pickDateTime(
                                  _dateTimeIncidentDController,
                                  dateTimeIncident,
                                  (DateTime selectedDateTime) {
                                    setState(() {
                                      dateTimeIncident = selectedDateTime;
                                      // Sync with general dateTime
                                      _dateTimeIncidentController.text = _formatDateTime(selectedDateTime);
                                    });
                                  },
                                );
                              },
                            },
                            {
                              'label': 'PLACE OF INCIDENT',
                              'required': true,
                              'controller': _placeOfIncidentDController,
                              'keyboardType': TextInputType.text,
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),
                        
                        // Narrative section with image picker box (like submit tip)
                        Padding(
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
          // Custom validation and auto-scroll logic
          bool valid = _formKey.currentState!.validate();
          if (!valid) {
            // Find the first required field that is empty
            for (final entry in _requiredFieldKeys.entries) {
              final label = entry.key;
              final key = entry.value;
              // Check if the controller for this label is empty
              TextEditingController? controller;
              switch (label) {
                case 'TYPE OF INCIDENT':
                  controller = _typeOfIncidentController;
                  break;
                case 'COPY FOR':
                  controller = _copyForController;
                  break;
                case 'SURNAME':
                  controller = _surnameReportingController;
                  break;
                case 'FIRST NAME':
                  controller = _firstNameReportingController;
                  break;
                case 'MIDDLE NAME':
                  controller = _middleNameReportingController;
                  break;
                case 'QUALIFIER':
                  controller = _qualifierReportingController;
                  break;
                case 'NICKNAME':
                  controller = _nicknameReportingController;
                  break;
                case 'CITIZENSHIP':
                  controller = _citizenshipReportingController;
                  break;
                case 'SEX/GENDER':
                  controller = _sexGenderReportingController;
                  break;
                case 'CIVIL STATUS':
                  controller = _civilStatusReportingController;
                  break;
                case 'DATE OF BIRTH':
                  controller = _dateOfBirthReportingController;
                  break;
                case 'AGE':
                  controller = _ageReportingController;
                  break;
                case 'PLACE OF BIRTH':
                  controller = _placeOfBirthReportingController;
                  break;
                case 'HOME PHONE':
                  controller = _homePhoneReportingController;
                  break;
                case 'MOBILE PHONE':
                  controller = _mobilePhoneReportingController;
                  break;
                case 'CURRENT ADDRESS (HOUSE NUMBER/STREET)':
                  controller = _currentAddressReportingController;
                  break;
                case 'VILLAGE/SITIO':
                  controller = _villageSitioReportingController;
                  break;
                case 'REGION':
                  controller = null; // Special case, handled by Region selector
                  break;
                case 'PROVINCE':
                  controller = null; // Special case, handled by Province selector
                  break;
                case 'TOWN/CITY':
                  controller = null; // Special case, handled by Municipality selector
                  break;
                case 'BARANGAY':
                  controller = null; // Special case, handled by Barangay selector
                  break;
                // Add all other required fields for victim and narrative sections
                case 'SURNAME VICTIM':
                  controller = _surnameVictimController;
                  break;
                case 'FIRST NAME VICTIM':
                  controller = _firstNameVictimController;
                  break;
                case 'MIDDLE NAME VICTIM':
                  controller = _middleNameVictimController;
                  break;
                case 'QUALIFIER VICTIM':
                  controller = _qualifierVictimController;
                  break;
                case 'NICKNAME VICTIM':
                  controller = _nicknameVictimController;
                  break;
                case 'CITIZENSHIP VICTIM':
                  controller = _citizenshipVictimController;
                  break;
                case 'SEX/GENDER VICTIM':
                  controller = _sexGenderVictimController;
                  break;
                case 'CIVIL STATUS VICTIM':
                  controller = _civilStatusVictimController;
                  break;
                case 'DATE OF BIRTH VICTIM':
                  controller = _dateOfBirthVictimController;
                  break;
                case 'AGE VICTIM':
                  controller = _ageVictimController;
                  break;
                case 'PLACE OF BIRTH VICTIM':
                  controller = _placeOfBirthVictimController;
                  break;
                case 'HOME PHONE VICTIM':
                  controller = _homePhoneVictimController;
                  break;
                case 'MOBILE PHONE VICTIM':
                  controller = _mobilePhoneVictimController;
                  break;
                case 'CURRENT ADDRESS (HOUSE NUMBER/STREET) VICTIM':
                  controller = _currentAddressVictimController;
                  break;
                case 'VILLAGE/SITIO VICTIM':
                  controller = _villageSitioVictimController;
                  break;
                case 'REGION VICTIM':
                  controller = null; // Special case, handled by Region selector
                  break;
                case 'PROVINCE VICTIM':
                  controller = null; // Special case, handled by Province selector
                  break;
                case 'TOWN/CITY VICTIM':
                  controller = null; // Special case, handled by Municipality selector
                  break;
                case 'BARANGAY VICTIM':
                  controller = null; // Special case, handled by Barangay selector
                  break;
                case 'TYPE OF INCIDENT D':
                  controller = _typeOfIncidentDController;
                  break;
                case 'DATE/TIME OF INCIDENT':
                  controller = _dateTimeIncidentDController;
                  break;
                case 'PLACE OF INCIDENT D':
                  controller = _placeOfIncidentDController;
                  break;
                case 'NARRATIVE OF INCIDENT':
                  controller = _narrativeController;
                  break;
              }
              if (controller != null && (controller.text.isEmpty)) {
                // Scroll to the widget
                final context = key.currentContext;
                if (context != null) {
                  Scrollable.ensureVisible(context, duration: Duration(milliseconds: 500), curve: Curves.easeInOut, alignment: 0.10);
                }
                break;
              }
            }
            // Show validation error
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please fill all required fields.'),
                backgroundColor: Colors.red,
              ),
            );
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

