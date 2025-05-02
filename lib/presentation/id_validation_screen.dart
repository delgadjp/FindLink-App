import '../core/app_export.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:findlink/presentation/confirm_id_details_screen.dart';

class IDValidationScreen extends StatefulWidget {
  @override
  _IDValidationScreenState createState() => _IDValidationScreenState();
}

class _IDValidationScreenState extends State<IDValidationScreen> {
  final ImagePicker _picker = ImagePicker();
  File? frontImage;
  File? backImage;
  bool isSubmitting = false;
  
  // ID types available for selection
  final List<String> idTypes = [
    'Driver\'s License',
    'National ID',
  ];
  
  String selectedIdType = 'Driver\'s License'; // Default value

  Future<void> _pickImage(ImageSource source, int imageType) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          switch (imageType) {
            case 1:
              frontImage = File(pickedFile.path);
              break;
            case 2:
              backImage = File(pickedFile.path);
              break;
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceDialog(int imageType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Choose Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.photo_library, color: Color(0xFF53C0FF)),
                        SizedBox(width: 10),
                        Text('Gallery'),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery, imageType);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(),
                ),
                GestureDetector(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt, color: Color(0xFF53C0FF)),
                        SizedBox(width: 10),
                        Text('Camera'),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera, imageType);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Modified to validate and navigate to confirmation screen instead of direct submission
  void _validateAndContinue() {
    // Check if required images are provided based on ID type
    if (frontImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide front image of your ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Only check for back image if National ID is selected
    if (selectedIdType == 'National ID' && backImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide both front and back images for National ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to the confirmation screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmIDDetailsScreen(
          frontImage: frontImage!, 
          backImage: selectedIdType == 'National ID' ? backImage : null,
          idType: selectedIdType,
        ),
      ),
    );
  }

  Widget _buildImageUploader(String title, String description, File? image, int imageType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel(title),
        SizedBox(height: 5),
        Text(
          description,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 10),
        InkWell(
          onTap: () => _showImageSourceDialog(imageType),
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: image == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 40,
                        color: Color(0xFF53C0FF),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Tap to upload',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
          ),
        ),
        if (image != null) 
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _showImageSourceDialog(imageType),
              child: Text(
                'Change Image',
                style: TextStyle(color: Color(0xFF53C0FF)),
              ),
            ),
          ),
        SizedBox(height: 15),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Container(
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2A5298), // Darker blue at top
              Color(0xFF4B89DC), // Lighter blue at bottom
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Form with styling
                  Container(
                    margin: EdgeInsets.fromLTRB(0, 20, 0, 20),
                    padding: EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Logo above the form title
                        Image.asset(
                          ImageConstant.logoFinal,
                          width: 100,
                          height: 100,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 10),
                        
                        // ID Validation title
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'ID VALIDATION',
                            style: TextStyle(
                              color: Color(0xFF424242),
                              fontSize: 22,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        
                        // Description
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(
                            'Please provide valid ID to verify your identity',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        
                        // ID Validation Form
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ID Type Selection
                            _buildSectionHeader("ID Information"),
                            
                            _buildInputLabel('ID Type'),
                            SizedBox(height: 5),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.credit_card, color: Color(0xFF53C0FF)),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedIdType,
                                        style: TextStyle(color: Colors.black),
                                        dropdownColor: Colors.white,
                                        isExpanded: true,
                                        icon: Icon(Icons.arrow_drop_down, color: Color(0xFF53C0FF)),
                                        items: idTypes.map<DropdownMenuItem<String>>((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(
                                              value,
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 14,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            selectedIdType = newValue!;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 25),

                            // Image Upload Section
                            _buildSectionHeader("Upload ID Images"),
                            
                            // Front of ID
                            _buildImageUploader(
                              'Front of ID', 
                              'Upload a clear photo of the front of your ID', 
                              frontImage, 
                              1
                            ),
                            
                            // Back of ID - Only show for National ID
                            if (selectedIdType == 'National ID')
                              _buildImageUploader(
                                'Back of ID', 
                                'Upload a clear photo of the back of your ID', 
                                backImage, 
                                2
                              ),
                            
                            SizedBox(height: 15),
                            
                            // Terms and Privacy
                            Container(
                              padding: EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Text(
                                'By submitting your ID, you agree that we may verify your identity. Your information will be handled in accordance with our Privacy Policy.',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            
                            SizedBox(height: 30),
                            
                            // Continue Button (renamed from Submit)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isSubmitting ? null : _validateAndContinue,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFFFFD27E),
                                  foregroundColor: Color(0xFF424242),
                                  padding: EdgeInsets.symmetric(vertical: 15),
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  disabledBackgroundColor: Colors.grey.shade400,
                                ),
                                child: isSubmitting 
                                  ? Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text('PROCESSING...'),
                                      ],
                                    )
                                  : Text(
                                      'CONTINUE',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Color(0xFF424242),
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 5),
        Divider(color: Color(0xFF53C0FF), thickness: 1.5, endIndent: 240),
        SizedBox(height: 15),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Color(0xFF424242),
        fontSize: 14,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w600,
      ),
    );
  }
}