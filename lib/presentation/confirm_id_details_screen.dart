import 'dart:io';
import 'dart:convert';
import '/core/app_export.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class ConfirmIDDetailsScreen extends StatefulWidget {
  final File idImage;
  final String idType;
  final Map<String, dynamic>? registrationData;
  final bool isFromRegistration;
  
  const ConfirmIDDetailsScreen({
    Key? key, 
    required this.idImage, 
    required this.idType,
    this.registrationData,
    this.isFromRegistration = false,
  }) : super(key: key);

  @override
  _ConfirmIDDetailsScreenState createState() => _ConfirmIDDetailsScreenState();
}

class _ConfirmIDDetailsScreenState extends State<ConfirmIDDetailsScreen> {
  bool isSubmitting = false;
  bool isLoading = true;
  bool _isDataMatching = false; // Default to false until validation
  String? _mismatchReason; // Store reason if data doesn't match
  bool _isCorrectIDType = true; // Flag to check if uploaded ID matches selected type
  bool _isExpired = false; // Flag to check if driver's license is expired

  // Google Vision API key from TipService
  final String _visionApiKey = 'AIzaSyBpeXXTgrLeT9PuUT-8H-AXPTW6sWlnys0';
    // Data extracted from ID via OCR
  Map<String, dynamic> extractedData = {
    'firstName': '',
    'middleName': '',
    'lastName': '',
    'dateOfBirth': null,
    'expirationDate': null, // Added field for expiration date
    'philIDNumber': '', // Added field for Philippine ID number
    'address': '', // Added field for complete address
    'licenseNo': '', // Added field for Driver's License number
  };

  // Current user email from Firebase Auth or registration data
  late String userEmail;

  @override
  void initState() {
    super.initState();
    
    // Get email from registration data or current user
    if (widget.isFromRegistration && widget.registrationData != null) {
      userEmail = widget.registrationData!['email'];
    } else {
      // Get current user email if already signed in
      userEmail = FirebaseAuth.instance.currentUser?.email ?? 'Not available';
    }
    
    // Start OCR extraction when screen loads
    _extractTextFromID();
  }
  
  // Extract text from ID using Google Cloud Vision API
  Future<void> _extractTextFromID() async {
    try {
      // Set loading state
      setState(() {
        isLoading = true;
        _isDataMatching = false; // Reset validation status during loading
        _isCorrectIDType = true; // Reset ID type validation
      });
      
      // Process ID image with OCR
      final ocrResult = await _processImageWithVisionAPI(widget.idImage);

      // First check if the ID type matches what was selected
      _validateIDType(ocrResult);
      
      // If ID type doesn't match, don't proceed with data extraction
      if (!_isCorrectIDType) {
        setState(() {
          isLoading = false;
        });
        return;
      }
      
      // Extract data based on ID type
      if (widget.idType == 'Driver\'s License') {
        _extractDriversLicenseData(ocrResult);
      } else {
        _extractNationalIDData(ocrResult);
      }
      
      // Check if any data was successfully extracted
      bool hasExtractedData = extractedData['firstName']?.isNotEmpty == true ||
                             extractedData['middleName']?.isNotEmpty == true ||
                             extractedData['lastName']?.isNotEmpty == true ||
                             extractedData['dateOfBirth'] != null;
      
      // After extraction is complete, validate against registration data if in registration flow
      if (widget.isFromRegistration && widget.registrationData != null) {
        if (hasExtractedData) {
          _validateDataMatch();
        } else {
          // If no data was extracted, validation fails
          setState(() {
            _isDataMatching = false;
            _mismatchReason = "Could not extract enough information from ID. Please upload a clearer image.";
          });
        }
      } else {
        // If not in registration flow, success depends on having extracted data
        setState(() {
          _isDataMatching = hasExtractedData;
          if (!hasExtractedData) {
            _mismatchReason = "Could not extract information from ID. Please upload a clearer image.";
          }
        });
      }
      
      // Update UI
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error in OCR extraction: $e');
      
      // Show error but continue with empty data
      setState(() {
        isLoading = false;
        _mismatchReason = "Error extracting data from ID: $e";
        _isDataMatching = false;
      });
    }
  }

  // Validate if the uploaded ID matches the selected ID type
  void _validateIDType(String extractedText) {
    final upperCaseText = extractedText.toUpperCase();
      // Detect ID type based on extracted text
    final bool isDriversLicense = upperCaseText.contains('DRIVER') && 
                                 (upperCaseText.contains('LICENSE') || 
                                  upperCaseText.contains('LICENCE')) ||
                                 upperCaseText.contains('TRANSPORTATION') ||
                                 upperCaseText.contains('DRIVING');
    final bool isPhilID = upperCaseText.contains('PAMBANSANG') || 
                         upperCaseText.contains('PHILSYS') ||
                         upperCaseText.contains('PHILIPPINE IDENTIFICATION') ||
                         upperCaseText.contains('PAGKAKAKILANLAN');
    
    String detectedIDType = 'Unknown';
    if (isDriversLicense) {
      detectedIDType = 'Driver\'s License';
    } else if (isPhilID) {
      detectedIDType = 'Philippine Identification Card';
    }
    
    // Check if detected ID type matches selected ID type
    if (detectedIDType != 'Unknown') {
      if (widget.idType == 'Driver\'s License' && !isDriversLicense) {
        setState(() {
          _isCorrectIDType = false;
          _mismatchReason = "You selected Driver's License but uploaded a different ID type. Please upload the correct ID.";
        });
      } else if (widget.idType == 'Philippine Identification Card' && !isPhilID) {
        setState(() {
          _isCorrectIDType = false;
          _mismatchReason = "You selected Philippine Identification Card but uploaded a different ID type. Please upload the correct ID.";
        });
      }
    }
  }
  // Process image with Vision API
  Future<String> _processImageWithVisionAPI(File image) async {
    try {
      // Convert image to base64
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Call Vision API
      final response = await http.post(
        Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$_visionApiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'requests': [
            {
              'image': {
                'content': base64Image
              },
              'features': [
                {'type': 'TEXT_DETECTION', 'maxResults': 1},
                {'type': 'DOCUMENT_TEXT_DETECTION', 'maxResults': 1}
              ]
            }
          ]
        })
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        // Try to get full text from document text detection first (better for structured documents)
        String extractedText = '';
        
        if (jsonResponse['responses'][0].containsKey('fullTextAnnotation')) {
          extractedText = jsonResponse['responses'][0]['fullTextAnnotation']['text'] ?? '';
        } 
        // Fallback to regular text detection if document detection failed
        else if (jsonResponse['responses'][0].containsKey('textAnnotations') && 
                 jsonResponse['responses'][0]['textAnnotations'].isNotEmpty) {
          extractedText = jsonResponse['responses'][0]['textAnnotations'][0]['description'] ?? '';
        }
        
        print('--- EXTRACTED TEXT FROM ID ---');
        print(extractedText);
        print('-----------------------------');
        
        return extractedText;
      } else {
        print('Error calling Google Vision API: ${response.statusCode}, ${response.body}');
        throw Exception('Failed to extract text from image');
      }
    } catch (e) {
      print('Exception in _processImageWithVisionAPI: $e');
      throw e;
    }
  }
  // Extract data from driver's license using regex patterns
  void _extractDriversLicenseData(String text) {
    // Convert text to uppercase for consistent matching
    final upperCaseText = text.toUpperCase();
    
    // Look for the format: "LAST NAME, FIRST NAME MIDDLE NAME" followed by a specific name on the next line
    // This pattern captures Philippine driver's license format with a line specifically for the name
    final nameLineRegex = RegExp(r'LAST NAME,\s+FIRST NAME,\s+MIDDLE NAME\s*\n(.*?)(?:\n|NATIONALITY|DATE|SEX|BIRTH|ADDRESS)', dotAll: true, caseSensitive: false);
    final nameLineMatch = nameLineRegex.firstMatch(upperCaseText);
    
    if (nameLineMatch != null) {
      final fullName = nameLineMatch.group(1)?.trim() ?? '';
      
      // Philippine driver's license format: "LASTNAME, FIRSTNAME MIDDLENAME"
      final commaNameFormat = RegExp(r'([A-Z\s]+),\s*([A-Z\s]+)\s+([A-Z\s]+)');
      final commaMatch = commaNameFormat.firstMatch(fullName);
      
      if (commaMatch != null) {
        // Format "LASTNAME, FIRSTNAME MIDDLENAME"
        extractedData['lastName'] = _toTitleCase(commaMatch.group(1)?.trim() ?? '');
        extractedData['firstName'] = _toTitleCase(commaMatch.group(2)?.trim() ?? '');
        extractedData['middleName'] = _toTitleCase(commaMatch.group(3)?.trim() ?? '');
      } else {
        // Try alternative comma format with just two parts (LASTNAME, FIRSTNAME)
        final simpleCommaFormat = RegExp(r'([A-Z\s]+),\s*([A-Z\s]+)');
        final simpleCommaMatch = simpleCommaFormat.firstMatch(fullName);
        
        if (simpleCommaMatch != null) {
          extractedData['lastName'] = _toTitleCase(simpleCommaMatch.group(1)?.trim() ?? '');
          extractedData['firstName'] = _toTitleCase(simpleCommaMatch.group(2)?.trim() ?? '');
          extractedData['middleName'] = '';
        } else {
          // Try alternative format with spaces only
          final nameParts = fullName.split(' ').where((part) => part.isNotEmpty).toList();
          
          if (nameParts.length >= 2) {
            extractedData['lastName'] = _toTitleCase(nameParts.first);
            extractedData['firstName'] = _toTitleCase(nameParts[1]);
            
            // If there are more than 2 parts, the rest are middle names
            if (nameParts.length > 2) {
              extractedData['middleName'] = _toTitleCase(nameParts.sublist(2).join(' '));
            }
          }
        }
      }
    }
      // If the specific pattern didn't match, try a more generic approach
    if (extractedData['firstName']?.isEmpty == true && extractedData['lastName']?.isEmpty == true) {
      // Look for the specific pattern in Philippine driver's license (e.g., "FORMILLEZA, EDRIAN JUNTURA")
      final lines = upperCaseText.split('\n');
      for (int i = 0; i < lines.length; i++) {
        // First try to find the line with "LAST NAME, FIRST NAME, MIDDLE NAME" header
        if (lines[i].contains("LAST NAME") && 
            lines[i].contains("FIRST NAME") && 
            lines[i].contains("MIDDLE NAME") && 
            i + 1 < lines.length) {
          
          final nameLine = lines[i + 1].trim();
          if (nameLine.contains(',')) {
            final nameParts = nameLine.split(',');
            if (nameParts.length >= 2) {
              extractedData['lastName'] = _toTitleCase(nameParts[0].trim());
              
              // Modified: Use similar approach as PhilID to handle multi-word first and middle names
              // Get everything after the comma
              final remainingName = nameParts[1].trim();
              
              // Try to find where the middle name starts by searching for common middle name patterns
              // For Philippine names, middle names often appear after 2-3 words for the first name
              final words = remainingName.split(' ').where((w) => w.isNotEmpty).toList();
              
              if (words.length >= 3) {
                // Assume first 2 words are first name, rest are middle name (common pattern)
                extractedData['firstName'] = _toTitleCase(words.sublist(0, 2).join(' ').trim());
                extractedData['middleName'] = _toTitleCase(words.sublist(2).join(' ').trim());
              } else if (words.length == 2) {
                // If only 2 words, assume first word is first name, second is middle name
                extractedData['firstName'] = _toTitleCase(words[0].trim());
                extractedData['middleName'] = _toTitleCase(words[1].trim());
              } else if (words.length == 1) {
                // If only one word, it's the first name with no middle name
                extractedData['firstName'] = _toTitleCase(words[0].trim());
                extractedData['middleName'] = '';
              }
            }
          }
          break;
        }
      }
      
      // If still no match, look for comma-separated name directly (e.g., "TANEO, DON ANDREI FLORES")
      if (extractedData['firstName']?.isEmpty == true && extractedData['lastName']?.isEmpty == true) {
        for (String line in lines) {
          if (line.contains(',') && !line.contains("LAST NAME") && !line.contains("EXPIRATION")) {
            final nameParts = line.split(',');
            if (nameParts.length >= 2) {
              extractedData['lastName'] = _toTitleCase(nameParts[0].trim());
              
              // Modified: Use similar approach as above to handle multi-word first and middle names
              // Get everything after the comma - this contains both first and middle name
              final remainingName = nameParts[1].trim();
              final words = remainingName.split(' ').where((w) => w.isNotEmpty).toList();
              
              // For Philippine driver's licenses like "TANEO, DON ANDREI FLORES"
              // Try to intelligently separate first name and middle name based on common patterns
              if (words.length >= 3) {
                // If >= 3 words, assume first 2 are first name (e.g., "DON ANDREI") and rest are middle name
                extractedData['firstName'] = _toTitleCase(words.sublist(0, 2).join(' ').trim());
                extractedData['middleName'] = _toTitleCase(words.sublist(2).join(' ').trim());
              } else if (words.length == 2) {
                // If 2 words, assume first is first name, second is middle name
                extractedData['firstName'] = _toTitleCase(words[0].trim());
                extractedData['middleName'] = _toTitleCase(words[1].trim());
              } else if (words.length == 1) {
                // If only one word, it's the first name
                extractedData['firstName'] = _toTitleCase(words[0].trim());
                extractedData['middleName'] = '';
              }
              
              // If this looks like a name (contains no numbers or special markers), break
              if (extractedData['lastName']!.isNotEmpty && 
                  !extractedData['lastName']!.contains(RegExp(r'[0-9/\-]'))) {
                break;
              }
            }
          }
        }
      }
    }
      // Extract date of birth with improved pattern for Philippine license
    // Look for the date that appears after "DATE OF BIRTH" or near "WEIGHT" and "HEIGHT"
    final dobRegex = RegExp(r'DATE\s+OF\s+BIRTH(?:\s+WEIGHT\s+\(KG\)\s+HEIGHT\s+\(M\))?\s*\n?([\d/\-\.]+)', caseSensitive: false);
    final dobMatch = dobRegex.firstMatch(upperCaseText);
    
    if (dobMatch != null) {
      final dobString = dobMatch.group(1)?.trim() ?? '';
      
      try {
        // Try YYYY/MM/DD format (common in PH driver's license)
        extractedData['dateOfBirth'] = DateFormat('yyyy/MM/dd').parse(dobString);
      } catch (e) {
        try {
          // Try other formats if the main one fails
          extractedData['dateOfBirth'] = DateFormat('MM/dd/yyyy').parse(dobString.replaceAll('-', '/'));
        } catch (e) {
          print('Failed to parse date: $dobString');
        }
      }
    }
    
    // If DOB is still null, try to find it in a more generic way by scanning all lines
    if (extractedData['dateOfBirth'] == null) {
      final lines = upperCaseText.split('\n');
      for (String line in lines) {
        // Check for lines that contain only a date pattern (YYYY/MM/DD)
        if (RegExp(r'^\d{4}/\d{2}/\d{2}$').hasMatch(line.trim())) {
          try {
            extractedData['dateOfBirth'] = DateFormat('yyyy/MM/dd').parse(line.trim());
            break;
          } catch (e) {
            print('Failed to parse date: $line');
          }
        }
      }
    }
    
    // Extract expiration date - common formats include "Expiration Date: YYYY/MM/DD" or "EXPIRATION DATE YYYY-MM-DD"
    final expirationRegex = RegExp(r'(?:EXPIRATION DATE|EXPIRY|VALID UNTIL)[\s:]*(\d{4}[/\-\.]\d{1,2}[/\-\.]\d{1,2}|\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{4})', caseSensitive: false);
    final expirationMatch = expirationRegex.firstMatch(upperCaseText);
    
    if (expirationMatch != null) {
      final expirationString = expirationMatch.group(1)?.trim() ?? '';
      
      try {
        // Try to parse in common formats (YYYY/MM/DD, DD/MM/YYYY, etc.)
        DateTime? expirationDate;
        
        if (RegExp(r'^\d{4}[/\-\.]\d{1,2}[/\-\.]\d{1,2}$').hasMatch(expirationString)) {
          expirationDate = DateFormat('yyyy/MM/dd').parse(expirationString.replaceAll('-', '/').replaceAll('.', '/'));
        } else if (RegExp(r'^\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{4}$').hasMatch(expirationString)) {
          expirationDate = DateFormat('dd/MM/yyyy').parse(expirationString.replaceAll('-', '/').replaceAll('.', '/'));
        }
        
        if (expirationDate != null) {
          extractedData['expirationDate'] = expirationDate;
          
          // Check if the license is expired
          final now = DateTime.now();
          if (expirationDate.isBefore(now)) {
            _isExpired = true;
            _mismatchReason = "This driver's license has expired. Please provide a valid, unexpired ID.";
            _isDataMatching = false;
          }
        }
      } catch (e) {
        print('Failed to parse expiration date: $expirationString - $e');
      }
    }
    
    // If we still haven't found the expiration date, try alternative patterns
    if (extractedData['expirationDate'] == null) {
      // Look for standalone dates that appear after "EXPIRATION"
      final lines = upperCaseText.split('\n');
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains('EXPIRATION') || lines[i].contains('EXPIRY') || lines[i].contains('VALID UNTIL')) {
          // Check this line and the next line for date patterns
          final linesToCheck = [lines[i]];
          if (i + 1 < lines.length) {
            linesToCheck.add(lines[i + 1]);
          }
          
          for (final lineToCheck in linesToCheck) {
            // Look for common date patterns (YYYY/MM/DD or YYYY-MM-DD)
            final datePattern = RegExp(r'(\d{4}[/\-\.]\d{1,2}[/\-\.]\d{1,2}|\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{4})');
            final match = datePattern.firstMatch(lineToCheck);
            
            if (match != null) {
              final dateStr = match.group(1)!;
              try {
                DateTime? expirationDate;
                
                if (RegExp(r'^\d{4}[/\-\.]\d{1,2}[/\-\.]\d{1,2}$').hasMatch(dateStr)) {
                  expirationDate = DateFormat('yyyy/MM/dd').parse(dateStr.replaceAll('-', '/').replaceAll('.', '/'));
                } else if (RegExp(r'^\d{1,2}[/\-\.]\d{1,2}[/\-\.]\d{4}$').hasMatch(dateStr)) {
                  expirationDate = DateFormat('dd/MM/yyyy').parse(dateStr.replaceAll('-', '/').replaceAll('.', '/'));
                }
                
                if (expirationDate != null) {
                  extractedData['expirationDate'] = expirationDate;
                  
                  // Check if the license is expired
                  final now = DateTime.now();
                  if (expirationDate.isBefore(now)) {
                    _isExpired = true;
                    _mismatchReason = "This driver's license has expired. Please provide a valid, unexpired ID.";
                    _isDataMatching = false;
                  }
                  break; // We found and parsed a date, we can stop searching
                }
              } catch (e) {
                print('Failed to parse alternative expiration date: $dateStr - $e');
              }
            }
          }
          
          // If we found the expiration date, we can break the loop
          if (extractedData['expirationDate'] != null) {
            break;
          }
        }
      }
    }
    
    // Extract License No. (Philippines format: Dxx-xx-xxxxx or similar)
    final licenseNoRegex = RegExp(r'LICENSE\s*NO\.?\s*[:\-]?\s*([A-Z0-9\-]+)', caseSensitive: false);
    final licenseNoMatch = licenseNoRegex.firstMatch(upperCaseText);
    if (licenseNoMatch != null) {
      extractedData['licenseNo'] = licenseNoMatch.group(1)?.trim() ?? '';
    } else {
      // Try to find a line that looks like a license number (e.g., D37-24-001894)
      final lines = upperCaseText.split('\n');
      for (final line in lines) {
        if (RegExp(r'^D\d{2,3}[-]?\d{2}[-]?\d{5,}$').hasMatch(line.trim())) {
          extractedData['licenseNo'] = line.trim();
          break;
        }
      }
    }

    // Extract Address - specific to Philippines driver's license format
    String extractedAddress = '';

    // Direct pattern matching for the exact address format
    final exactAddressPattern = RegExp(
      r'(?:ADDRESS\s*[:]*\s*)?(?:LOT\s+\d+,?\s*BLOCK\s+\d+[A-Za-z]*,?\s*PHASE\s+\d+[A-ZaZ]*,?\s*[A-Za-z]+\s+ST\.,?\s*[A-ZaZ]+,?\s*VILL\.,?\s*[A-Za-z]+\s+[IVX]+,?\s*CITY\s+OF\s+[A-Za-z\sÑñ]+,?\s*[A-Za-z]+,?\s*\d{4})',
      caseSensitive: false
    );
    
    final addressMatch = exactAddressPattern.firstMatch(upperCaseText);
    if (addressMatch != null) {
      extractedAddress = addressMatch.group(0)?.replaceAll('ADDRESS', '').trim() ?? '';
    }

    // If exact pattern didn't match, try line-by-line approach
    if (extractedAddress.isEmpty) {
      final lines = upperCaseText.split('\n');
      for (String line in lines) {
        if (line.contains('LOT') && 
            line.contains('BLOCK') && 
            line.contains('PHASE') && 
            line.contains('ST.') && 
            line.contains('VILL.')) {
          extractedAddress = line.trim();
          
          // Get the next line if it contains city and zip code
          final lineIndex = lines.indexOf(line);
          if (lineIndex < lines.length - 1) {
            final nextLine = lines[lineIndex + 1].trim();
            if (nextLine.contains('CITY OF') || RegExp(r'\d{4}$').hasMatch(nextLine)) {
              extractedAddress += ', ' + nextLine;
            }
          }
          break;
        }
      }
    }

    // Clean up the address
    if (extractedAddress.isNotEmpty) {
      // Remove any potential header text
      extractedAddress = extractedAddress
        .replaceAll(RegExp(r'ADDRESS\s*:?\s*', caseSensitive: false), '')
        .replaceAll(RegExp(r'PRESENT\s+ADDRESS\s*:?\s*', caseSensitive: false), '')
        .trim();

      // Format the address properly
      final addressParts = extractedAddress
        .split(',')
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();

      extractedAddress = addressParts.join(', ');
    }

    extractedData['address'] = _toTitleCase(extractedAddress);
    
    // Clean up any double commas in address
    if (extractedData['address']?.isNotEmpty == true) {
      extractedData['address'] = extractedData['address']!.replaceAll(RegExp(r',\s*,'), ',');
    }

    // ...existing code...
  }
  
  // Extract data from national ID
  void _extractNationalIDData(String text) {
    // Convert text to uppercase for consistent matching
    final upperCaseText = text.toUpperCase();
    print('--- PROCESSING PHILIPPINE IDENTIFICATION CARD TEXT ---');
    print(upperCaseText);
    print('----------------------------------');

    // Extract last name - Appears after "Apelyido / Last Name" label
    final lastNameRegex = RegExp(r'(?:APELYIDO|LAST NAME)[^A-Z0-9]*([A-Z\s]+)', dotAll: true, caseSensitive: false);
    final lastNameMatch = lastNameRegex.firstMatch(upperCaseText);
    if (lastNameMatch != null) {
      String lastName = lastNameMatch.group(1)?.trim() ?? '';
      // Remove any label text that might have been included
      lastName = lastName.replaceAll(RegExp(r'LAST NAME', caseSensitive: false), '')
                         .replaceAll(RegExp(r'APELYIDO', caseSensitive: false), '')
                         .replaceAll(RegExp(r'MGA PANGALAN', caseSensitive: false), '')
                         .replaceAll(RegExp(r'GIVEN NAMES', caseSensitive: false), '')
                         .replaceAll(RegExp(r'MIDDLE NAME', caseSensitive: false), '')
                         .replaceAll(RegExp(r'GITNANG APELYIDO', caseSensitive: false), '')
                         .replaceAll(RegExp(r'/'), '')
                         .trim();
      // Remove any trailing label fragments
      lastName = lastName.replaceAll(RegExp(r'\b(MGA PANGALAN|GIVEN NAMES|MIDDLE NAME|GITNANG APELYIDO)\b', caseSensitive: false), '').trim();
      extractedData['lastName'] = _toTitleCase(lastName);
    }
      // Extract first name - Appears after "Mga Pangalan / Given Names" label
    final firstNameRegex = RegExp(r'(?:MGA PANGALAN|GIVEN NAMES)[:\s/]+([A-Z\s]+)(?=\n|GITNA|MIDDLE)', dotAll: true, caseSensitive: false);
    final firstNameMatch = firstNameRegex.firstMatch(upperCaseText);
    
    if (firstNameMatch != null) {
      final fullGivenNames = firstNameMatch.group(1)?.trim() ?? '';
      
      // Clean up any label text that might have been included
      final cleanedNames = fullGivenNames
          .replaceAll(RegExp(r'GIVEN NAMES:?\s*', caseSensitive: false), '')
          .trim();
      
      // If given names contain multiple words, first one is usually first name, rest are additional given names
      final givenNameParts = cleanedNames.split(' ');
      
      if (givenNameParts.isNotEmpty) {
        extractedData['firstName'] = _toTitleCase(givenNameParts[0]);
        
        // If there are additional given names, add them to first name with space
        if (givenNameParts.length > 1) {
          extractedData['firstName'] = _toTitleCase(givenNameParts.join(' '));
        }
      }
    }
      // Extract middle name - Appears after "Gitnang Apelyido / Middle Name" label
    final middleNameRegex = RegExp(r'(?:GITNANG APELYIDO|MIDDLE NAME)[:\s/]+([A-Z\s]+)(?=\n|PETSA|DATE)', dotAll: true, caseSensitive: false);
    final middleNameMatch = middleNameRegex.firstMatch(upperCaseText);
    
    if (middleNameMatch != null) {
      String middleName = middleNameMatch.group(1)?.trim() ?? '';
      
      // Clean up any label text that might have been included
      middleName = middleName
          .replaceAll(RegExp(r'MIDDLE NAME:?\s*', caseSensitive: false), '')
          .trim();
          
      extractedData['middleName'] = _toTitleCase(middleName);
    }
    
    // Extract date of birth - Appears after "Petsa ng Kapanganakan / Date of Birth" label
    // National ID can have various date formats, need to handle multiple patterns
    final dobRegex = RegExp(r'(?:PETSA NG KAPANGANAKAN|DATE OF BIRTH)[:\s/]+([A-Z0-9\s,.]+)(?=\n|TIRAHAN|ADDRESS)', dotAll: true, caseSensitive: false);
    final dobMatch = dobRegex.firstMatch(upperCaseText);
    
    if (dobMatch != null) {
      final dobString = dobMatch.group(1)?.trim() ?? '';
      
      // Try various date formats
      try {
        // Pre-process the date string to handle common OCR issues
        String processedDobString = dobString;
        
        // Fix missing spaces/comma between day and year (e.g., "AUGUST 022004" -> "AUGUST 02, 2004") 
        final monthDayYearPattern = RegExp(r'([A-Z]+)\s+(\d{1,2})(\d{4})', caseSensitive: false);
        final missingSpaceMatch = monthDayYearPattern.firstMatch(processedDobString);
        
        if (missingSpaceMatch != null) {
          final month = missingSpaceMatch.group(1);
          final day = missingSpaceMatch.group(2);
          final year = missingSpaceMatch.group(3);
          processedDobString = '$month $day, $year';
          print('Reformatted date string: $processedDobString');
        }
        
        // For text date format like "AUGUST 02, 2004"
        final textDatePattern = RegExp(r'([A-Z]+)\s+(\d{1,2})[\s,]+(\d{4})', caseSensitive: false);
        final textMatch = textDatePattern.firstMatch(processedDobString);
        
        if (textMatch != null) {
          final monthName = textMatch.group(1)?.toUpperCase() ?? '';
          int month = 1;
          
          // Convert month name to number
          Map<String, int> months = {
            'JANUARY': 1, 'JAN': 1,
            'FEBRUARY': 2, 'FEB': 2,
            'MARCH': 3, 'MAR': 3,
            'APRIL': 4, 'APR': 4,
            'MAY': 5,
            'JUNE': 6, 'JUN': 6,
            'JULY': 7, 'JUL': 7,
            'AUGUST': 8, 'AUG': 8,
            'SEPTEMBER': 9, 'SEP': 9, 'SEPT': 9,
            'OCTOBER': 10, 'OCT': 10,
            'NOVEMBER': 11, 'NOV': 11,
            'DECEMBER': 12, 'DEC': 12,
          };
          
          if (months.containsKey(monthName)) {
            month = months[monthName]!;
          }
          
          final day = int.tryParse(textMatch.group(2) ?? '') ?? 1;
          final year = int.tryParse(textMatch.group(3) ?? '') ?? 2000;
          
          extractedData['dateOfBirth'] = DateTime(year, month, day);
          print('Successfully parsed date: ${extractedData['dateOfBirth']}');
        } else {
          // Try other common formats
          try {
            extractedData['dateOfBirth'] = DateFormat('MM/dd/yyyy').parse(processedDobString);
          } catch (e) {
            try {
              extractedData['dateOfBirth'] = DateFormat('dd/MM/yyyy').parse(processedDobString);
            } catch (e) {
              try {
                extractedData['dateOfBirth'] = DateFormat('yyyy-MM-dd').parse(processedDobString);
              } catch (e) {
                print('Failed to parse date: $processedDobString');
                
                // Last attempt: Try to handle other common formats like "AUGUST022004"
                final directMonthDayYearPattern = RegExp(r'([A-Z]+)(\d{2})(\d{4})', caseSensitive: false);
                final directMatch = directMonthDayYearPattern.firstMatch(dobString);
                
                if (directMatch != null) {
                  final monthName = directMatch.group(1)?.toUpperCase() ?? '';
                  int month = 1;
                  
                  // Convert month name to number
                  Map<String, int> months = {
                    'JANUARY': 1, 'JAN': 1, 'FEBRUARY': 2, 'FEB': 2, 'MARCH': 3, 'MAR': 3,
                    'APRIL': 4, 'APR': 4, 'MAY': 5, 'JUNE': 6, 'JUN': 6, 'JULY': 7, 'JUL': 7,
                    'AUGUST': 8, 'AUG': 8, 'SEPTEMBER': 9, 'SEP': 9, 'SEPT': 9,
                    'OCTOBER': 10, 'OCT': 10, 'NOVEMBER': 11, 'NOV': 11, 'DECEMBER': 12, 'DEC': 12,
                  };
                  
                  if (months.containsKey(monthName)) {
                    month = months[monthName]!;
                  }
                  
                  final day = int.tryParse(directMatch.group(2) ?? '') ?? 1;
                  final year = int.tryParse(directMatch.group(3) ?? '') ?? 2000;
                  
                  extractedData['dateOfBirth'] = DateTime(year, month, day);
                  print('Successfully parsed direct date format: ${extractedData['dateOfBirth']}');
                }
              }
            }
          }
        }
      } catch (e) {
        print('Failed to parse date: $dobString - $e');
      }
    }
    
    // Set default values to empty string if data wasn't extracted
    extractedData['firstName'] = extractedData['firstName'] ?? '';
    extractedData['middleName'] = extractedData['middleName'] ?? '';
    extractedData['lastName'] = extractedData['lastName'] ?? '';
    
    // If we failed to extract data through specific fields, try a more generic approach
    if (extractedData['firstName']?.isEmpty == true && extractedData['lastName']?.isEmpty == true) {
      
      // If a line contains "DELGADO" or similar format, it might be the last name
      final lines = upperCaseText.split('\n');
      
      for (String line in lines) {
        // Skip lines that contain common labels or are too short
        if (line.contains('REPUBLIKA') || line.contains('PHILIPPINE') || 
            line.contains('PAMBAN') || line.length < 3) {
          continue;
        }
        
        // Look for capitalized words that might be names
        if (RegExp(r'^[A-Z\s]+$').hasMatch(line.trim())) {
          final parts = line.trim().split(' ');
          
          // If this looks like just one word, treat as last name
          if (parts.length == 1 && extractedData['lastName']?.isEmpty == true) {
            extractedData['lastName'] = _toTitleCase(parts[0]);
          } 
          // If 2+ words and first name is empty, might be given names
          else if (parts.length >= 2 && extractedData['firstName']?.isEmpty == true) {
            extractedData['firstName'] = _toTitleCase(parts.join(' '));
          }
        }
      }
    }
      // Extract PhilID Number - typically in format like "8928-3948-0460-5732"
    final philIDRegex = RegExp(r'(\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4})', caseSensitive: false);
    final philIDMatch = philIDRegex.firstMatch(upperCaseText);
    
    if (philIDMatch != null) {
      String idNumber = philIDMatch.group(1)?.trim() ?? '';
      // Format to ensure consistent format with dashes
      idNumber = idNumber.replaceAll(RegExp(r'\s'), '-'); // Replace spaces with dashes
      if (!idNumber.contains('-')) {
        // Add dashes if they don't exist
        idNumber = idNumber.replaceAllMapped(
          RegExp(r'(\d{4})(\d{4})(\d{4})(\d{4})'), 
          (match) => '${match[1]}-${match[2]}-${match[3]}-${match[4]}'
        );
      }
      extractedData['philIDNumber'] = idNumber;
    }
    
    // Extract Address - improved logic to get the correct address line(s)
    String extractedAddress = '';
    final lines = upperCaseText.split('\n');
    for (int i = 0; i < lines.length; i++) {
      if (lines[i].contains('TIRAHAN') || lines[i].contains('ADDRESS')) {
        // Try to get the next non-empty line(s) after the label
        int j = i + 1;
        while (j < lines.length && (lines[j].trim().isEmpty || lines[j].contains('REPUBLIC OF THE PHILIPPINES'))) {
          j++;
        }
        if (j < lines.length) {
          extractedAddress = lines[j].trim();
          // Optionally, concatenate the next line if it looks like part of the address
          if (j + 1 < lines.length &&
              RegExp(r'PHILIPPINES|CITY|CAVITE|MANILA|PROVINCE|4103|[0-9]').hasMatch(lines[j + 1])) {
            // Check if the current address already ends with a comma before adding another
            if (extractedAddress.endsWith(',')) {
              extractedAddress += ' ' + lines[j + 1].trim();
            } else {
              extractedAddress += ', ' + lines[j + 1].trim();
            }
          }
        }
        break;
      }
    }
    // Remove any header text if present
    if (extractedAddress.contains('REPUBLIC OF THE PHILIPPINES')) {
      extractedAddress = '';
    }
    
    // Clean up any double commas that might still be present
    extractedAddress = extractedAddress.replaceAll(',,', ',');
    
    extractedData['address'] = _toTitleCase(extractedAddress);
    
    // If we didn't find the address with the label, look for typical address patterns
    if (extractedData['address']?.isEmpty == true) {
      final lines = upperCaseText.split('\n');
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].contains('PH') && 
            lines[i].contains('RESIDENCE') || 
            lines[i].contains('CITY OF') || 
            lines[i].contains('PROVINCE') ||
            (lines[i].contains('B') && lines[i].contains('L') && lines[i].contains('PHILIPPINES'))) {
          
          extractedData['address'] = _toTitleCase(lines[i].trim());
          // Check if the address continues on the next line
          if (i+1 < lines.length && 
              (lines[i+1].contains('CAVITE') || 
               lines[i+1].contains('MANILA') || 
               lines[i+1].contains('CITY') || 
               lines[i+1].contains('PROVINCE'))) {
            // Check if current address ends with a comma
            if (extractedData['address']!.endsWith(',')) {
              extractedData['address'] += ' ' + _toTitleCase(lines[i+1].trim());
            } else {
              extractedData['address'] += ', ' + _toTitleCase(lines[i+1].trim());
            }
          }
          break;
        }
      }
    }
    
    // Final cleanup for any double commas that might still exist
    if (extractedData['address'] != null) {
      extractedData['address'] = extractedData['address']!.replaceAll(',,', ',');
    }
    
    print('Extracted data from Philippine Identification Card: $extractedData');
  }
  
  // Helper function to convert text to proper case
  String _toTitleCase(String text) {
    if (text.isEmpty) return '';
    
    return text.toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return '';
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }
  
  // Method to validate if extracted ID data matches registration data
  void _validateDataMatch() {
    if (widget.registrationData == null) {
      _isDataMatching = true; // No registration data to compare against
      return;
    }
    
    // Check if we have any extracted data first
    bool hasExtractedData = extractedData['firstName']?.isNotEmpty == true ||
                           extractedData['middleName']?.isNotEmpty == true ||
                           extractedData['lastName']?.isNotEmpty == true ||
                           extractedData['dateOfBirth'] != null;
                           
    if (!hasExtractedData) {
      setState(() {
        _isDataMatching = false;
        _mismatchReason = "Could not extract information from ID. Please upload a clearer image.";
      });
      return;
    }
    
    List<String> mismatches = [];
    
    // Check first name match if extracted
    if (extractedData['firstName']?.isNotEmpty == true &&
        extractedData['firstName'].toLowerCase() != widget.registrationData!['firstName'].toLowerCase()) {
      mismatches.add('First Name');
    }
    
    // Check middle name match if extracted
    if (extractedData['middleName']?.isNotEmpty == true &&
        extractedData['middleName'].toLowerCase() != widget.registrationData!['middleName'].toLowerCase()) {
      mismatches.add('Middle Name');
    }
    
    // Check last name match if extracted
    if (extractedData['lastName']?.isNotEmpty == true &&
        extractedData['lastName'].toLowerCase() != widget.registrationData!['lastName'].toLowerCase()) {
      mismatches.add('Last Name');
    }
    
    // Check date of birth match if extracted
    if (extractedData['dateOfBirth'] != null && widget.registrationData!['dateOfBirth'] != null) {
      DateTime idDOB = extractedData['dateOfBirth'];
      DateTime regDOB = widget.registrationData!['dateOfBirth'];
      if (idDOB.year != regDOB.year || idDOB.month != regDOB.month || idDOB.day != regDOB.day) {
        mismatches.add('Date of Birth');
      }
    }
    
    // If there are mismatches, set _isDataMatching to false and create mismatch reason
    setState(() {
      if (mismatches.isNotEmpty) {
        _isDataMatching = false;
        _mismatchReason = "The following information from your ID doesn't match your registration details: ${mismatches.join(', ')}.";
      } else {
        _isDataMatching = true;
        _mismatchReason = null;
      }
    });
  }

  Future<void> _submitVerification() async {
    setState(() {
      isSubmitting = true;
    });

    try {
      // Simulate API call delay
      await Future.delayed(Duration(seconds: 2));
      
      if (widget.isFromRegistration) {
        if (!_isDataMatching) {
          // Show error if data doesn't match
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ID verification failed: $_mismatchReason'),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            isSubmitting = false;
          });
          return;
        }
        
        // Register user with Firebase Auth
        await _registerUser();
      } else {
        // Handle existing user verification flow
        // Upload images to Firebase Storage and update verification status
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          // In a real implementation, update verification status in Firebase
          final AuthService authService = AuthService();
          await authService.updateIDVerificationStatus(
            uid: currentUser.uid,
            submitted: true,
            idType: widget.idType,
            uploadedIDImage: widget.idImage,
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
      }
      
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
  
  // Method to register user with Firebase and create Firestore document
  Future<void> _registerUser() async {
    try {
      final AuthService authService = AuthService();
      
      // Register user with email and password
      final email = widget.registrationData!['email'];
      final password = widget.registrationData!['password'];
      
      // Create user in Firebase Auth
      final UserCredential userCredential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
          // Add user to Firestore with additional profile information
      await authService.addUserToFirestore(
        userCredential.user!, 
        email,
        firstName: widget.registrationData!['firstName'],
        middleName: widget.registrationData!['middleName'],
        lastName: widget.registrationData!['lastName'],
        birthday: widget.registrationData!['dateOfBirth'],
        age: widget.registrationData!['age'],
        gender: widget.registrationData!['gender'],
        phoneNumber: widget.registrationData!['phoneNumber'],
        selectedIDType: widget.idType,
        uploadedIDImage: widget.idImage,
      );
      
      // Update ID verification status
      await authService.updateIDVerificationStatus(
        uid: userCredential.user!.uid,
        submitted: true,
        verified: true,
        idType: widget.idType,
        uploadedIDImage: widget.idImage,
      );
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate to home page
      Navigator.pushReplacementNamed(context, '/home');
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration error: $e'),
          backgroundColor: Colors.red,
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
              Color(0xFF2A5298),
              Color(0xFF4B89DC),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 24),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          spreadRadius: 2,
                          blurRadius: 18,
                          offset: Offset(0, 6),
                        ),
                      ],
                      border: Border.all(color: Color(0xFFE3E8F0), width: 1.2),
                    ),
                    child: isLoading
                        ? _buildLoadingState()
                        : !_isCorrectIDType || _isExpired
                            ? _buildIDTypeMismatchError()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Logo
                                  Image.asset(
                                    ImageConstant.logoFinal,
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.contain,
                                  ),
                                  SizedBox(height: 12),
                                  // Title
                                  Text(
                                    'CONFIRM ID INFORMATION',
                                    style: TextStyle(
                                      color: Color(0xFF424242),
                                      fontSize: 22,
                                      fontFamily: 'Inter',
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 6),
                                  // Description
                                  Text(
                                    widget.isFromRegistration
                                        ? 'Please verify that the information below matches your registration details.'
                                        : 'Please verify that the information below is correct before submitting.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  SizedBox(height: 18),
                                  // Validation status
                                  if (widget.isFromRegistration) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: _isDataMatching ? Color(0xFFEAF7EE) : Color(0xFFFDEAEA),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _isDataMatching ? Colors.green.shade300 : Colors.red.shade300,
                                        ),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            _isDataMatching ? Icons.check_circle : Icons.error_outline,
                                            color: _isDataMatching ? Colors.green : Colors.red,
                                          ),
                                          SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _isDataMatching ? 'ID Validation Successful' : 'ID Validation Failed',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: _isDataMatching ? Colors.green.shade700 : Colors.red.shade700,
                                                  ),
                                                ),
                                                if (!_isDataMatching && _mismatchReason != null)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 2.0),
                                                    child: Text(
                                                      _mismatchReason!,
                                                      style: TextStyle(
                                                        color: Colors.red.shade700,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                if (!_isDataMatching)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 6.0),
                                                    child: Text(
                                                      'Please go back and update your registration information to match your ID.',
                                                      style: TextStyle(
                                                        color: Colors.red.shade700,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 18),
                                  ],
                                  // ID Image
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: _buildInputLabel('ID Image'),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    height: 180,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        widget.idImage,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 22),
                                  // Info Section Header
                                  Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Color(0xFF53C0FF)),
                                      SizedBox(width: 8),
                                      Text(
                                        'ID INFORMATION',
                                        style: TextStyle(
                                          color: Color(0xFF424242),
                                          fontSize: 16,
                                          fontFamily: 'Inter',
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(color: Color(0xFF53C0FF), thickness: 1.2),
                                  SizedBox(height: 10),
                                  // Info fields
                                  _buildReadOnlyField('First Name', extractedData['firstName'], icon: Icons.person_outline),
                                  _buildReadOnlyField('Middle Name', extractedData['middleName'], icon: Icons.person_outline),
                                  _buildReadOnlyField('Last Name', extractedData['lastName'], icon: Icons.person_outline),
                                  _buildReadOnlyField(
                                    'Date of Birth',
                                    extractedData['dateOfBirth'] != null
                                        ? DateFormat('MM/dd/yyyy').format(extractedData['dateOfBirth'])
                                        : null,
                                    icon: Icons.cake_outlined,
                                  ),
                                  _buildReadOnlyField('Email', userEmail, icon: Icons.email_outlined),
                                  SizedBox(height: 24),
                                  // Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: isSubmitting ? null : () => Navigator.pop(context),
                                          style: OutlinedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(vertical: 18),
                                            side: BorderSide(color: Color(0xFFFF3B3B), width: 2),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                          ),
                                          child: Text(
                                            'CANCEL',
                                            style: TextStyle(
                                              color: Color(0xFFFF3B3B),
                                              fontSize: 15,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: (isSubmitting ||
                                                  (widget.isFromRegistration && !_isDataMatching) ||
                                                  (!_isDataMatching && !widget.isFromRegistration))
                                              ? null
                                              : _submitVerification,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFFFFD27E),
                                            foregroundColor: Color(0xFF424242),
                                            padding: EdgeInsets.symmetric(vertical: 18),
                                            elevation: 4,
                                            shadowColor: Color(0xFFFFD27E).withOpacity(0.4),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(14),
                                            ),
                                            disabledBackgroundColor: Colors.grey.shade400,
                                          ),
                                          child: isSubmitting
                                              ? Text(
                                                  'REGISTERING',
                                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                                                )
                                              : Text(
                                                  'REGISTER',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                    letterSpacing: 1.2,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                  overflow: TextOverflow.ellipsis,
                                                  maxLines: 1,
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
  
  // Loading state widget
  Widget _buildLoadingState() {
    return Column(
      children: [
        SizedBox(height: 20),
        Image.asset(
          ImageConstant.logoFinal,
          width: 100,
          height: 100,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 30),
        CircularProgressIndicator(color: Color(0xFF53C0FF)),
        SizedBox(height: 20),
        Text(
          'Extracting information from your ID...',
          style: TextStyle(
            color: Color(0xFF424242),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 20),
      ],
    );
  }

  // Error state widget for ID type mismatch
  Widget _buildIDTypeMismatchError() {
    return Column(
      children: [
        SizedBox(height: 20),
        Image.asset(
          ImageConstant.logoFinal,
          width: 100,
          height: 100,
          fit: BoxFit.contain,
        ),
        SizedBox(height: 30),
        Icon(
          Icons.error_outline,
          color: Colors.red,
          size: 60,
        ),
        SizedBox(height: 20),
        Text(
          'ID Type Mismatch',
          style: TextStyle(
            color: Colors.red.shade700,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            _mismatchReason ?? 'The ID you uploaded does not match the ID type you selected.',
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 30),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFFFD27E),
            foregroundColor: Color(0xFF424242),
            padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            'GO BACK',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }
  
  Widget _buildReadOnlyField(String label, String? value, {IconData? icon}) {
    String cleanValue = value ?? '';
    if (cleanValue.isNotEmpty) {
      cleanValue = cleanValue
          .replaceAll('Given Names:', '')
          .replaceAll('Given Names', '')
          .replaceAll('Middle Name:', '')
          .replaceAll('Middle Name', '')
          .replaceAll('Last Name:', '')
          .replaceAll('Last Name', '')
          .trim();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Color(0xFF53C0FF), size: 20),
            SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputLabel(label),
                SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    cleanValue.isEmpty ? 'Not found' : cleanValue,
                    style: TextStyle(
                      color: cleanValue.isEmpty ? Colors.grey : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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