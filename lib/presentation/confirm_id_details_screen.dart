import 'package:flutter/material.dart';
import 'dart:io';
import '../core/app_export.dart';
import 'package:intl/intl.dart';

class ConfirmIDDetailsScreen extends StatefulWidget {
  final File frontImage;
  final File? backImage;
  final String idType;
  
  const ConfirmIDDetailsScreen({
    Key? key, 
    required this.frontImage, 
    this.backImage, 
    required this.idType
  }) : super(key: key);

  @override
  _ConfirmIDDetailsScreenState createState() => _ConfirmIDDetailsScreenState();
}

class _ConfirmIDDetailsScreenState extends State<ConfirmIDDetailsScreen> {
  bool isSubmitting = false;
  
  // Simulated extracted data from ID
  // In a real app, this would come from an OCR service or API
  final Map<String, dynamic> extractedData = {
    'firstName': 'John',
    'middleName': 'Michael',
    'lastName': 'Doe',
    'dateOfBirth': DateTime(1990, 5, 15),
  };

  // Current user email from Firebase Auth
  final String userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Not available';

  @override
  void initState() {
    super.initState();
    // In a real app, here we would:
    // 1. Call an OCR API to extract text from images
    // 2. Process the extracted text to identify relevant fields
    // 3. Update the extractedData map with real values
  }

  Future<void> _submitVerification() async {
    setState(() {
      isSubmitting = true;
    });

    try {
      // Simulate API call delay
      await Future.delayed(Duration(seconds: 2));
      
      // Here we would actually:
      // 1. Upload images to Firebase Storage
      // 2. Save extracted data to Firestore
      // 3. Update user verification status
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // In a real implementation, update verification status in Firebase
        final AuthService authService = AuthService();
        await authService.updateIDVerificationStatus(
          uid: currentUser.uid,
          submitted: true,
          idType: widget.idType,
        );
      }
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ID verification submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to home page
      Navigator.pushReplacementNamed(context, '/home');
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting verification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSubmitting = false;
        });
      }
    }
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
                        
                        // Title
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'CONFIRM YOUR INFORMATION',
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
                            'Please verify that the information extracted from your ID is correct before submitting',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        
                        // Display uploaded ID images
                        Row(
                          children: [
                            // Front image
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildInputLabel('Front of ID'),
                                  SizedBox(height: 8),
                                  Container(
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.file(
                                        widget.frontImage,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Back image (if available)
                            if (widget.backImage != null) ...[
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInputLabel('Back of ID'),
                                    SizedBox(height: 8),
                                    Container(
                                      height: 120,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: Image.file(
                                          widget.backImage!,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        
                        SizedBox(height: 25),
                        
                        // Display read-only form with extracted information
                        _buildReadOnlyField('First Name', extractedData['firstName']),
                        _buildReadOnlyField('Middle Name', extractedData['middleName']),
                        _buildReadOnlyField('Last Name', extractedData['lastName']),
                        _buildReadOnlyField(
                          'Date of Birth', 
                          DateFormat('MM/dd/yyyy').format(extractedData['dateOfBirth']),
                        ),
                        _buildReadOnlyField('Email', userEmail),
                        
                        SizedBox(height: 25),
                        
                        // Action Buttons
                        Row(
                          children: [
                            // Go back button
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isSubmitting ? null : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: EdgeInsets.symmetric(vertical: 15),
                                  side: BorderSide(color: Color.fromARGB(255, 255, 43, 43), width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'CANCEL',
                                  style: TextStyle(
                                    color: Color.fromARGB(255, 255, 43, 43),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 10),
                            
                            // Submit button
                            Expanded(
                              child: ElevatedButton(
                                onPressed: isSubmitting ? null : _submitVerification,
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
                                        Text('SUBMITTING...', style: TextStyle(fontSize: 14)),
                                      ],
                                    )
                                  : Text(
                                      'SUBMIT',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
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

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel(label),
        SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
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