import '/core/app_export.dart';
import 'dart:io';
import '../widgets/step_indicator.dart';

class IDValidationScreen extends StatefulWidget {
  // Add parameters for registration data and flow control
  final Map<String, dynamic>? registrationData;
  final bool isFromRegistration;
  
  IDValidationScreen({
    Key? key,
    this.registrationData,
    this.isFromRegistration = false,
  }) : super(key: key);
  
  @override
  _IDValidationScreenState createState() => _IDValidationScreenState();
}

class _IDValidationScreenState extends State<IDValidationScreen> {
  final ImagePicker _picker = ImagePicker();
  File? idImage;
  bool isSubmitting = false;
  
  // ID types available for selection
  final List<String> idTypes = [
    'Driver\'s License',
    'Philippine Identification Card',
  ];
  
  String selectedIdType = 'Driver\'s License'; // Default value

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          idImage = File(pickedFile.path);
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

  void _showImageSourceDialog() {
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
                              'Choose how to upload your ID',
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

  // Modified to validate and navigate to confirmation screen including registration data
  void _validateAndContinue() {
    if (idImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please provide an image of your ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to the confirmation screen with all required data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmIDDetailsScreen(
          idImage: idImage!, 
          idType: selectedIdType,
          registrationData: widget.isFromRegistration ? widget.registrationData : null,
          isFromRegistration: widget.isFromRegistration,
        ),
      ),
    );
  }

  Widget _buildImageUploader(String title, String description, File? image) {
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
          onTap: _showImageSourceDialog,
          child: Container(
            height: 200,
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
                        size: 50,
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
              onPressed: _showImageSourceDialog,
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
      appBar: widget.isFromRegistration ? AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ID Validation',
          style: TextStyle(color: Colors.white),
        ),
      ) : null,
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
                            widget.isFromRegistration
                                ? 'Please provide valid ID to complete your registration'
                                : 'Please provide valid ID to verify your identity',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),

                        if (widget.isFromRegistration) ...[
                          StepIndicator(currentStep: 2),
                          SizedBox(height: 24),
                        ],
                        
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

                            // ID Image Upload Section
                            _buildSectionHeader("Upload ID Image"),
                            
                            // ID Image
                            _buildImageUploader(
                              'ID Image', 
                              'Upload a clear photo of your ID card', 
                              idImage
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
                            
                            // Continue Button
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