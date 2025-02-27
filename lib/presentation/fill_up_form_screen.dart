import '/core/app_export.dart';
import '/data/philippines_data.dart';

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

  static const String dropdownPlaceholder = '-- SELECT --';

  final List<String> citizenshipOptions = [dropdownPlaceholder, 'Filipino', 'American', 'Chinese', 'Japanese', 'Korean', 'Others'];
  final List<String> genderOptions = [dropdownPlaceholder, 'Male', 'Female', 'Other'];
  final List<String> civilStatusOptions = [dropdownPlaceholder, 'Single', 'Married', 'Widowed', 'Separated', 'Divorced'];

  int? reportingPersonAge;
  int? suspectAge;
  int? victimAge;

  String? reportingPersonProvince;
  String? reportingPersonCity;
  String? reportingPersonOtherProvince;
  String? reportingPersonOtherCity;
  
  String? suspectProvince;
  String? suspectCity;
  String? suspectOtherProvince;
  String? suspectOtherCity;
  
  String? victimProvince;
  String? victimCity;
  String? victimOtherProvince;
  String? victimOtherCity;

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
  void dispose() {
    _dateOfBirthReportingController.dispose();
    _dateOfBirthSuspectController.dispose();
    _dateOfBirthVictimController.dispose();
    super.dispose();
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
                            "INSTRUCTIONS: Refer to PNP SOP on ‘Recording of Incidents in the Police Blotter’ in filling up this form. This incident Record Form(IRF) may be reproduced, photocopied, and/or downloaded from the DIDM website, www.didm.pnp.gov.ph.",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        _buildRowInputs([
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
                        ]),
                        SizedBox(height: 10),
                         
                        _buildRowInputs([
                          {
                            'label': 'DATE AND TIME REPORTED',
                            'required': true,
                            'keyboardType': TextInputType.datetime,
                          },
                          {
                            'label': 'DATE AND TIME OF INCIDENT',
                            'required': true,
                            'keyboardType': TextInputType.datetime,
                          },
                          {
                            'label': 'PLACE OF INCIDENT',
                            'required': true,
                            'keyboardType': TextInputType.text,
                          },
                        ]),
                        SizedBox(height: 10),

                        Container(
                          color: const Color.fromARGB(255, 30, 33, 90), // Background color
                          padding: EdgeInsets.all(8), // Optional padding
                          child: _buildSectionTitle(
                          'ITEM "A" - REPORTING PERSON', Colors.transparent),
                        ),

                        SizedBox(height: 10),

                        _buildRowInputs([
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
                        ]),
                        SizedBox(height: 10),
                        _buildRowInputs([
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
                        ]),
                        SizedBox(height: 10),
                        _buildRowInputs([
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
                        ]),
                        SizedBox(height: 10),
                        _buildRowInputs([
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
                        ]),
                        SizedBox(height: 10),
                        _buildRowInputs([
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
                        ]),
                        SizedBox(height: 10),
                        _buildRowInputs([
                          {
                            'label': 'CURRENT ADDRESS (HOUSE NUMBER/STREET)',
                            'required': true,
                            'keyboardType': TextInputType.text,
                          },
                        ]),
                        SizedBox(height: 10),
                          _buildRowInputs([
                            {
                              'label': 'VILLAGE/SITIO',
                              'required': true,
                              'keyboardType': TextInputType.text,
                            },
                          ]),
                          SizedBox(height: 10),
                          _buildRowInputs([
                            {
                              'label': 'BARANGAY',
                              'required': true,
                              'keyboardType': TextInputType.text,
                            },
                            {
                              'label': 'TOWN/CITY',
                              'required': true,
                              'keyboardType': TextInputType.text,
                              'section': 'reporting',
                            },
                            {
                              'label': 'PROVINCE',
                              'required': true,
                              'keyboardType': TextInputType.text,
                              'section': 'reporting',
                            },
                          ]),
                          SizedBox(height: 10),


                          CheckboxListTile(
                          title: Text("Do you have another address?", style: TextStyle(fontSize: 15, color: Colors.black)), // Change text color to black
                          value: hasOtherAddressReporting,
                          onChanged: (bool? value) {
                            setState(() {
                              hasOtherAddressReporting = value ?? false;
                            });
                          },
                        ),
                        if (hasOtherAddressReporting) ...[
                          _buildRowInputs([
                            {
                              'label': 'OTHER ADDRESS (HOUSE NUMBER/STREET)',
                              'required': true,
                              'keyboardType': TextInputType.text,
                            },
                          ]),
                            SizedBox(height: 10),
                          _buildRowInputs([
                            {
                              'label': 'VILLAGE/SITIO',
                              'required': true,
                              'keyboardType': TextInputType.text,
                            },
                          ]),
                          SizedBox(height: 10),
                          _buildRowInputs([
                            {
                              'label': 'BARANGAY',
                              'required': true,
                              'keyboardType': TextInputType.text,
                            },
                            {
                              'label': 'TOWN/CITY',
                              'required': true,
                              'section': 'reportingOther',
                            },
                            {
                              'label': 'PROVINCE',
                              'required': true,
                              'section': 'reportingOther',
                            },
                          ]),
                          SizedBox(height: 10),
                        ],


                          SizedBox(height: 10),
                          _buildRowInputs([
                            {
                              'label': 'HIGHEST EDUCATION ATTAINMENT',
                              'required': false,
                              'keyboardType': TextInputType.text,
                            },
                            {
                              'label': 'OCCUPATION',
                              'required': false,
                              'keyboardType': TextInputType.text,
                            },
                          ]),
                         SizedBox(height: 10),
                          _buildRowInputs([
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
                          ]),
                          SizedBox(height: 10),


                        _buildSectionTitle('ITEM "B" - SUSPECT DATA', Color(0xFF1E215A)),
                        SizedBox(height: 10),

                        _buildRowInputs([
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
                        ]),
                        SizedBox(height: 10),
                         _buildRowInputs([
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
                        ]),
                        SizedBox(height: 10),
                         _buildRowInputs([
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
                        ]),
                        SizedBox(height: 10),
                        _buildRowInputs([
                          {
                            'label': 'DATE OF BIRTH',
                            'required': true,
                            'controller': _dateOfBirthSuspectController,
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
                                  _dateOfBirthSuspectController.text = 
                                      "${pickedDate.day.toString().padLeft(2, '0')}/"
                                      "${pickedDate.month.toString().padLeft(2, '0')}/"
                                      "${pickedDate.year}";
                                  suspectAge = calculateAge(pickedDate);
                                });
                              }
                            },
                          },
                          {
                            'label': 'AGE',
                            'required': true,
                            'controller': TextEditingController(text: suspectAge?.toString() ?? ''),
                            'readOnly': true,
                          },
                          {
                            'label': 'PLACE OF BIRTH',
                            'required': true,
                            'keyboardType': TextInputType.text,
                          },
                        ]),
                                                SizedBox(height: 10),

                        _buildRowInputs([
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
                        ]),
                        SizedBox(height: 10),
                        _buildRowInputs([
                          {
                            'label': 'CURRENT ADDRESS (HOUSE NUMBER/STREET)',
                            'required': true,
                            'keyboardType': TextInputType.text,
                          },
                        ]),
                        SizedBox(height: 10),
                          _buildRowInputs([
                            {
                              'label': 'VILLAGE/SITIO',
                              'required': true,
                              'keyboardType': TextInputType.text,
                            },
                          ]),
                          SizedBox(height: 10),
                          _buildRowInputs([
                            {
                              'label': 'BARANGAY',
                              'required': true,
                              'keyboardType': TextInputType.text,
                            },
                            {
                              'label': 'TOWN/CITY',
                              'required': true,
                              'keyboardType': TextInputType.text,
                              'section': 'suspect',
                            },
                            {
                              'label': 'PROVINCE',
                              'required': true,
                              'keyboardType': TextInputType.text,
                              'section': 'suspect',
                            },
                          ]),
                          SizedBox(height: 10),

                          CheckboxListTile(
                          title: Text("Do you have another address?", style: TextStyle(fontSize: 15, color: Colors.black)), // Change text color to black
                          value: hasOtherAddressSuspect,
                          onChanged: (bool? value) {
                            setState(() {
                              hasOtherAddressSuspect = value ?? false;
                            });
                          },
                        ),
                        if (hasOtherAddressSuspect) ...[
                          _buildRowInputs([
                            {
                              'label': 'OTHER ADDRESS (HOUSE NUMBER/STREET)',
                              'required': true,
                              'keyboardType': TextInputType.text,
                            },
                          ]),
                            SizedBox(height: 10),
                          _buildRowInputs([
                            {
                              'label': 'VILLAGE/SITIO',
                              'required': true,
                              'keyboardType': TextInputType.text,
                            },
                          ]),
                          SizedBox(height: 10),
                          _buildRowInputs([
                            {
                              'label': 'BARANGAY',
                              'required': true,
                              'keyboardType': TextInputType.text,
                            },
                            {
                              'label': 'TOWN/CITY',
                              'required': true,
                              'section': 'suspectOther',
                            },
                            {
                              'label': 'PROVINCE',
                              'required': true,
                              'section': 'suspectOther',
                            },
                          ]),
                          SizedBox(height: 10),
                        ],

                       

                        _buildRowInputs([
                          {
                            'label': 'HIGHEST EDUCATION ATTAINMENT',
                            'required': false,
                            'keyboardType': TextInputType.text,
                          },
                          {
                            'label': 'OCCUPATION',
                            'required': false,
                            'keyboardType': TextInputType.text,
                          },
                        ]),
                         SizedBox(height: 10),
                        _buildRowInputs([
                          {
                            'label': 'WORK ADDRESS',
                            'required': false,
                            'keyboardType': TextInputType.text,
                          },
                         ]),
                         SizedBox(height: 10),
                        _buildRowInputs([
                          {
                            'label': 'RELATION TO VICTIM',
                            'required': false,
                            'keyboardType': TextInputType.text,
                          },
                          {
                            'label': 'EMAIL ADDRESS (If Any)',
                            'required': false,
                            'keyboardType': TextInputType.emailAddress,
                          },
                        ]),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          SizedBox(height: 10),
                            Text(
                              "WITH PREVIOUS CRIMINAL CASE RECORD?",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black,
                              ),
                            ),
                            Row(
                              children: [
                                Radio<bool>(
                                  value: true,
                                  groupValue: hasPreviousCriminalRecord,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      hasPreviousCriminalRecord = value ?? false;
                                    });
                                  },
                                ),
                                Text(
                                  "Yes",
                                  style: TextStyle(fontSize: 14, color: Colors.black),
                                ),
                                Radio<bool>(
                                  value: false,
                                  groupValue: hasPreviousCriminalRecord,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      hasPreviousCriminalRecord = value ?? false;
                                    });
                                  },
                                ),
                                Text(
                                  "No",
                                  style: TextStyle(fontSize: 14, color: Colors.black),
                                ),
                              ],
                            ),
                            if (hasPreviousCriminalRecord)
                              Padding(
                                padding: const EdgeInsets.only(left: 32.0, top: 8.0),
                                child: TextField(
                                  decoration: InputDecoration(
                                    labelText: "Specify Previous Criminal Case Record",
                                    border: OutlineInputBorder(),
                                    contentPadding: EdgeInsets.all(8),
                                  ),
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                          ],
                        ),
                        _buildRowInputs([
                          {
                            'label': 'STATUS OF PREVIOUS CASE',
                            'required': false,
                            'keyboardType': TextInputType.text,
                          },
                        ]),
                         SizedBox(height: 10),
                        _buildRowInputs([
                          {
                            'label': 'HEIGHT',
                            'required': false,
                            'keyboardType': TextInputType.number,
                            'inputFormatters': [FilteringTextInputFormatter.digitsOnly],
                          },
                          {
                            'label': 'WEIGHT',
                            'required': false,
                            'keyboardType': TextInputType.number,
                            'inputFormatters': [FilteringTextInputFormatter.digitsOnly],
                          },
                          {
                            'label': 'BUILT',
                            'required': false,
                            'keyboardType': TextInputType.text,
                          },
                        ]),
                         SizedBox(height: 10),
                        _buildRowInputs([
                          {
                            'label': 'COLOR OF EYES',
                            'required': false,
                            'keyboardType': TextInputType.text,
                          },
                          {
                            'label': 'DESCRIPTION OF EYES',
                            'required': false,
                            'keyboardType': TextInputType.text,
                          },
                        ]),
                         SizedBox(height: 10),
                        _buildRowInputs([
                          {
                            'label': 'COLOR OF HAIR',
                            'required': false,
                            'keyboardType': TextInputType.text,
                          },
                          {
                            'label': 'DESCRIPTION OF HAIR',
                            'required': false,
                            'keyboardType': TextInputType.text,
                          },
                        ]),
                         SizedBox(height: 10),
                        UnderInfluenceCheckboxes(),
                         SizedBox(height: 10),


                        _buildSectionTitle('FOR CHILDREN IN CONFLICT WITH LAW', const Color.fromARGB(255, 30, 33, 90)),
                         SizedBox(height: 10),
                        _buildRowInputs([
                          {
                            'label': 'NAME OF GUARDIAN',
                            'required': false,
                            'keyboardType': TextInputType.text,
                          },
                        ]),
                        SizedBox(height: 10),
                          _buildRowInputs([
                            {
                              'label': 'GUARDIAN ADDRESS',
                              'required': false,
                              'keyboardType': TextInputType.text,
                            },
                          ]),
                        SizedBox(height: 10),
                          _buildRowInputs([
                            {
                              'label': 'HOME PHONE',
                              'required': false,
                              'keyboardType': TextInputType.phone,
                              'inputFormatters': [FilteringTextInputFormatter.digitsOnly],
                            },
                            {
                              'label': 'MOBILE PHONE',
                              'required': false,
                              'keyboardType': TextInputType.phone,
                              'inputFormatters': [FilteringTextInputFormatter.digitsOnly],
                            },
                          ]),
                        SizedBox(height: 10),



                        _buildSectionTitle('ITEM "C" - VICTIM DATA', const Color.fromARGB(255, 30, 33, 90)),
                        SizedBox(height: 10),
                       _buildRowInputs([
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
                        ]),
                        SizedBox(height: 10),
                         _buildRowInputs([
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
                        ]),
                        SizedBox(height: 10),
                         _buildRowInputs([
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
                        ]),
                        SizedBox(height: 10),
                        _buildRowInputs([
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
                        ]),
                                                SizedBox(height: 10),

                        _buildRowInputs([
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
                        ]),
                        SizedBox(height: 10),
                        _buildRowInputs([
                          {
                            'label': 'CURRENT ADDRESS (HOUSE NUMBER/STREET)',
                            'required': true,
                            'keyboardType': TextInputType.text,
                          },
                        ]),
                        SizedBox(height: 10),
                          _buildRowInputs([
                            {
                              'label': 'VILLAGE/SITIO',
                              'required': true,
                              'keyboardType': TextInputType.text,
                            },
                          ]),
                          SizedBox(height: 10),
                          _buildRowInputs([
                            {
                              'label': 'BARANGAY',
                              'required': true,
                              'keyboardType': TextInputType.text,
                            },
                            {
                              'label': 'TOWN/CITY',
                              'required': true,
                              'keyboardType': TextInputType.text,
                              'section': 'victim',
                            },
                            {
                              'label': 'PROVINCE',
                              'required': true,
                              'keyboardType': TextInputType.text,
                              'section': 'victim',
                            },
                          ]),
                          SizedBox(height: 10),

                          CheckboxListTile(
                          title: Text("Do you have another address?", style: TextStyle(fontSize: 15, color: Colors.black)), // Change text color to black
                          value: hasOtherAddressVictim,
                          onChanged: (bool? value) {
                            setState(() {
                              hasOtherAddressVictim = value ?? false;
                            });
                          },
                        ),
                        if (hasOtherAddressVictim) ...[
                          _buildRowInputs([
                            {
                              'label': 'OTHER ADDRESS (HOUSE NUMBER/STREET)',
                              'required': true,
                              'keyboardType': TextInputType.text,
                            },
                          ]),
                            SizedBox(height: 10),
                          _buildRowInputs([
                            {
                              'label': 'VILLAGE/SITIO',
                              'required': true,
                              'keyboardType': TextInputType.text,
                            },
                          ]),
                          SizedBox(height: 10),
                          _buildRowInputs([
                            {
                              'label': 'BARANGAY',
                              'required': true,
                              'keyboardType': TextInputType.text,
                            },
                            {
                              'label': 'TOWN/CITY',
                              'required': true,
                              'section': 'victimOther',
                            },
                            {
                              'label': 'PROVINCE',
                              'required': true,
                              'section': 'victimOther',
                            },
                          ]),
                          SizedBox(height: 10),
                        ],

                       

                        _buildRowInputs([
                          {
                            'label': 'HIGHEST EDUCATION ATTAINMENT',
                            'required': false,
                            'keyboardType': TextInputType.text,
                          },
                          {
                            'label': 'OCCUPATION',
                            'required': false,
                            'keyboardType': TextInputType.text,
                          },
                        ]),
                         SizedBox(height: 10),
                        _buildRowInputs([
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
                        ]),
                         SizedBox(height: 10),
            


                        _buildSectionTitle('ITEM "D" - NARRATIVE OF INCIDENT', const Color.fromARGB(255, 30, 33, 90)),
                        SizedBox(height: 10),
                        _buildRowInputs([
                          {
                            'label': 'TYPE OF INCIDENT',
                            'required': true,
                            'keyboardType': TextInputType.text,
                          },
                          {
                            'label': 'DATE/TIME OF INCIDENT',
                            'required': true,
                            'keyboardType': TextInputType.datetime,
                          },
                          {
                            'label': 'PLACE OF INCIDENT',
                            'required': true,
                            'keyboardType': TextInputType.text,
                          },
                        ]),
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
                        _buildRowInputs([
                          {
                            'label': 'NAME OF REPORTING PERSON',
                            'required': true,
                            'keyboardType': TextInputType.name,
                            'inputFormatters': [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                          },
                          {
                            'label': 'SIGNATURE OF REPORTING PERSON',
                            'required': true,
                            'keyboardType': TextInputType.text,
                          },
                        ]),
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

                        _buildRowInputs([
                          {
                            'label': 'NAME OF ADMINISTERING OFFICER(DUTY OFFICER)',
                            'required': true,
                            'keyboardType': TextInputType.name,
                            'inputFormatters': [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))],
                          },
                          {
                            'label': 'SIGNATURE OF ADMINISTERING OFFICER(DUTY OFFICER)',
                            'required': true,
                            'keyboardType': TextInputType.text,
                          },
                        ]),
                        SizedBox(height: 10),
                        _buildRowInputs([
                          {
                            'label': 'RANK, NAME AND DESIGNATION OF POLICE OFFICER (WHETHER HE/SHE IS THE DUTY INVESTIGATOR, INVESTIGATOR ON CASE OR THE ASSISTING POLICE OFFICER)',
                            'required': true,
                            'keyboardType': TextInputType.text,
                          },
                        ]),
                        SizedBox(height: 10),
                        _buildRowInputs([
                          {
                            'label': 'SIGNATURE OF DUTY INVESTIGATOR/ INVESTIGATOR ON CASE/ ASSISTING POLICE OFFICER',
                            'required': true,
                            'keyboardType': TextInputType.text,
                          },
                        ]),
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

                        _buildRowInputs([
                          {
                            'label': 'RANK/NAME OF DESK OFFICER:',
                            'required': true,
                            'keyboardType': TextInputType.text,
                          },
                        ]),
                        SizedBox(height: 10),
                        _buildRowInputs([
                          {
                            'label': 'SIGNATURE OF DESK OFFICER:',
                            'required': true,
                            'keyboardType': TextInputType.text,
                          },
                          {
                            'label': 'BLOTTER ENTRY NR:',
                            'required': true,
                            'keyboardType': TextInputType.text,
                          },
                        ]),
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
                        _buildRowInputs([
                          {
                            'label': 'Name of Police Station',
                            'required': true,
                            'keyboardType': TextInputType.text,
                          },
                          {
                            'label': 'Telephone',
                            'required': true,
                            'keyboardType': TextInputType.phone,
                            'inputFormatters': [FilteringTextInputFormatter.digitsOnly],
                          },
                        ]),
                        SizedBox(height: 10),
                        _buildRowInputs([
                          {
                            'label': 'Investigator-on-Case',
                            'required': true,
                            'keyboardType': TextInputType.text,
                          },
                          {
                            'label': 'Mobile Phone',
                            'required': true,
                            'keyboardType': TextInputType.phone,
                            'inputFormatters': [FilteringTextInputFormatter.digitsOnly],
                          },
                        ]),
                        SizedBox(height: 10),
                        _buildRowInputs([
                          {
                            'label': 'Name of Chief/Head of Office',
                            'required': true,
                            'keyboardType': TextInputType.text,
                          },
                          {
                            'label': 'Mobile Phone',
                            'required': true,
                            'keyboardType': TextInputType.phone,
                            'inputFormatters': [FilteringTextInputFormatter.digitsOnly],
                          },
                        ]),
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

  Widget _buildInputField(String label, {
    bool isRequired = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    List<String>? dropdownItems,
    TextEditingController? controller,
    bool? readOnly,
    VoidCallback? onTap,
    Function(String?)? onChanged,
    String? value,
  }) {
    return Expanded(
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 35,
              child: Row(
                children: [
                  Expanded(
                    child: Tooltip(
                      message: label,  // Show full text on hover
                      child: Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11, // Slightly reduced from 12
                          color: Colors.black,
                          height: 1.2, // Add line height control
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        softWrap: true, // Enable soft wrapping
                      ),
                    ),
                  ),
                  if (isRequired)
                    Text(
                      ' *',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 35,
              child: dropdownItems != null
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        return DropdownButtonFormField<String>(
                          value: value ?? dropdownPlaceholder,
                          items: dropdownItems.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              enabled: value != dropdownPlaceholder, // Disable placeholder item
                              child: Text(
                                value,
                                style: TextStyle(
                                  fontSize: constraints.maxWidth < 200 ? 12 : 14,
                                  color: value == dropdownPlaceholder 
                                      ? Colors.grey 
                                      : Colors.black,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != dropdownPlaceholder) {
                              onChanged?.call(newValue);
                            }
                          },
                          style: TextStyle(
                            fontSize: constraints.maxWidth < 200 ? 12 : 14,
                            color: Colors.black,
                          ),
                          dropdownColor: Colors.white,
                          icon: Icon(Icons.arrow_drop_down, color: Colors.black, size: 20),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(color: const Color.fromARGB(255, 188, 188, 188)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(color: const Color.fromARGB(255, 205, 205, 205)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            isDense: true,
                          ),
                          isExpanded: true,
                        );
                      },
                    )
                  : GestureDetector(
                      onTap: onTap,
                      child: AbsorbPointer(
                        absorbing: onTap != null,
                        child: TextFormField(
                          controller: controller,
                          readOnly: readOnly ?? false,
                          keyboardType: keyboardType,
                          inputFormatters: inputFormatters,
                          validator: validator,
                          style: TextStyle(fontSize: 13, color: Colors.black),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(color: const Color.fromARGB(255, 188, 188, 188)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(5),
                              borderSide: BorderSide(color: const Color.fromARGB(255, 205, 205, 205)),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            isDense: true,
                            errorStyle: TextStyle(height: 0),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRowInputs(List<Map<String, dynamic>> fields) {
    return Row(
      children: fields.map((field) {
        // Handle Reporting Person address
        if (field['label'] == 'PROVINCE' && field['section'] == 'reporting') {
          return _buildInputField(
            field['label'],
            isRequired: field['required'] ?? false,
            dropdownItems: [dropdownPlaceholder, ...PhilippinesData.provinces],
            onChanged: (String? newValue) {
              setState(() {
                reportingPersonProvince = newValue;
                reportingPersonCity = null; // Reset city when province changes
              });
            },
            value: reportingPersonProvince,
          );
        } else if (field['label'] == 'TOWN/CITY' && field['section'] == 'reporting') {
          return _buildInputField(
            field['label'],
            isRequired: field['required'] ?? false,
            dropdownItems: reportingPersonProvince != null 
                ? [dropdownPlaceholder, ...PhilippinesData.getCities(reportingPersonProvince!)]
                : [dropdownPlaceholder],
            value: reportingPersonCity ?? dropdownPlaceholder,
            onChanged: (String? newValue) {
              setState(() {
                reportingPersonCity = newValue;
              });
            },
          );
        }
        
        // Handle Reporting Person Other address
        else if (field['label'] == 'PROVINCE' && field['section'] == 'reportingOther') {
          return _buildInputField(
            field['label'],
            isRequired: field['required'] ?? false,
            dropdownItems: [dropdownPlaceholder, ...PhilippinesData.provinces],
            onChanged: (String? newValue) {
              setState(() {
                reportingPersonOtherProvince = newValue;
                reportingPersonOtherCity = null;
              });
            },
            value: reportingPersonOtherProvince,
          );
        } else if (field['label'] == 'TOWN/CITY' && field['section'] == 'reportingOther') {
          return _buildInputField(
            field['label'],
            isRequired: field['required'] ?? false,
            dropdownItems: reportingPersonOtherProvince != null 
                ? [dropdownPlaceholder, ...PhilippinesData.getCities(reportingPersonOtherProvince!)]
                : [dropdownPlaceholder],
            value: reportingPersonOtherCity ?? dropdownPlaceholder,
            onChanged: (String? newValue) {
              setState(() {
                reportingPersonOtherCity = newValue;
              });
            },
          );
        }

        // Handle Suspect address
        else if (field['label'] == 'PROVINCE' && field['section'] == 'suspect') {
          return _buildInputField(
            field['label'],
            isRequired: field['required'] ?? false,
            dropdownItems: [dropdownPlaceholder, ...PhilippinesData.provinces],
            onChanged: (String? newValue) {
              setState(() {
                suspectProvince = newValue;
                suspectCity = null; // Reset city when province changes
              });
            },
            value: suspectProvince,
          );
        } else if (field['label'] == 'TOWN/CITY' && field['section'] == 'suspect') {
          return _buildInputField(
            field['label'],
            isRequired: field['required'] ?? false,
            dropdownItems: suspectProvince != null 
                ? [dropdownPlaceholder, ...PhilippinesData.getCities(suspectProvince!)]
                : [dropdownPlaceholder],
            value: suspectCity ?? dropdownPlaceholder,
            onChanged: (String? newValue) {
              setState(() {
                suspectCity = newValue;
              });
            },
          );
        }
        
        // Handle Suspect Other address
        else if (field['label'] == 'PROVINCE' && field['section'] == 'suspectOther') {
          return _buildInputField(
            field['label'],
            isRequired: field['required'] ?? false,
            dropdownItems: [dropdownPlaceholder, ...PhilippinesData.provinces],
            onChanged: (String? newValue) {
              setState(() {
                suspectOtherProvince = newValue;
                suspectOtherCity = null;
              });
            },
            value: suspectOtherProvince,
          );
        } else if (field['label'] == 'TOWN/CITY' && field['section'] == 'suspectOther') {
          return _buildInputField(
            field['label'],
            isRequired: field['required'] ?? false,
            dropdownItems: suspectOtherProvince != null 
                ? [dropdownPlaceholder, ...PhilippinesData.getCities(suspectOtherProvince!)]
                : [dropdownPlaceholder],
            value: suspectOtherCity ?? dropdownPlaceholder,
            onChanged: (String? newValue) {
              setState(() {
                suspectOtherCity = newValue;
              });
            },
          );
        }

        // Handle Victim address
        else if (field['label'] == 'PROVINCE' && field['section'] == 'victim') {
          return _buildInputField(
            field['label'],
            isRequired: field['required'] ?? false,
            dropdownItems: [dropdownPlaceholder, ...PhilippinesData.provinces],
            onChanged: (String? newValue) {
              setState(() {
                victimProvince = newValue;
                victimCity = null; // Reset city when province changes
              });
            },
            value: victimProvince,
          );
        } else if (field['label'] == 'TOWN/CITY' && field['section'] == 'victim') {
          return _buildInputField(
            field['label'],
            isRequired: field['required'] ?? false,
            dropdownItems: victimProvince != null 
                ? [dropdownPlaceholder, ...PhilippinesData.getCities(victimProvince!)]
                : [dropdownPlaceholder],
            value: victimCity ?? dropdownPlaceholder,
            onChanged: (String? newValue) {
              setState(() {
                victimCity = newValue;
              });
            },
          );
        }

        // Handle Victim Other address
        else if (field['label'] == 'PROVINCE' && field['section'] == 'victimOther') {
          return _buildInputField(
            field['label'],
            isRequired: field['required'] ?? false,
            dropdownItems: [dropdownPlaceholder, ...PhilippinesData.provinces],
            onChanged: (String? newValue) {
              setState(() {
                victimOtherProvince = newValue;
                victimOtherCity = null;
              });
            },
            value: victimOtherProvince,
          );
        } else if (field['label'] == 'TOWN/CITY' && field['section'] == 'victimOther') {
          return _buildInputField(
            field['label'],
            isRequired: field['required'] ?? false,
            dropdownItems: victimOtherProvince != null 
                ? [dropdownPlaceholder, ...PhilippinesData.getCities(victimOtherProvince!)]
                : [dropdownPlaceholder],
            value: victimOtherCity ?? dropdownPlaceholder,
            onChanged: (String? newValue) {
              setState(() {
                victimOtherCity = newValue;
              });
            },
          );
        }

        // Handle all other fields
        return _buildInputField(
          field['label'],
          isRequired: field['required'] ?? false,
          keyboardType: field['keyboardType'],
          inputFormatters: field['inputFormatters'],
          validator: field['validator'],
          dropdownItems: field['dropdownItems'],
          controller: field['controller'],
          readOnly: field['readOnly'],
          onTap: field['onTap'],
        );
      }).toList(),
    );
  }

  Widget _buildInput(String label) {
    return Expanded(
      child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 8,
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
            ),
            SizedBox(height: 4),
            TextField(
              style: TextStyle(fontSize: 8, color: Colors.black), // Set text color to black
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color.fromARGB(255, 0, 0, 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                
                ),
                contentPadding: EdgeInsets.symmetric(vertical: 4), // Adjust content padding to decrease height
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color bgColor) {
    return Container(
      color: bgColor,
      padding: EdgeInsets.all(8),
      width: double.infinity,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}

class UnderInfluenceCheckboxes extends StatefulWidget {
  @override
  _UnderInfluenceCheckboxesState createState() => _UnderInfluenceCheckboxesState();
}

class _UnderInfluenceCheckboxesState extends State<UnderInfluenceCheckboxes> {
  bool no = false;
  bool drugs = false;
  bool liquor = false;
  bool others = false;
  TextEditingController othersController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "UNDER THE INFLUENCE?",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11, // Slightly larger for clarity
            color: Colors.black,
          ),
        ),
        SizedBox(height: 4), // Reduced spacing
        Wrap(
          spacing: 8, // Horizontal spacing between checkboxes
          runSpacing: 0, // Vertical spacing between rows
          children: [
            _buildCheckbox("NO", no, (value) {
              setState(() {
                no = value!;
                if (no) {
                  drugs = false;
                  liquor = false;
                  others = false;
                  othersController.clear(); // Clear text field if Others was selected
                }
              });
            }),
            _buildCheckbox("DRUGS", drugs, (value) {
              setState(() {
                drugs = value!;
                if (drugs) no = false; // Uncheck "NO" if any option is selected
              });
            }),
            _buildCheckbox("LIQUOR", liquor, (value) {
              setState(() {
                liquor = value!;
                if (liquor) no = false;
              });
            }),
            _buildCheckbox("OTHERS", others, (value) {
              setState(() {
                others = value!;
                if (others) {
                  no = false; // Uncheck "NO" if "OTHERS" is selected
                } else {
                  othersController.clear(); // Clear input when unchecked
                }
              });
            }),
          ],
        ),
        if (others) // Show text field only when "OTHERS" is checked
          Padding(
            padding: const EdgeInsets.only(top: 4.0), // Reduced top padding
            child: TextField(
              controller: othersController,
              decoration: InputDecoration(
                labelText: "Specify Other Influences",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.all(8),
              ),
              style: TextStyle(fontSize: 10),
            ),
          ),
      ],
    );
  }

  Widget _buildCheckbox(String label, bool value, Function(bool?) onChanged) {
    return IntrinsicWidth(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: 0.8, // Make checkbox smaller
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              visualDensity: VisualDensity.compact,
              activeColor: Colors.blue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.black), // Reduced font size
          ),
        ],
      ),
    );
  }
}

class SubmitButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;

  const SubmitButton({Key? key, required this.formKey}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF1E215A),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () {
          if (formKey.currentState?.validate() ?? false) {
            // Proceed with form submission
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send),
            SizedBox(width: 8),
            Text(
              'Submit Report',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

