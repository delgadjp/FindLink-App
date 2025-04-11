import '/core/app_export.dart';
import 'package:philippines_rpcmb/philippines_rpcmb.dart';
import 'package:intl/intl.dart';
import '../core/network/irf_service.dart';
import '../models/irf_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  bool isCheckingPrivacyStatus = true; // Flag to track if we're checking privacy status
  
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
  final TextEditingController _workAddressVictimController = TextEditingController();
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
    
    // Preset type of incident to "Missing Person" and make it read-only
    _typeOfIncidentController.text = "Missing Person";
    _typeOfIncidentDController.text = "Missing Person";
    
    // Also initialize the date time incident D controller with the same value if incident date exists
    if (dateTimeIncident != null) {
      _dateTimeIncidentDController.text = _formatDateTime(dateTimeIncident!);
    }
    
    // Initialize formState
    updateFormState();

    // Check if user has already accepted the privacy policy
    checkPrivacyPolicyAcceptance();
  }
  
  // New method to check if user has accepted privacy policy
  Future<void> checkPrivacyPolicyAcceptance() async {
    setState(() {
      isCheckingPrivacyStatus = true;
    });
    
    try {
      final User? currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        // Query Firestore for the current user's document
        final QuerySnapshot userDoc = await _firestore
            .collection('users')
            .where('uid', isEqualTo: currentUser.uid)
            .limit(1)
            .get();
        
        if (userDoc.docs.isNotEmpty) {
          final userData = userDoc.docs.first.data() as Map<String, dynamic>;
          
          // Check if privacy policy acceptance field exists and is true
          if (userData.containsKey('privacyPolicyAccepted') && 
              userData['privacyPolicyAccepted'] == true) {
            setState(() {
              hasAcceptedPrivacyPolicy = true;
            });
          } else {
            // If not accepted, show the privacy policy modal
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showPrivacyPolicyModal();
            });
          }
        } else {
          // No user document found, show the privacy policy
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showPrivacyPolicyModal();
          });
        }
      } else {
        // No user logged in, show the privacy policy
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showPrivacyPolicyModal();
        });
      }
    } catch (e) {
      print('Error checking privacy policy acceptance: $e');
      // On error, default to showing the privacy policy
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showPrivacyPolicyModal();
      });
    } finally {
      setState(() {
        isCheckingPrivacyStatus = false;
      });
    }
  }
  
  // New method to update privacy policy acceptance status in Firestore
  Future<void> updatePrivacyPolicyAcceptance(bool accepted) async {
    try {
      final User? currentUser = _auth.currentUser;
      
      if (currentUser != null) {
        // Find the user's document
        final QuerySnapshot userDoc = await _firestore
            .collection('users')
            .where('uid', isEqualTo: currentUser.uid)
            .limit(1)
            .get();
        
        if (userDoc.docs.isNotEmpty) {
          // Update the user's document with the acceptance status
          await userDoc.docs.first.reference.update({
            'privacyPolicyAccepted': accepted,
            'privacyPolicyAcceptedAt': accepted ? FieldValue.serverTimestamp() : null,
          });
          
          setState(() {
            hasAcceptedPrivacyPolicy = accepted;
          });
        }
      }
    } catch (e) {
      print('Error updating privacy policy acceptance: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating privacy policy status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
          
        // Handle similarly for other address sections if they exist
        // ...existing code...
        
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
    _villageSitioVictimController.dispose();
    _educationVictimController.dispose();
    _occupationVictimController.dispose();
    _workAddressVictimController.dispose();
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
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDateTime ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(Duration(days: 365)),
    );
    
    if (pickedDate != null) {
      // After selecting date, show time picker
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(initialDateTime ?? DateTime.now()),
      );
      
      if (pickedTime != null) {
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        
        onDateTimeSelected(selectedDateTime);
        controller.text = _formatDateTime(selectedDateTime);
      }
    }
  }

  // Helper method to collect all form data
  Map<String, dynamic> collectFormData() {
    Map<String, dynamic> formData = {
      // General information
      'typeOfIncident': _typeOfIncidentController.text,
      'copyFor': _copyForController.text,
      'dateTimeReported': dateTimeReported,
      'dateTimeIncident': dateTimeIncident,
      'placeOfIncident': _placeOfIncidentController.text,
      
      // ITEM A - Reporting Person
      'itemA': {
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
        'region': reportingPersonRegion?.regionName,
        'province': reportingPersonProvince?.name,
        'townCity': reportingPersonMunicipality?.name,
        'barangay': reportingPersonBarangay,
        'education': _educationReportingController.text,
        'occupation': _occupationReportingController.text,
        'idCardPresented': _idCardPresentedController.text,
        'emailAddress': _emailReportingController.text,
      },
      
      // ITEM C - Victim
      'itemC': {
        'surname': _surnameVictimController.text,
        'firstName': _firstNameVictimController.text,
        'middleName': _middleNameVictimController.text,
        'qualifier': _qualifierVictimController.text,
        'nickname': _nicknameVictimController.text,
        'citizenship': _citizenshipVictimController.text,
        'sexGender': _sexGenderVictimController.text,
        'civilStatus': _civilStatusVictimController.text,
        'dateOfBirth': _dateOfBirthVictimController.text,
        'age': _ageVictimController.text,
        'placeOfBirth': _placeOfBirthVictimController.text,
        'homePhone': _homePhoneVictimController.text,
        'mobilePhone': _mobilePhoneVictimController.text,
        'currentAddress': _currentAddressVictimController.text,
        'villageSitio': _villageSitioVictimController.text,
        'region': victimRegion?.regionName,
        'province': victimProvince?.name,
        'townCity': victimMunicipality?.name,
        'barangay': victimBarangay,
        'education': _educationVictimController.text,
        'occupation': _occupationVictimController.text,
        'workAddress': _workAddressVictimController.text,
        'emailAddress': _emailVictimController.text,
      },
      
      // ITEM D - Narrative
      'typeOfIncidentD': _typeOfIncidentDController.text,
      'dateTimeIncidentD': _dateOfBirthVictimController.text,
      'placeOfIncidentD': _placeOfIncidentDController.text,
      'narrative': _narrativeController.text,
    };
    
    // Add other address for reporting person if available
    if (hasOtherAddressReporting) {
      formData['itemA']['hasOtherAddress'] = true;
      formData['itemA']['otherRegion'] = reportingPersonOtherRegion?.regionName;
      formData['itemA']['otherProvince'] = reportingPersonOtherProvince?.name;
      formData['itemA']['otherTownCity'] = reportingPersonOtherMunicipality?.name;
      formData['itemA']['otherBarangay'] = reportingPersonOtherBarangay;
    }
    
    // Add other address for victim if available
    if (hasOtherAddressVictim) {
      formData['itemC']['hasOtherAddress'] = true;
      formData['itemC']['otherRegion'] = victimOtherRegion?.regionName;
      formData['itemC']['otherProvince'] = victimOtherProvince?.name;
      formData['itemC']['otherTownCity'] = victimOtherMunicipality?.name;
      formData['itemC']['otherBarangay'] = victimOtherBarangay;
    }
    
    return formData;
  }

  // Convert form data to IRFModel
  IRFModel createIRFModel() {
    // Parse date of birth strings to DateTime objects if present
    DateTime? reportingDob;
    if (_dateOfBirthReportingController.text.isNotEmpty) {
      try {
        reportingDob = DateFormat('dd/MM/yyyy').parse(_dateOfBirthReportingController.text);
      } catch (e) {
        print('Error parsing reporting person date of birth: $e');
      }
    }
    
    DateTime? victimDob;
    if (_dateOfBirthVictimController.text.isNotEmpty) {
      try {
        victimDob = DateFormat('dd/MM/yyyy').parse(_dateOfBirthVictimController.text);
      } catch (e) {
        print('Error parsing victim date of birth: $e');
      }
    }
    
    int? reportingAge = _ageReportingController.text.isNotEmpty ? 
      int.tryParse(_ageReportingController.text) : null;
    
    int? victimAge = _ageVictimController.text.isNotEmpty ?
      int.tryParse(_ageVictimController.text) : null;
    
    return IRFModel(
      typeOfIncident: _typeOfIncidentController.text,
      copyFor: _copyForController.text,
      dateTimeReported: dateTimeReported,
      dateTimeIncident: dateTimeIncident,
      placeOfIncident: _placeOfIncidentController.text,
      
      // ITEM A - Reporting Person
      itemA: IRFModel.createPersonDetails(
        surname: _surnameReportingController.text,
        firstName: _firstNameReportingController.text,
        middleName: _middleNameReportingController.text,
        qualifier: _qualifierReportingController.text,
        nickname: _nicknameReportingController.text,
        citizenship: _citizenshipReportingController.text,
        sexGender: _sexGenderReportingController.text,
        civilStatus: _civilStatusReportingController.text,
        dateOfBirth: reportingDob,
        age: reportingAge,
        placeOfBirth: _placeOfBirthReportingController.text,
        homePhone: _homePhoneReportingController.text,
        mobilePhone: _mobilePhoneReportingController.text,
        currentAddress: _currentAddressReportingController.text,
        villageSitio: _villageSitioReportingController.text,
        region: reportingPersonRegion?.regionName,
        province: reportingPersonProvince?.name,
        townCity: reportingPersonMunicipality?.name,
        barangay: reportingPersonBarangay,
        highestEducationAttainment: _educationReportingController.text,
        occupation: _occupationReportingController.text,
        idCardPresented: _idCardPresentedController.text,
        emailAddress: _emailReportingController.text,
        otherRegion: hasOtherAddressReporting ? reportingPersonOtherRegion?.regionName : null,
        otherProvince: hasOtherAddressReporting ? reportingPersonOtherProvince?.name : null,
        otherTownCity: hasOtherAddressReporting ? reportingPersonOtherMunicipality?.name : null,
        otherBarangay: hasOtherAddressReporting ? reportingPersonOtherBarangay : null,
      ),
      
      // ITEM C - Victim
      itemC: IRFModel.createPersonDetails(
        surname: _surnameVictimController.text,
        firstName: _firstNameVictimController.text,
        middleName: _middleNameVictimController.text,
        qualifier: _qualifierVictimController.text,
        nickname: _nicknameVictimController.text,
        citizenship: _citizenshipVictimController.text,
        sexGender: _sexGenderVictimController.text,
        civilStatus: _civilStatusVictimController.text,
        dateOfBirth: victimDob,
        age: victimAge,
        placeOfBirth: _placeOfBirthVictimController.text,
        homePhone: _homePhoneVictimController.text,
        mobilePhone: _mobilePhoneVictimController.text,
        currentAddress: _currentAddressVictimController.text,
        villageSitio: _villageSitioVictimController.text,
        region: victimRegion?.regionName,
        province: victimProvince?.name,
        townCity: victimMunicipality?.name,
        barangay: victimBarangay,
        highestEducationAttainment: _educationVictimController.text,
        occupation: _occupationVictimController.text,
        workAddress: _workAddressVictimController.text,
        emailAddress: _emailVictimController.text,
        otherRegion: hasOtherAddressVictim ? victimOtherRegion?.regionName : null,
        otherProvince: hasOtherAddressVictim ? victimOtherProvince?.name : null,
        otherTownCity: hasOtherAddressVictim ? victimOtherMunicipality?.name : null,
        otherBarangay: hasOtherAddressVictim ? victimOtherBarangay : null,
      ),
      
      // ITEM D - Narrative
      narrative: _narrativeController.text,
      typeOfIncidentD: _typeOfIncidentDController.text,
      dateTimeIncidentD: dateTimeIncident, // Using the same DateTime from the main form
      placeOfIncidentD: _placeOfIncidentDController.text,
    );
  }
  
  // Submit form to Firebase
  Future<void> submitForm() async {
    if (!_isSubmissionAllowed()) {
      return;
    }
    
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
      
      // Submit to Firebase
      DocumentReference<Object?> docRef = await _irfService.submitIRF(irfData);
      
      // Get the document to retrieve the formal ID
      DocumentSnapshot doc = await docRef.get();
      String formalId = (doc.data() as Map<String, dynamic>)['documentId'] ?? docRef.id;
      
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
  
  // Save draft locally
  Future<void> saveDraft() async {
    if (!_isSubmissionAllowed()) {
      return;
    }
    
    setState(() {
      isSavingDraft = true;
    });

    try {
      // Check if user is authenticated first
      if (FirebaseAuth.instance.currentUser == null) {
        throw Exception('User not authenticated. Please log in again.');
      }
      
      // Create IRF model from form data
      IRFModel irfData = createIRFModel();
      
      // Save draft locally
      String draftId = await _irfService.saveIRFDraft(irfData);
      
      // Show success message with local draft ID
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Draft saved locally! Reference #: ${draftId.split('_').last}'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      print('Draft saving error: $e');
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving draft: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          isSavingDraft = false;
        });
      }
    }
  }

  // Add this method to load a draft
  Future<void> loadDraft(String draftId) async {
    try {
      // Show loading indicator
      setState(() {
        isSavingDraft = true; // Reuse this state for loading
      });
      
      // Fetch the draft from local storage
      var draftData = await _irfService.getIRF(draftId);
      
      if (draftData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Draft not found'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Convert data to IRFModel if it's from local storage
      IRFModel draft;
      if (draftData is Map<String, dynamic>) {
        // Convert Map to IRFModel
        draft = _irfService.localDraftService.draftToModel(draftData);
      } else {
        // This would happen if it's a Firebase document
        draft = IRFModel.fromDocument(draftData);
      }
      
      // Populate form fields with draft data
      _populateFormFields(draft);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Draft loaded successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error loading draft: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading draft: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSavingDraft = false;
      });
    }
  }
  
  // Add this method to populate form fields from an IRFModel
  void _populateFormFields(IRFModel draft) {
    // General information
    _typeOfIncidentController.text = draft.typeOfIncident ?? "Missing Person";
    _copyForController.text = draft.copyFor ?? "";
    
    if (draft.dateTimeReported != null) {
      dateTimeReported = draft.dateTimeReported;
      _dateTimeReportedController.text = _formatDateTime(draft.dateTimeReported!);
    }
    
    if (draft.dateTimeIncident != null) {
      dateTimeIncident = draft.dateTimeIncident;
      _dateTimeIncidentController.text = _formatDateTime(draft.dateTimeIncident!);
      _dateTimeIncidentDController.text = _formatDateTime(draft.dateTimeIncident!);
    }
    
    _placeOfIncidentController.text = draft.placeOfIncident ?? "";
    
    // ITEM A - Reporting Person
    if (draft.itemA != null) {
      Map<String, dynamic> itemA = draft.itemA!;
      
      _surnameReportingController.text = itemA['surname'] ?? "";
      _firstNameReportingController.text = itemA['firstName'] ?? "";
      _middleNameReportingController.text = itemA['middleName'] ?? "";
      _qualifierReportingController.text = itemA['qualifier'] ?? "";
      _nicknameReportingController.text = itemA['nickname'] ?? "";
      _citizenshipReportingController.text = itemA['citizenship'] ?? "";
      _sexGenderReportingController.text = itemA['sexGender'] ?? "";
      _civilStatusReportingController.text = itemA['civilStatus'] ?? "";
      
      // Handle date of birth
      if (itemA['dateOfBirth'] != null) {
        if (itemA['dateOfBirth'] is DateTime) {
          DateTime dob = itemA['dateOfBirth'];
          _dateOfBirthReportingController.text = 
              "${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}";
        } else if (itemA['dateOfBirth'] is String) {
          try {
            DateTime dob = DateTime.parse(itemA['dateOfBirth']);
            _dateOfBirthReportingController.text = 
                "${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}";
          } catch (e) {
            print('Error parsing date: $e');
            _dateOfBirthReportingController.text = itemA['dateOfBirth'];
          }
        }
      }
      
      _ageReportingController.text = itemA['age']?.toString() ?? "";
      _placeOfBirthReportingController.text = itemA['placeOfBirth'] ?? "";
      _homePhoneReportingController.text = itemA['homePhone'] ?? "";
      _mobilePhoneReportingController.text = itemA['mobilePhone'] ?? "";
      _currentAddressReportingController.text = itemA['currentAddress'] ?? "";
      _villageSitioReportingController.text = itemA['villageSitio'] ?? "";
      _educationReportingController.text = itemA['education'] ?? "";
      _occupationReportingController.text = itemA['occupation'] ?? "";
      _idCardPresentedController.text = itemA['idCardPresented'] ?? "";
      _emailReportingController.text = itemA['emailAddress'] ?? "";
      
      // Handle other address checkbox
      hasOtherAddressReporting = itemA['otherRegion'] != null || 
                               itemA['otherProvince'] != null ||
                               itemA['otherTownCity'] != null ||
                               itemA['otherBarangay'] != null;
      
      // We'll add address loading in a separate update to the form state
    }
    
    // ITEM C - Victim
    if (draft.itemC != null) {
      Map<String, dynamic> itemC = draft.itemC!;
      
      _surnameVictimController.text = itemC['surname'] ?? "";
      _firstNameVictimController.text = itemC['firstName'] ?? "";
      _middleNameVictimController.text = itemC['middleName'] ?? "";
      _qualifierVictimController.text = itemC['qualifier'] ?? "";
      _nicknameVictimController.text = itemC['nickname'] ?? "";
      _citizenshipVictimController.text = itemC['citizenship'] ?? "";
      _sexGenderVictimController.text = itemC['sexGender'] ?? "";
      _civilStatusVictimController.text = itemC['civilStatus'] ?? "";
      
      // Handle date of birth
      if (itemC['dateOfBirth'] != null) {
        if (itemC['dateOfBirth'] is DateTime) {
          DateTime dob = itemC['dateOfBirth'];
          _dateOfBirthVictimController.text = 
              "${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}";
        } else if (itemC['dateOfBirth'] is String) {
          try {
            DateTime dob = DateTime.parse(itemC['dateOfBirth']);
            _dateOfBirthVictimController.text = 
                "${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}";
          } catch (e) {
            print('Error parsing date: $e');
            _dateOfBirthVictimController.text = itemC['dateOfBirth'];
          }
        }
      }
      
      _ageVictimController.text = itemC['age']?.toString() ?? "";
      _placeOfBirthVictimController.text = itemC['placeOfBirth'] ?? "";
      _homePhoneVictimController.text = itemC['homePhone'] ?? "";
      _mobilePhoneVictimController.text = itemC['mobilePhone'] ?? "";
      _currentAddressVictimController.text = itemC['currentAddress'] ?? "";
      _villageSitioVictimController.text = itemC['villageSitio'] ?? "";
      _educationVictimController.text = itemC['education'] ?? "";
      _occupationVictimController.text = itemC['occupation'] ?? "";
      _workAddressVictimController.text = itemC['workAddress'] ?? "";
      _emailVictimController.text = itemC['emailAddress'] ?? "";
      
      // Handle other address checkbox
      hasOtherAddressVictim = itemC['otherRegion'] != null || 
                            itemC['otherProvince'] != null ||
                            itemC['otherTownCity'] != null ||
                            itemC['otherBarangay'] != null;
    }
    
    // ITEM D - Narrative
    _typeOfIncidentDController.text = draft.typeOfIncidentD ?? "Missing Person";
    if (draft.dateTimeIncidentD != null) {
      _dateTimeIncidentDController.text = _formatDateTime(draft.dateTimeIncidentD!);
    }
    _placeOfIncidentDController.text = draft.placeOfIncidentD ?? "";
    _narrativeController.text = draft.narrative ?? "";
    
    // Update the form state to reflect loaded data
    setState(() {
      // Form state will be updated based on the populated fields
      updateFormState();
    });
  }
  
  // Show dialog to select a draft to load
  Future<void> _showLoadDraftDialog() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator()),
    );
    
    try {
      // Get all drafts
      List<IRFModel> drafts = await _irfService.getUserDrafts();
      
      // Hide loading indicator
      Navigator.pop(context);
      
      if (drafts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No drafts found'),
            backgroundColor: Colors.blue,
          ),
        );
        return;
      }
      
      // Show draft selection dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Select a Draft to Load'),
            content: Container(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: drafts.length,
                itemBuilder: (context, index) {
                  IRFModel draft = drafts[index];
                  String createdDate = draft.createdAt != null 
                      ? DateFormat('MM/dd/yyyy hh:mm a').format(draft.createdAt!)
                      : 'Unknown date';
                  
                  String victimName = '';
                  if (draft.itemC != null) {
                    String surname = draft.itemC!['surname'] ?? '';
                    String firstName = draft.itemC!['firstName'] ?? '';
                    if (surname.isNotEmpty || firstName.isNotEmpty) {
                      victimName = '$firstName $surname';
                    }
                  }
                  
                  return ListTile(
                    title: Text(victimName.isNotEmpty ? victimName : 'Draft #${index + 1}'),
                    subtitle: Text('Created: $createdDate'),
                    onTap: () {
                      Navigator.pop(context);
                      loadDraft(draft.documentId!);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Cancel'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      // Hide loading indicator if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading drafts: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Show privacy policy modal
  void _showPrivacyPolicyModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0), // Less rounded corners
            ),
            title: Text(
              'Data Privacy Act Compliance',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            content: SingleChildScrollView(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                  ),
                  children: <TextSpan>[
                    TextSpan(text: 'In accordance with '),
                    TextSpan(
                      text: 'Republic Act No. 10173',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: ', the '),
                    TextSpan(
                      text: 'Data Privacy Act of 2012',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ', we ensure that your personal data will be processed securely and used solely for law enforcement purposes.\n\n'
                        'By submitting this form, you ',
                    ),
                    TextSpan(
                      text: 'voluntarily provide your personal data',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: ' for official police use. Your information will not be disclosed to unauthorized entities.\n\n'
                        'For more details, visit the ',
                    ),
                    TextSpan(
                      text: 'National Privacy Commission',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Disagree',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () {
                  // Update the user's privacy policy status
                  updatePrivacyPolicyAcceptance(false);
                  // Navigate back to home screen
                  Navigator.of(context).pop(); // Close the dialog
                  Navigator.of(context).pushReplacementNamed(AppRoutes.home); // Go to home screen
                },
              ),
              TextButton(
                child: Text(
                  'Accept',
                  style: TextStyle(color: Color(0xFF0D47A1)),
                ),
                onPressed: () {
                  // Update the user's privacy policy status
                  updatePrivacyPolicyAcceptance(true);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Check if form submission is allowed based on privacy acceptance
  bool _isSubmissionAllowed() {
    if (!hasAcceptedPrivacyPolicy) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You must accept the Data Privacy Policy to continue'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'View Policy',
            onPressed: _showPrivacyPolicyModal,
          ),
        ),
      );
      return false;
    }
    return true;
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0D47A1),
        actions: [
          // Load Draft button in AppBar
          TextButton.icon(
            onPressed: isSavingDraft ? null : _showLoadDraftDialog,
            icon: Icon(Icons.file_open, color: Colors.white),
            label: Text('Load Draft', 
              style: TextStyle(color: Colors.white, fontSize: 14)
            ),
          ),
          // Save Draft button in AppBar
          TextButton.icon(
            onPressed: isSavingDraft ? null : saveDraft,
            icon: isSavingDraft 
              ? SizedBox(
                  height: 20, 
                  width: 20, 
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  )
                )
              : Icon(Icons.save_outlined, color: Colors.white),
            label: Text('Save Draft', 
              style: TextStyle(color: Colors.white, fontSize: 14)
            ),
          ),
          // Discard button in AppBar
          TextButton.icon(
            onPressed: () {
              // Show confirmation dialog
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Discard Changes?'),
                  content: Text('Are you sure you want to discard all changes?'),
                  actions: [
                    TextButton(
                      child: Text('Cancel'),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: Text('Discard', style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        Navigator.pop(context);
                        // Add discard logic here
                      },
                    ),
                  ],
                ),
              );
            },
            icon: Icon(Icons.close, color: Colors.white),
            label: Text('Discard', 
              style: TextStyle(color: Colors.white, fontSize: 14)
            ),
          ),
          SizedBox(width: 8), // Add some padding at the end
        ],
      ),
      drawer: AppDrawer(),
      body: isCheckingPrivacyStatus 
        ? Center(child: CircularProgressIndicator()) // Show loading while checking privacy status
        : SingleChildScrollView(
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
                        FormRowInputs(
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
                              'required': false,
                              'controller': _copyForController,
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),
                         
                        FormRowInputs(
                          fields: [
                            {
                              'label': 'DATE AND TIME REPORTED',
                              'required': true,
                              'controller': _dateTimeReportedController,
                              'readOnly': true,
                              'onTap': () {
                                _pickDateTime(
                                  _dateTimeReportedController,
                                  dateTimeReported,
                                  (DateTime selectedDateTime) {
                                    setState(() {
                                      dateTimeReported = selectedDateTime;
                                    });
                                  },
                                );
                              },
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
                        
                        SizedBox(height: 10),

                        // Section title using the new component
                        SectionTitle(
                          title: 'REPORTING PERSON',
                          backgroundColor: Color(0xFF1E215A),
                        ),

                        SizedBox(height: 10),

                        FormRowInputs(
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
                              'required': false,
                              'controller': _middleNameReportingController,
                              'keyboardType': TextInputType.name,
                              'inputFormatters': [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),
                        
                        FormRowInputs(
                          fields: [
                            {
                              'label': 'QUALIFIER',
                              'required': false,
                              'controller': _qualifierReportingController,
                              'keyboardType': TextInputType.text,
                            },
                            {
                              'label': 'NICKNAME',
                              'required': false,
                              'controller': _nicknameReportingController,
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
                              'label': 'CITIZENSHIP',
                              'required': true,
                              'controller': _citizenshipReportingController,
                              'dropdownItems': citizenshipOptions,
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
                        
                        SizedBox(height: 10),
                        
                        FormRowInputs(
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
                        
                        SizedBox(height: 10),
                        
                        FormRowInputs(
                          fields: [
                            {
                              'label': 'HOME PHONE',
                              'required': false,
                              'controller': _homePhoneReportingController,
                              'keyboardType': TextInputType.phone,
                              'inputFormatters': [FilteringTextInputFormatter.digitsOnly],
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
                              'required': false,
                              'controller': _educationReportingController,
                              'dropdownItems': educationOptions,
                              'section': 'reporting',
                            },
                            {
                              'label': 'OCCUPATION',
                              'required': false,
                              'controller': _occupationReportingController,
                              'dropdownItems': occupationOptions,
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
                              'label': 'ID CARD PRESENTED',
                              'required': false,
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
                          title: 'MISSING PERSON DATA',
                          backgroundColor: Color(0xFF1E215A),
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
                              'required': false,
                              'controller': _middleNameVictimController,
                              'keyboardType': TextInputType.name,
                              'inputFormatters': [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),
                        
                        FormRowInputs(
                          fields: [
                            {
                              'label': 'QUALIFIER',
                              'required': false,
                              'controller': _qualifierVictimController,
                              'keyboardType': TextInputType.text,
                            },
                            {
                              'label': 'NICKNAME',
                              'required': false,
                              'controller': _nicknameVictimController,
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
                              'label': 'CITIZENSHIP',
                              'required': true,
                              'controller': _citizenshipVictimController,
                              'dropdownItems': citizenshipOptions,
                            },
                            {
                              'label': 'SEX/GENDER',
                              'required': true,
                              'controller': _sexGenderVictimController,
                              'dropdownItems': genderOptions,
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
                        
                        SizedBox(height: 10),
                        
                        FormRowInputs(
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
                        
                        SizedBox(height: 10),

                        FormRowInputs(
                          fields: [
                            {
                              'label': 'HOME PHONE',
                              'required': false,
                              'controller': _homePhoneVictimController,
                              'keyboardType': TextInputType.phone,
                              'inputFormatters': [FilteringTextInputFormatter.digitsOnly],
                            },
                            {
                              'label': 'MOBILE PHONE',
                              'required': true,
                              'controller': _mobilePhoneVictimController,
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
                        ],

                        FormRowInputs(
                          fields: [
                            {
                              'label': 'HIGHEST EDUCATION ATTAINMENT',
                              'required': false,
                              'controller': _educationVictimController,
                              'dropdownItems': educationOptions,
                              'section': 'victim',
                            },
                            {
                              'label': 'OCCUPATION',
                              'required': false,
                              'controller': _occupationVictimController,
                              'dropdownItems': occupationOptions,
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
                              'label': 'WORK ADDRESS',
                              'required': false,
                              'controller': _workAddressVictimController,
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
                          title: 'ITEM "D" - NARRATIVE OF INCIDENT',
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
                        
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                            "ENTER IN DETAIL THE NARRATIVE OF INCIDENT OR EVENT, ANSWERING THE WHO, WHAT, WHEN, WHERE, WHY AND HOW OF REPORTING",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                              color: Colors.black,
                            ),
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
        onSubmit: submitForm,
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

