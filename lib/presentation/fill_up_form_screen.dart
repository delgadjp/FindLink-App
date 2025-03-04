import '/core/app_export.dart';
import 'package:philippines_rpcmb/philippines_rpcmb.dart';
import 'package:intl/intl.dart';
import '../widgets/form/disabled_form_fields.dart';

class FillUpFormScreen extends StatefulWidget {
  const FillUpFormScreen({Key? key}) : super(key: key);
  @override
  FillUpForm createState() => FillUpForm();
}

class FillUpForm extends State<FillUpFormScreen> {
  bool hasOtherAddressReporting = false;
  bool hasOtherAddressSuspect = false;
  bool hasOtherAddressVictim = false;
  bool hasPreviousCriminalRecord = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _dateOfBirthReportingController = TextEditingController();
  final TextEditingController _dateOfBirthSuspectController = TextEditingController();
  final TextEditingController _dateOfBirthVictimController = TextEditingController();
  
  // Add controllers for date and time fields
  final TextEditingController _dateTimeReportedController = TextEditingController();
  final TextEditingController _dateTimeIncidentController = TextEditingController();
  
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
    
    // Initialize formState
    updateFormState();
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
        // Similar for all other address fields
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
        // Suspect address fields
        case 'suspectRegion':
          if (suspectRegion != value) {
            suspectProvince = null;
            suspectMunicipality = null;
            suspectBarangay = null;
          }
          suspectRegion = value;
          break;
        case 'suspectProvince':
          if (suspectProvince != value) {
            suspectMunicipality = null;
            suspectBarangay = null;
          }
          suspectProvince = value;
          break;
        case 'suspectMunicipality':
          if (suspectMunicipality != value) {
            suspectBarangay = null;
          }
          suspectMunicipality = value;
          break;
        case 'suspectBarangay':
          suspectBarangay = value;
          break;
        // Suspect other address fields
        case 'suspectOtherRegion':
          if (suspectOtherRegion != value) {
            suspectOtherProvince = null;
            suspectOtherMunicipality = null;
            suspectOtherBarangay = null;
          }
          suspectOtherRegion = value;
          break;
        case 'suspectOtherProvince':
          if (suspectOtherProvince != value) {
            suspectOtherMunicipality = null;
            suspectOtherBarangay = null;
          }
          suspectOtherProvince = value;
          break;
        case 'suspectOtherMunicipality':
          if (suspectOtherMunicipality != value) {
            suspectOtherBarangay = null;
          }
          suspectOtherMunicipality = value;
          break;
        case 'suspectOtherBarangay':
          suspectOtherBarangay = value;
          break;
        // Victim address fields
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
        // Victim other address fields
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
        // Education and occupation fields
        case 'reportingEducation':
          reportingPersonEducation = value;
          break;
        case 'reportingOccupation':
          reportingPersonOccupation = value;
          break;
        case 'suspectEducation':
          suspectEducation = value;
          break;
        case 'suspectOccupation':
          suspectOccupation = value;
          break;
        case 'victimEducation':
          victimEducation = value;
          break;
        case 'victimOccupation':
          victimOccupation = value;
          break;
      }
      updateFormState();
    });
  }

  @override
  void dispose() {
    _dateOfBirthReportingController.dispose();
    _dateOfBirthSuspectController.dispose();
    _dateOfBirthVictimController.dispose();
    _dateTimeReportedController.dispose();
    _dateTimeIncidentController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF0D47A1),
        actions: [
          // Save Draft button in AppBar
          TextButton.icon(
            onPressed: () {
              // Save draft logic
            },
            icon: Icon(Icons.save_outlined, color: Colors.white),
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
      body: SingleChildScrollView(
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
                      Text(
                        "Philippine National Police",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        ),
                      ),
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
                        Container(
                          color: const Color.fromARGB(255, 243, 243, 243), // Light gray background
                          padding: EdgeInsets.all(8),
                          child: Text(
                            "INSTRUCTIONS: Refer to PNP SOP on 'Recording of Incidents in the Police Blotter' in filling up this form. This incident Record Form(IRF) may be reproduced, photocopied, and/or downloaded from the DIDM website, www.didm.pnp.gov.ph.",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        
                        FormRowInputs(
                          fields: [
                            {
                              'label': 'IRF ENTRY NUMBER',
                              'required': true,
                              'keyboardType': TextInputType.number,
                              'inputFormatters': [FilteringTextInputFormatter.digitsOnly],
                            },
                            {
                              'label': 'TYPE OF INCIDENT',
                              'required': true,
                              'keyboardType': TextInputType.text,
                            },
                            {
                              'label': 'COPY FOR',
                              'required': false,
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
                                    });
                                  },
                                );
                              },
                            },
                            {
                              'label': 'PLACE OF INCIDENT',
                              'required': true,
                              'keyboardType': TextInputType.text,
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),

                        // Section title using the new component
                        SectionTitle(
                          title: 'ITEM "A" - REPORTING PERSON',
                          backgroundColor: Color(0xFF1E215A),
                        ),

                        SizedBox(height: 10),

                        FormRowInputs(
                          fields: [
                            {
                              'label': 'FAMILY NAME',
                              'required': true,
                              'keyboardType': TextInputType.name,
                              'inputFormatters': [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                            },
                            {
                              'label': 'FIRST NAME',
                              'required': true,
                              'keyboardType': TextInputType.name,
                              'inputFormatters': [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                            },
                            {
                              'label': 'MIDDLE NAME',
                              'required': false,
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
                              'keyboardType': TextInputType.text,
                            },
                            {
                              'label': 'NICKNAME',
                              'required': false,
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
                              'dropdownItems': citizenshipOptions,
                            },
                            {
                              'label': 'SEX/GENDER',
                              'required': true,
                              'dropdownItems': genderOptions,
                            },
                            {
                              'label': 'CIVIL STATUS',
                              'required': true,
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
                                  });
                                }
                              },
                            },
                            {
                              'label': 'AGE',
                              'required': true,
                              'controller': TextEditingController(text: reportingPersonAge?.toString() ?? ''),
                              'readOnly': true,
                            },
                            {
                              'label': 'PLACE OF BIRTH',
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
                              'label': 'HOME PHONE',
                              'required': false,
                              'keyboardType': TextInputType.phone,
                              'inputFormatters': [FilteringTextInputFormatter.digitsOnly],
                            },
                            {
                              'label': 'MOBILE PHONE',
                              'required': true,
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
                              'dropdownItems': educationOptions,
                              'section': 'reporting',
                            },
                            {
                              'label': 'OCCUPATION',
                              'required': false,
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
                              'keyboardType': TextInputType.text,
                            },
                            {
                              'label': 'EMAIL ADDRESS (If Any)',
                              'required': false,
                              'keyboardType': TextInputType.emailAddress,
                            },
                          ],
                          formState: formState,
                          onFieldChange: onFieldChange,
                        ),
                        
                        SizedBox(height: 10),

                        SectionTitle(
                          title: 'ITEM "B" - SUSPECT DATA',
                          backgroundColor: Color(0xFF1E215A),
                        ),
                        
                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['FAMILY NAME', 'FIRST NAME', 'MIDDLE NAME']),
                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['QUALIFIER', 'NICKNAME']),
                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['CITIZENSHIP', 'SEX/GENDER', 'CIVIL STATUS']),
                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['DATE OF BIRTH', 'AGE', 'PLACE OF BIRTH']),
                        
                        SizedBox(height: 10),

                        // Replace Item B home phone and mobile fields with disabled version
                        DisabledFormFields.buildDisabledFormRow(['HOME PHONE', 'MOBILE PHONE']),
                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['CURRENT ADDRESS (HOUSE NUMBER/STREET)']),
                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['VILLAGE/SITIO']),
                        SizedBox(height: 10),
                        
                        Divider(color: const Color.fromARGB(255, 119, 119, 119), thickness: 2),
                        SizedBox(height: 5),
                        
                        // Replace address fields with disabled version
                        DisabledFormFields.buildDisabledFormRow(['REGION', 'PROVINCE']),
                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['TOWN/CITY', 'BARANGAY']),
                        
                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['HIGHEST EDUCATION ATTAINMENT', 'OCCUPATION']),
                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['WORK ADDRESS']),
                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['RELATION TO VICTIM', 'EMAIL ADDRESS (If Any)']),

                        // Replace the previous criminal record section with disabled fields
                        Container(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "WITH PREVIOUS CRIMINAL CASE RECORD?",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 10),
                              Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    margin: EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  Text(
                                    "Yes",
                                    style: TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                  SizedBox(width: 20),
                                  Container(
                                    width: 20,
                                    height: 20,
                                    margin: EdgeInsets.symmetric(horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  Text(
                                    "No",
                                    style: TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        DisabledFormFields.buildDisabledFormRow(['Specify Previous Criminal Case Record']),
                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['STATUS OF PREVIOUS CASE']),
                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['HEIGHT', 'WEIGHT', 'BUILT']),
                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['COLOR OF EYES', 'DESCRIPTION OF EYES']),
                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['COLOR OF HAIR', 'DESCRIPTION OF HAIR']),
                        
                        SizedBox(height: 10),

                        UnderInfluenceCheckboxes(),
                        
                        SizedBox(height: 10),

                        SectionTitle(
                          title: 'FOR CHILDREN IN CONFLICT WITH LAW',
                          backgroundColor: Color(0xFF1E215A),
                        ),
                        
                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['NAME OF GUARDIAN']),
                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['GUARDIAN ADDRESS']),
                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['HOME PHONE', 'MOBILE PHONE']),

                        SizedBox(height: 10),

                        SectionTitle(
                          title: 'ITEM "C" - VICTIM DATA',
                          backgroundColor: Color(0xFF1E215A),
                        ),
                        
                        SizedBox(height: 10),

                        FormRowInputs(
                          fields: [
                            {
                              'label': 'FAMILY NAME',
                              'required': true,
                              'keyboardType': TextInputType.name,
                              'inputFormatters': [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                            },
                            {
                              'label': 'FIRST NAME',
                              'required': true,
                              'keyboardType': TextInputType.name,
                              'inputFormatters': [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                            },
                            {
                              'label': 'MIDDLE NAME',
                              'required': false,
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
                              'keyboardType': TextInputType.text,
                            },
                            {
                              'label': 'NICKNAME',
                              'required': false,
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
                              'dropdownItems': citizenshipOptions,
                            },
                            {
                              'label': 'SEX/GENDER',
                              'required': true,
                              'dropdownItems': genderOptions,
                            },
                            {
                              'label': 'CIVIL STATUS',
                              'required': true,
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
                                  });
                                }
                              },
                            },
                            {
                              'label': 'AGE',
                              'required': true,
                              'controller': TextEditingController(text: victimAge?.toString() ?? ''),
                              'readOnly': true,
                            },
                            {
                              'label': 'PLACE OF BIRTH',
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
                              'label': 'HOME PHONE',
                              'required': false,
                              'keyboardType': TextInputType.phone,
                              'inputFormatters': [FilteringTextInputFormatter.digitsOnly],
                            },
                            {
                              'label': 'MOBILE PHONE',
                              'required': true,
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
                              'dropdownItems': educationOptions,
                              'section': 'victim',
                            },
                            {
                              'label': 'OCCUPATION',
                              'required': false,
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
                              'keyboardType': TextInputType.text,
                            },
                            {
                              'label': 'EMAIL ADDRESS (If Any)',
                              'required': false,
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
                              'keyboardType': TextInputType.text,
                            },
                            {
                              'label': 'DATE/TIME OF INCIDENT',
                              'required': true,
                              'controller': TextEditingController(text: dateTimeIncident != null ? _formatDateTime(dateTimeIncident!) : ''),
                              'readOnly': true,
                            },
                            {
                              'label': 'PLACE OF INCIDENT',
                              'required': true,
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
                            TextField(
                            maxLines: 10, // Set max lines to make it a textarea
                            style: TextStyle(fontSize: 15, color: Colors.black), // Set text color to black
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.black),
                              ),
                              contentPadding: EdgeInsets.all(8),
                            ),
                            ),
                          ],
                          ),
                        ),
                        
                        SizedBox(height: 10),

                        Container(
                          color: const Color.fromARGB(255, 160, 173, 242), // Light gray background
                          padding: EdgeInsets.all(8),
                          child: Text(
                            "I HEREBY CERTIFY TO THE CORRECTNESS OF THE FOREGOING TO THE BEST OF MY KNOWLEDGE AND BELIEF.",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        ),

                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['NAME OF REPORTING PERSON', 'SIGNATURE OF REPORTING PERSON']),

                        SizedBox(height: 10),

                        Container(
                          color: const Color.fromARGB(255, 160, 173, 242), // Light gray background
                          padding: EdgeInsets.all(8),
                          child: Text(
                            "SUBSCRIBED AND SWORN TO BEFORE ME",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['NAME OF ADMINISTERING OFFICER(DUTY OFFICER)', 'SIGNATURE OF ADMINISTERING OFFICER(DUTY OFFICER)']),
                        DisabledFormFields.buildDisabledFormRow(['RANK, NAME AND DESIGNATION OF POLICE OFFICER']),
                        DisabledFormFields.buildDisabledFormRow(['SIGNATURE OF DUTY INVESTIGATOR/ INVESTIGATOR ON CASE/ ASSISTING POLICE OFFICER']),

                        SizedBox(height: 10),

                        Container(
                          color: const Color.fromARGB(255, 160, 173, 242), // Light gray background
                          padding: EdgeInsets.all(8),
                          child: Text(
                            "INCIDENT RECORDED IN THE BLOTTER BY:",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['RANK/NAME OF DESK OFFICER:']),
                        DisabledFormFields.buildDisabledFormRow(['SIGNATURE OF DESK OFFICER:', 'BLOTTER ENTRY NR:']),

                        SizedBox(height: 10),
                        
                        Container(
                          color: const Color.fromARGB(255, 243, 243, 243), // Light gray background
                          padding: EdgeInsets.all(8),
                          child: Text(
                            "REMINDER TO REPORTING PERSON: Keep the copy of this Incident Record Form (IRF). An update of the progress of the investigation of the crime or incident that you reported will be given to you upon presentation of this IRF. For your reference, the data below is the contact details of this police station.",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['Name of Police Station', 'Telephone']),
                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['Investigator-on-Case', 'Mobile Phone']),
                        SizedBox(height: 10),
                        DisabledFormFields.buildDisabledFormRow(['Name of Chief/Head of Office', 'Mobile Phone']),
                        
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      bottomNavigationBar: SubmitButton(formKey: _formKey),
    );
  }
}

