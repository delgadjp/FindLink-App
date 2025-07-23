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
import 'dart:ui'; // Added import for ImageFilter

class FillUpFormScreen extends StatefulWidget {
  const FillUpFormScreen({Key? key}) : super(key: key);
  @override
  FillUpForm createState() => FillUpForm();
}

class FillUpForm extends State<FillUpFormScreen> {
  bool hasOtherAddressReporting = false;
  bool hasOtherAddressVictim = false;
  bool isSubmitting = false;
  bool isSavingDraft = false;
  bool hasAcceptedPrivacyPolicy = false;
  bool isCheckingPrivacyStatus = true;
  
  // Add for copying address from reporting to victim
  bool sameAddressAsReporting = false;
  
  // Image handling variables
  File? _imageFile;
  Uint8List? _webImage;
  final picker = ImagePicker();
  
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
              // Error occurred during validation - remove image
            } else if (!validationResult['containsHuman']) {
              _imageFile = null;
              _webImage = null;
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Image removed - no person detected'),
                  backgroundColor: Colors.orange,
                ),
              );
            } else {
              // Person detected - validation successful
            }
          });
        } catch (e) {
          setState(() {
            // Image validation error occurred
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accessing image: ${e.toString()}')),
      );
    }
  }
  
  // Reference to Firestore
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
          _idCardPresentedController.text = selectedIDType ?? '';          // Handle birthday field for date of birth
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
    // Check reporting person home phone
    final reportingHomePhone = _homePhoneReportingController.text.trim();
    if (reportingHomePhone.isNotEmpty && 
        reportingHomePhone.toLowerCase() != 'n/a' && 
        reportingHomePhone.toLowerCase() != 'none') {
      
      // Philippines Cavite landline format validation
      // Format: (046) XXX-XXXX or 046-XXX-XXXX or 046XXXXXXX
      bool isValidFormat = false;
      
      if (RegExp(r'^\(046\)\s*\d{3}-\d{4}$').hasMatch(reportingHomePhone) || // (046) XXX-XXXX
          RegExp(r'^046-\d{3}-\d{4}$').hasMatch(reportingHomePhone) ||        // 046-XXX-XXXX
          RegExp(r'^046\d{7}$').hasMatch(reportingHomePhone)) {               // 046XXXXXXX
        isValidFormat = true;
      }
      
      if (!isValidFormat) {
        await _scrollToFieldByController(_homePhoneReportingController);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fix the reporting person home phone field before submitting. Enter valid Cavite landline format (046) XXX-XXXX or None.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    
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
      // Check victim home phone
    final victimHomePhone = _homePhoneVictimController.text.trim();
    if (victimHomePhone.isNotEmpty && 
        victimHomePhone.toLowerCase() != 'n/a' && 
        victimHomePhone.toLowerCase() != 'none') {
      
      // Philippines Cavite landline format validation
      // Format: (046) XXX-XXXX or 046-XXX-XXXX or 046XXXXXXX
      bool isValidFormat = false;
      
      if (RegExp(r'^\(046\)\s*\d{3}-\d{4}$').hasMatch(victimHomePhone) || // (046) XXX-XXXX
          RegExp(r'^046-\d{3}-\d{4}$').hasMatch(victimHomePhone) ||        // 046-XXX-XXXX
          RegExp(r'^046\d{7}$').hasMatch(victimHomePhone)) {               // 046XXXXXXX
        isValidFormat = true;
      }
      
      if (!isValidFormat) {
        await _scrollToFieldByController(_homePhoneVictimController);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please fix the missing person home phone field before submitting. Enter valid Cavite landline format (046) XXX-XXXX or None.'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
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
    if (_dateOfBirthReportingController.text.trim().isEmpty) {
      await _scrollToSpecificField('DATE OF BIRTH');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Date of Birth (Reporting Person) is required and cannot be empty.'),
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
    if (_homePhoneReportingController.text.trim().isEmpty) {
      await _scrollToSpecificField('HOME PHONE');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Home Phone (Reporting Person) is required and cannot be empty.'),
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
    if (_dateOfBirthVictimController.text.trim().isEmpty) {
      await _scrollToSpecificField('DATE OF BIRTH VICTIM');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Date of Birth (Missing Person) is required and cannot be empty.'),
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
    if (_homePhoneVictimController.text.trim().isEmpty) {
      await _scrollToSpecificField('HOME PHONE VICTIM');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Home Phone (Missing Person) is required and cannot be empty.'),
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
      _homePhoneReportingController: 'HOME PHONE',
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
      _homePhoneVictimController: 'HOME PHONE VICTIM',
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
    
    // Check if all key identifying information matches
    if (reportingSurname.isNotEmpty && victimSurname.isNotEmpty &&
        reportingFirstName.isNotEmpty && victimFirstName.isNotEmpty &&
        reportingMiddleName.isNotEmpty && victimMiddleName.isNotEmpty &&
        reportingDob.isNotEmpty && victimDob.isNotEmpty) {
      
      if (reportingSurname == victimSurname &&
          reportingFirstName == victimFirstName &&
          reportingMiddleName == victimMiddleName &&
          reportingDob == victimDob) {
        return false; // Same person - validation failed
      }
    }
    
    return true; // Different person - validation passed
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
                              'readOnly': true,
                              'key': _getOrCreateKey('DATE OF BIRTH'),
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
                          SizedBox(height: 10),                        FormRowInputs(
                          fields: [
                            {
                              'label': 'HOME PHONE',
                              'required': true,
                              'controller': _homePhoneReportingController,
                              'keyboardType': TextInputType.text,
                              'hintText': 'Enter Home Phone Number or None',
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
                        
                        SizedBox(height: 10),                        FormRowInputs(
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
                              'readOnly': true,
                              'key': _getOrCreateKey('DATE OF BIRTH VICTIM'),
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
                        
                        SizedBox(height: 10),                        FormRowInputs(
                          fields: [
                            {
                              'label': 'HOME PHONE',
                              'required': true,
                              'controller': _homePhoneVictimController,
                              'keyboardType': TextInputType.text,
                              'hintText': 'Enter Home Phone Number or None',
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
                              'controller': _dateTimeIncidentController,
                              'readOnly': true,
                              'key': _getOrCreateKey('DATE/TIME OF INCIDENT'),
                              'onTap': () {
                                _pickDateTime(
                                  _dateTimeIncidentController,
                                  dateTimeIncident,
                                  (DateTime selectedDateTime) {
                                    setState(() {
                                      dateTimeIncident = selectedDateTime;
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
                              'key': _getOrCreateKey('PLACE OF INCIDENT'),
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
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

