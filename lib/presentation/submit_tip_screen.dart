import '../core/app_export.dart';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class SubmitTipScreen extends StatefulWidget {
  @override
  _SubmitTipScreenState createState() => _SubmitTipScreenState();
}

class _SubmitTipScreenState extends State<SubmitTipScreen> {
  final _formKey = GlobalKey<FormState>();
  File? _image;
  final picker = ImagePicker();

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
  };

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
    if (!RegExp(r'^\d{1,3}(\.\d{1,2})?$').hasMatch(value)) 
      return 'Enter height in cm (e.g. 175 or 175.5)';
    double? height = double.tryParse(value);
    if (height! < 30 || height > 250) 
      return 'Please enter a valid height (30-250 cm)';
    return null;
  }

  /// Pick an image from the gallery
  Future<void> _pickImage() async {
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = File(pickedFile.path);
          tipData['image'] = pickedFile.path;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  /// Submit tip data with validation
  Future<void> _submitTip() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_image == null) {
        // 🔥 Require an image
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please upload an image.')),
        );
        return;
      }

      try {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        List<String> tips = prefs.getStringList('tips') ?? [];

        tipData['name'] = _nameController.text;
        tipData['phone'] = _phoneController.text;
        tipData['dateLastSeen'] = _dateLastSeenController.text;
        tipData['timeLastSeen'] = _timeLastSeenController.text;
        tipData['gender'] = selectedGender ?? '';
        tipData['age'] = _ageController.text;
        tipData['clothing'] = _clothingController.text;
        tipData['features'] = _featuresController.text;
        tipData['height'] = _heightController.text;
        tipData['hairColor'] = selectedHairColor ?? '';
        tipData['eyeColor'] = selectedEyeColor == 'Other' 
            ? _customEyeColorController.text 
            : (selectedEyeColor ?? '');
        tipData['description'] = _descriptionController.text;
        tipData['image'] = _image!.path; // 🔥 Ensure image is included

        tips.add(jsonEncode(tipData));
        await prefs.setStringList('tips', tips);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tip submitted successfully!')),
        );

        // Clear fields after submission
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
        setState(() => _image = null);
      } catch (e) {
        print('Error saving tip: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting tip.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Submit Tip",
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
            colors: [Color.fromARGB(255, 0, 0, 0), Color(0xFF1565C0)],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle("Submit Information"),
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
                        _buildSectionHeader("Additional Details"),
                        _buildTextField(_clothingController, "Clothing Description", icon: Icons.checkroom),
                        _buildTextField(_featuresController, "Distinguishing Features", icon: Icons.face_retouching_natural),
                        _buildTextField(_descriptionController, "Additional Description",
                            maxLines: 3, icon: Icons.description),
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
                      backgroundColor: Colors.orange,
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
  }) {
    List<TextInputFormatter>? formatters;
    String? Function(String?)? validator;
    TextInputType? keyboardType;

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
          FilteringTextInputFormatter.allow(RegExp(r'^\d{1,3}(\.\d{0,2})?')),
        ];
        validator = _validateHeight;
        keyboardType = TextInputType.numberWithOptions(decimal: true);
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
        controller: controller,
        style: TextStyle(color: Colors.black87),
        decoration: _getInputDecoration(label, icon),
        inputFormatters: formatters,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
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
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<String> items,
    Function(String?) onChanged,
    IconData icon,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
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
      child: _image != null
          ? Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_image!, height: 200, fit: BoxFit.cover),
                ),
                SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => setState(() => _image = null),
                  icon: Icon(Icons.delete, color: Colors.red),
                  label: Text('Remove Image', style: TextStyle(color: Colors.red)),
                )
              ],
            )
          : InkWell(
              onTap: _pickImage,
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
                      'Upload Image',
                      style: TextStyle(color: Color(0xFF0D47A1)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}