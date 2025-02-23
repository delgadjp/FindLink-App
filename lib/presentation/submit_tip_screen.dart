import '../core/app_export.dart';
import 'dart:convert';
import 'dart:io';
 
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
        tipData['gender'] = _genderController.text;
        tipData['age'] = _ageController.text;
        tipData['clothing'] = _clothingController.text;
        tipData['features'] = _featuresController.text;
        tipData['height'] = _heightController.text;
        tipData['hairColor'] = _hairColorController.text;
        tipData['eyeColor'] = _eyeColorController.text;
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
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Color(0xFF0D47A1),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Provide a tip to help with the investigation:",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                SizedBox(height: 20),
                _buildTextField(_nameController, "Name", required: true),
                _buildTextField(_phoneController, "Phone", required: true),
                _buildTextField(_dateLastSeenController, "Date Last Seen",
                    required: true),
                _buildTextField(_timeLastSeenController, "Time Last Seen",
                    required: true),
                _buildTextField(_genderController, "Gender", required: true),
                _buildTextField(_ageController, "Age", required: true),
                _buildTextField(_clothingController, "Clothing Description",
                    required: true),
                _buildTextField(_featuresController, "Distinguishing Features",
                    required: true),
                _buildTextField(_heightController, "Height", required: true),
                _buildTextField(_hairColorController, "Hair Color",
                    required: true),
                _buildTextField(_eyeColorController, "Eye Color",
                    required: true),
                _buildTextField(
                    _descriptionController, "Additional Description",
                    maxLines: 3, required: true),
                SizedBox(height: 10),
                _image != null
                    ? Column(
                        children: [
                          Image.file(_image!, height: 100),
                          TextButton(
                            onPressed: () => setState(() => _image = null),
                            child: Text('Remove Image',
                                style: TextStyle(color: Colors.white)),
                          )
                        ],
                      )
                    : TextButton(
                        onPressed: _pickImage,
                        child: Text('Upload Image',
                            style: TextStyle(color: Colors.white)),
                      ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submitTip,
                  child: Text("Submit Tip"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
 
  /// Helper function to create text fields
  Widget _buildTextField(TextEditingController controller, String label,
      {bool required = false, int maxLines = 1}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: Colors.white), // Text color white
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white), // Label text white
          border: OutlineInputBorder(),
        ),
        maxLines: maxLines,
        validator: (value) {
          if (required && (value == null || value.isEmpty)) {
            return 'Please enter $label.';
          }
          return null;
        },
      ),
    );
  }
}