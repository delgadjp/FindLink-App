import '/core/app_export.dart';
import 'package:intl/intl.dart';
import 'package:flutter/gestures.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  final TextEditingController phoneNumberController = TextEditingController(); // Add phone number controller
  
  String selectedGender = 'Male'; // Default gender value
  DateTime? selectedDate;
  int? age;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isFirstNameValid = true;
  bool _isMiddleNameValid = true; // Added middle name validation
  bool _isLastNameValid = true;
  bool _isEmailValid = true;
  bool _isPasswordValid = true;
  bool _isPhoneNumberValid = true; // Add phone number validation state
  bool _termsAccepted = false; // Add Terms of Service checkbox state
  final _formKey = GlobalKey<FormState>();

  // Philippines country code
  final String countryCode = '+63';
  
  // Phone number validation regex - expects exactly 10 digits
  final RegExp phoneRegex = RegExp(r'^\d{10}$');

  // Show Terms of Service modal
  void _showTermsOfServiceModal() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Terms and Conditions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A5298),
                  ),
                ),
                SizedBox(height: 15),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome to the Missing Person Alarm Sheet (MPAS). By creating an account, you agree to the following terms:',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                        SizedBox(height: 10),
                        _buildTermItem('You will provide accurate and truthful information when submitting or updating any case or report.'),
                        _buildTermItem('All tips, sightings, or leads submitted are subject to verification by authorized personnel.'),
                        _buildTermItem('You will not misuse or falsify information that may hinder active investigations or cause unnecessary panic.'),
                        _buildTermItem('Your personal data will be kept confidential and used solely for case coordination and communication purposes.'),
                        _buildTermItem('Authorities have the right to deactivate accounts found misusing the platform.'),
                        _buildTermItem('This platform is for community help and should not be treated as a substitute for direct police reporting.'),
                        SizedBox(height: 10),
                        Text(
                          'For more information, please contact our support team. Your cooperation helps save lives.',
                          style: TextStyle(fontSize: 14, color: Colors.black87, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),                SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey,
                      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTermItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 14, color: Color(0xFF2A5298), fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // Validate phone number
  bool _validatePhoneNumber(String phone) {
    return phoneRegex.hasMatch(phone);
  }

  // Format phone number as user types (remove non-digit characters)
  String _formatPhoneNumber(String text) {
    return text.replaceAll(RegExp(r'[^0-9]'), '');
  }
  
  // Get the full phone number with country code
  String get fullPhoneNumber {
    return '$countryCode${phoneNumberController.text}';
  }

  void _calculateAge(DateTime birthDate) {
    final today = DateTime.now();
    int calculatedAge = today.year - birthDate.year;
    if (today.month < birthDate.month || 
        (today.month == birthDate.month && today.day < birthDate.day)) {
      calculatedAge--;
    }
    setState(() {
      age = calculatedAge;
    });
  }

  bool _validateEmail(String email) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime(DateTime.now().year - 18, DateTime.now().month, DateTime.now().day),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(), // Cannot pick future dates
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color(0xFFFFD27E),
              onPrimary: Color(0xFF424242),
              surface: Colors.white,
              onSurface: Color(0xFF424242),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFFFFD27E),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _calculateAge(picked);
      });
    }
  }

  // Method to validate form and proceed to ID validation
  void _validateAndProceedToIDValidation() {
    if (_formKey.currentState!.validate()) {
      if (selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please select your date of birth'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
      // Create a map with user registration data to pass to ID validation
      Map<String, dynamic> registrationData = {
        'email': emailController.text.trim(),
        'password': passwordController.text,
        'firstName': firstNameController.text.trim(),
        'middleName': middleNameController.text.trim(),
        'lastName': lastNameController.text.trim(),
        'dateOfBirth': selectedDate,
        'age': age,
        'gender': selectedGender,
        'phoneNumber': fullPhoneNumber,
      };
      
      // Navigate to ID validation with registration data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => IDValidationScreen(
            registrationData: registrationData,
            isFromRegistration: true,
          ),
        ),
      );
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
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          width: 120,
                          height: 120,
                          fit: BoxFit.contain,
                        ),
                        SizedBox(height: 10),
                        
                        // Create Account title inside the form container
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Text(
                            'CREATE ACCOUNT',
                            style: TextStyle(
                              color: Color(0xFF424242),
                              fontSize: 22,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Personal Information Section
                              _buildSectionHeader("Personal Information"),
                              
                              // First Name
                              _buildInputLabel('First Name'),
                              SizedBox(height: 5),
                              TextFormField(
                                controller: firstNameController,
                                style: TextStyle(color: Colors.black),
                                decoration: _buildInputDecoration(
                                  hintText: 'Enter your first name',
                                  prefixIcon: Icons.person_outline,
                                  isValid: _isFirstNameValid,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _isFirstNameValid = value.isNotEmpty;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your first name';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 15),

                              // Middle Name
                              _buildInputLabel('Middle Name'),
                              SizedBox(height: 5),
                              TextFormField(
                                controller: middleNameController,
                                style: TextStyle(color: Colors.black),
                                decoration: _buildInputDecoration(
                                  hintText: 'Enter your middle name',
                                  prefixIcon: Icons.person_outline,
                                  isValid: _isMiddleNameValid,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _isMiddleNameValid = value.isNotEmpty;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your middle name';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 15),

                              // Last Name
                              _buildInputLabel('Last Name'),
                              SizedBox(height: 5),
                              TextFormField(
                                controller: lastNameController,
                                style: TextStyle(color: Colors.black),
                                decoration: _buildInputDecoration(
                                  hintText: 'Enter your last name',
                                  prefixIcon: Icons.person_outline,
                                  isValid: _isLastNameValid,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _isLastNameValid = value.isNotEmpty;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your last name';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 15),

                              // Birthday and Age row
                              Row(
                                children: [
                                  // Date of Birth - Takes 2/3 of the width
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildInputLabel('Date of Birth'),
                                        SizedBox(height: 5),
                                        InkWell(
                                          onTap: () => _selectDate(context),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(Icons.calendar_today, color: Color(0xFF53C0FF), size: 20),
                                                SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    selectedDate == null ? 'Select date' : 
                                                    DateFormat('MM/dd/yyyy').format(selectedDate!),
                                                    style: TextStyle(
                                                      color: selectedDate == null ? Colors.grey : Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  
                                  // Age - Takes 1/3 of the width
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildInputLabel('Age'),
                                        SizedBox(height: 5),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: Colors.grey.shade300),
                                          ),
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            age == null ? '-' : '$age',
                                            style: TextStyle(
                                              color: age == null ? Colors.grey : Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 15),
                              
                              // Gender field
                              _buildInputLabel('Gender'),
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
                                    Icon(Icons.people_outline, color: Color(0xFF53C0FF)),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: selectedGender,
                                          style: TextStyle(color: Colors.black),
                                          isExpanded: true,
                                          dropdownColor: Colors.white,
                                          icon: Icon(Icons.arrow_drop_down, color: Color(0xFF53C0FF)),
                                          items: <String>['Male', 'Female', 'Prefer not to say']
                                              .map<DropdownMenuItem<String>>((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value, style: TextStyle(color: Colors.black)),
                                            );
                                          }).toList(),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              selectedGender = newValue!;
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 25),
                              
                              // Account Information Section
                              _buildSectionHeader("Account Information"),
                              
                              // Email address
                              _buildInputLabel('Email Address'),
                              SizedBox(height: 5),
                              TextFormField(
                                controller: emailController,
                                style: TextStyle(color: Colors.black),
                                keyboardType: TextInputType.emailAddress,
                                decoration: _buildInputDecoration(
                                  hintText: 'Enter your email',
                                  prefixIcon: Icons.email_outlined,
                                  isValid: _isEmailValid,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _isEmailValid = value.isEmpty || _validateEmail(value);
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your email address';
                                  }
                                  if (!_validateEmail(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 15),

                              // Phone Number
                              _buildInputLabel('Phone Number'),
                              SizedBox(height: 5),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: _isPhoneNumberValid ? Colors.grey.shade300 : Colors.red),
                                ),
                                child: Row(
                                  children: [
                                    // Country code prefix container
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(9),
                                          bottomLeft: Radius.circular(9),
                                        ),
                                        border: Border(
                                          right: BorderSide(color: Colors.grey.shade300),
                                        ),
                                      ),
                                      child: Text(
                                        countryCode,
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    // Phone number input field
                                    Expanded(
                                      child: TextFormField(
                                        controller: phoneNumberController,
                                        style: TextStyle(color: Colors.black),
                                        keyboardType: TextInputType.phone,
                                        decoration: InputDecoration(
                                          hintText: 'Enter your phone number',
                                          prefixIcon: Icon(
                                            Icons.phone_outlined,
                                            color: _isPhoneNumberValid ? Color(0xFF53C0FF) : Colors.red,
                                          ),
                                          border: InputBorder.none,
                                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                                          errorStyle: TextStyle(height: 0), // Hide error text as we'll use red border
                                        ),
                                        onChanged: (value) {
                                          setState(() {
                                            phoneNumberController.text = _formatPhoneNumber(value);
                                            phoneNumberController.selection = TextSelection.fromPosition(
                                              TextPosition(offset: phoneNumberController.text.length),
                                            );
                                            _isPhoneNumberValid = _validatePhoneNumber(phoneNumberController.text);
                                          });
                                        },
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your phone number';
                                          }
                                          if (!_validatePhoneNumber(value)) {
                                            return 'Please enter a valid phone number (10 digits)';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 5),
                              // Phone number format hint
                              Padding(
                                padding: EdgeInsets.only(left: 5),
                                child: Text(
                                  'Enter 10 digits (e.g., 9123456789)',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              SizedBox(height: 15),

                              // Password
                              _buildInputLabel('Password'),
                              SizedBox(height: 5),
                              TextFormField(
                                controller: passwordController,
                                style: TextStyle(color: Colors.black),
                                obscureText: _obscurePassword,
                                decoration: _buildInputDecoration(
                                  hintText: 'Enter your password',
                                  prefixIcon: Icons.lock_outline,
                                  isValid: _isPasswordValid,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _isPasswordValid = value.length >= 8;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  if (value.length < 8) {
                                    return 'Password must be at least 8 characters';
                                  }
                                  if (!value.contains(RegExp(r'[A-Z]'))) {
                                    return 'Password must contain at least one uppercase letter';
                                  }
                                  if (!value.contains(RegExp(r'[0-9]'))) {
                                    return 'Password must contain at least one number';
                                  }
                                  if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
                                    return 'Password must contain at least one special character';
                                  }
                                  return null;
                                },
                              ),
                              _buildPasswordStrengthIndicator(passwordController.text),
                              SizedBox(height: 15),

                              // Confirm Password
                              _buildInputLabel('Confirm Password'),
                              SizedBox(height: 5),
                              TextFormField(
                                controller: confirmPasswordController,
                                style: TextStyle(color: Colors.black),
                                obscureText: _obscureConfirmPassword,
                                decoration: _buildInputDecoration(
                                  hintText: 'Confirm your password',
                                  prefixIcon: Icons.lock_outline,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                      color: Colors.grey,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureConfirmPassword = !_obscureConfirmPassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please confirm your password';
                                  }
                                  if (value != passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 15),                              // Terms of Service checkbox
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Checkbox(
                                    value: _termsAccepted,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _termsAccepted = value ?? false;
                                      });
                                    },
                                    activeColor: Color(0xFFFFD27E),
                                    checkColor: Color(0xFF424242),
                                  ),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        style: TextStyle(
                                          color: Color(0xFF2A5298),
                                          fontSize: 14,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: 'I agree to all statements in ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(
                                            text: 'Terms of Service',
                                            style: TextStyle(
                                              color: Color.fromARGB(255, 13, 95, 236),
                                              fontWeight: FontWeight.bold,
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                _showTermsOfServiceModal();
                                              },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 30),// Continue Button - Changed from Register to Continue
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    // Validate that the Terms of Service checkbox is checked
                                    if (!_termsAccepted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Please accept the Terms of Service to continue'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }
                                    _validateAndProceedToIDValidation();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFFFFD27E),
                                    foregroundColor: Color(0xFF424242),
                                    padding: EdgeInsets.symmetric(vertical: 15),
                                    elevation: 2,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'SIGN UP',
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
                        ),
                        
                        // Already have an account row
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Already have an account?",
                                style: TextStyle(
                                  color: Color(0xFF424242),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  'Log In',
                                  style: TextStyle(
                                    color: Color(0xFF53C0FF),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
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

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    bool isValid = true,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(prefixIcon, color: isValid ? Color(0xFF53C0FF) : Colors.red),
      suffixIcon: suffixIcon,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isValid ? Colors.grey.shade300 : Colors.red,
          width: 1.0,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: isValid ? Color(0xFF53C0FF) : Colors.red,
          width: 2.0,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Colors.red,
          width: 1.0,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Colors.red,
          width: 2.0,
        ),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      errorStyle: TextStyle(color: Colors.red, fontSize: 12),
    );
  }

  Widget _buildPasswordStrengthIndicator(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    String strengthText = '';
    Color strengthColor = Colors.grey;
    double indicatorValue = 0;

    switch (strength) {
      case 0:
        strengthText = '';
        indicatorValue = 0;
        strengthColor = Colors.grey;
        break;
      case 1:
        strengthText = 'Weak';
        indicatorValue = 0.25;
        strengthColor = Colors.red;
        break;
      case 2:
        strengthText = 'Fair';
        indicatorValue = 0.5;
        strengthColor = Colors.orange;
        break;
      case 3:
        strengthText = 'Good';
        indicatorValue = 0.75;
        strengthColor = Colors.yellow;
        break;
      case 4:
        strengthText = 'Strong';
        indicatorValue = 1.0;
        strengthColor = Colors.green;
        break;
    }

    if (password.isEmpty) {
      return SizedBox(height: 0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 5),
        LinearProgressIndicator(
          value: indicatorValue,
          backgroundColor: Colors.grey.shade200,
          color: strengthColor,
          minHeight: 4,
          borderRadius: BorderRadius.circular(2),
        ),
        SizedBox(height: 5),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Password Strength:',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            Text(
              strengthText,
              style: TextStyle(
                color: strengthColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}