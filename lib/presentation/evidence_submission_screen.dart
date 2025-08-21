import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';
import '/core/app_export.dart';

class EvidenceSubmissionScreen extends StatefulWidget {
  final String caseId;
  final String caseNumber;
  final String caseName;

  const EvidenceSubmissionScreen({
    Key? key,
    required this.caseId,
    required this.caseNumber,
    required this.caseName,
  }) : super(key: key);

  @override
  _EvidenceSubmissionScreenState createState() => _EvidenceSubmissionScreenState();
}

class _EvidenceSubmissionScreenState extends State<EvidenceSubmissionScreen> {
  final TextEditingController _missingPersonNameController = TextEditingController();
  final TextEditingController _statementController = TextEditingController();
  final List<File> _selectedImages = [];
  bool _isSubmitting = false;
  final ImagePicker _picker = ImagePicker();
  
  // Validation state variables for OCR
  ValidationStatus _validationStatus = ValidationStatus.none;
  String _validationMessage = '';
  String _validationConfidence = '0.0';
  final GlobalKey _validationSectionKey = GlobalKey();
  
  // Signature controller
  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 2,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );
  Uint8List? _signatureImage;

  @override
  void dispose() {
    _missingPersonNameController.dispose();
    _statementController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  // Generate a formal document ID format: EVD-YYYYMMDD-XXXX (where XXXX is sequential starting at 0001)
  Future<String> generateFormalDocumentId() async {
    final today = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(today);
    final idPrefix = 'EVD-$dateStr-';

    try {
      // Get all documents with today's date prefix by document ID in the CaseEvidence collection
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('CaseEvidence')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: idPrefix + '0001')
          .where(FieldPath.documentId, isLessThanOrEqualTo: idPrefix + '9999')
          .get();

      // Find the highest sequential number by checking doc.id
      int highestNumber = 0;
      for (final doc in querySnapshot.docs) {
        final String docId = doc.id;
        if (docId.startsWith(idPrefix) && docId.length > idPrefix.length) {
          final String seqPart = docId.substring(idPrefix.length);
          final int? seqNum = int.tryParse(seqPart);
          if (seqNum != null && seqNum > highestNumber) {
            highestNumber = seqNum;
          }
        }
      }
      // Increment for next document
      final int nextNumber = highestNumber + 1;
      final String paddedNumber = nextNumber.toString().padLeft(4, '0');
      final String newDocId = '$idPrefix$paddedNumber';
      return newDocId;
    } catch (e) {
      // Fallback ID using more reliable method - but ensure it's still sequential
      final String paddedNumber = '0001'; // Start with 0001 if there's an error
      final String fallbackId = '$idPrefix$paddedNumber';
      return fallbackId;
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? images = await _picker.pickMultiImage(
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (images != null && images.isNotEmpty) {
        // Show loading state while processing the images
        setState(() {
          _validationStatus = ValidationStatus.processing;
          _validationMessage = "Processing images...";
        });

        List<File> validImages = [];
        for (var image in images) {
          if (_selectedImages.length + validImages.length < 5) {
            final file = File(image.path);
            
            // Validate each image with OCR
            try {
              final TipService tipService = TipService();
              Map<String, dynamic> validationResult = await tipService.validateImageWithGoogleVision(file);
              
              if (validationResult['isValid'] && validationResult['containsHuman']) {
                validImages.add(file);
              } else if (!validationResult['containsHuman']) {
                _showErrorSnackBar('One or more images were rejected - no person detected');
              }
            } catch (e) {
              print('Error validating image: $e');
              _showErrorSnackBar('Error validating image: $e');
            }
          }
        }

        setState(() {
          _selectedImages.addAll(validImages);
          if (validImages.isNotEmpty) {
            _validationStatus = ValidationStatus.humanDetected;
            _validationMessage = '${validImages.length} valid image(s) added with person detection confirmed';
          } else {
            _validationStatus = ValidationStatus.noHuman;
            _validationMessage = 'No valid images with persons detected';
          }
        });
      }
    } catch (e) {
      setState(() {
        _validationStatus = ValidationStatus.error;
        _validationMessage = 'Error selecting images: $e';
      });
      _showErrorSnackBar('Error selecting images: $e');
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image != null && _selectedImages.length < 5) {
        // Show loading state while processing the image
        setState(() {
          _validationStatus = ValidationStatus.processing;
          _validationMessage = "Processing image...";
        });

        final file = File(image.path);
        
        // Validate the image with OCR
        try {
          final TipService tipService = TipService();
          Map<String, dynamic> validationResult = await tipService.validateImageWithGoogleVision(file);
          
          if (!validationResult['isValid']) {
            setState(() {
              _validationStatus = ValidationStatus.error;
              _validationMessage = 'Error validating image: ${validationResult['message']}';
            });
          } else if (!validationResult['containsHuman']) {
            setState(() {
              _validationStatus = ValidationStatus.noHuman;
              _validationMessage = 'No person detected in the image. Please take another photo.';
              _validationConfidence = (validationResult['confidence'] * 100).toStringAsFixed(1);
            });
            _showErrorSnackBar('Image rejected - no person detected');
          } else {
            setState(() {
              _selectedImages.add(file);
              _validationStatus = ValidationStatus.humanDetected;
              _validationMessage = 'Person detected in image!';
              _validationConfidence = (validationResult['confidence'] * 100).toStringAsFixed(1);
            });
          }
        } catch (e) {
          print('Error validating image: $e');
          setState(() {
            _validationStatus = ValidationStatus.warning;
            _validationMessage = 'Image validation error: ${e.toString()}';
          });
          // Still add the image if validation fails
          setState(() {
            _selectedImages.add(file);
          });
        }
      }
    } catch (e) {
      setState(() {
        _validationStatus = ValidationStatus.error;
        _validationMessage = 'Error taking photo: $e';
      });
      _showErrorSnackBar('Error taking photo: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      // Clear validation status if no images left
      if (_selectedImages.isEmpty) {
        _validationStatus = ValidationStatus.none;
        _validationMessage = '';
        _validationConfidence = '0.0';
      }
    });
  }

  Future<void> _clearSignature() async {
    _signatureController.clear();
    setState(() {
      _signatureImage = null;
    });
  }

  Future<void> _saveSignature() async {
    if (_signatureController.isEmpty) {
      _showErrorSnackBar('Please provide a signature first');
      return;
    }

    final Uint8List? signature = await _signatureController.toPngBytes();
    if (signature != null) {
      setState(() {
        _signatureImage = signature;
      });
      _showSuccessSnackBar('Signature saved successfully');
    }
  }

  Future<void> _submitEvidence() async {
    // Validation
    if (_missingPersonNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Missing person name is required');
      return;
    }
    
    if (_selectedImages.isEmpty) {
      _showErrorSnackBar('Photo evidence is required');
      return;
    }
    
    if (_statementController.text.trim().isEmpty) {
      _showErrorSnackBar('Statement of reunion is required');
      return;
    }
    
    if (_signatureImage == null) {
      _showErrorSnackBar('E-Signature is required');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      // Generate formal document ID with sequential numbering
      String formalId;
      DocumentReference docRef;
      int attempt = 0;
      do {
        formalId = await generateFormalDocumentId();
        docRef = FirebaseFirestore.instance.collection('CaseEvidence').doc(formalId);
        final docSnap = await docRef.get();
        if (!docSnap.exists) break;
        // If exists, increment the highest number and try again
        attempt++;
        // Artificially bump the date to force next number (for rare race conditions)
        if (attempt > 10) {
          throw Exception('Too many attempts to generate unique Evidence ID');
        }
        // Wait a bit to avoid race
        await Future.delayed(Duration(milliseconds: 50));
      } while (true);

      // Upload images to Firebase Storage - "caseEvidencePhotos" bucket
      List<String> imageUrls = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        final file = _selectedImages[i];
        final fileName = 'evidence_${formalId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('caseEvidencePhotos')
            .child(formalId)
            .child(fileName);

        final uploadTask = await storageRef.putFile(file);
        final downloadUrl = await uploadTask.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }

      // Upload signature to Firebase Storage - "caseEvidenceSignatures" bucket
      String signatureUrl = '';
      if (_signatureImage != null) {
        final signatureFileName = 'signature_${formalId}_${DateTime.now().millisecondsSinceEpoch}.png';
        final signatureRef = FirebaseStorage.instance
            .ref()
            .child('caseEvidenceSignatures')
            .child(formalId)
            .child(signatureFileName);

        final signatureUploadTask = await signatureRef.putData(_signatureImage!);
        signatureUrl = await signatureUploadTask.ref.getDownloadURL();
      }

      // Create evidence document with your specified field names
      final evidenceData = {
        'EvidenceimageUrl': imageUrls.isNotEmpty ? imageUrls.first : '', // First image URL as string
        'MissingPersonName': _missingPersonNameController.text.trim(),
        'Statement': _statementController.text.trim(),
        'alarm_id': widget.caseId, // Using caseId as alarm_id
        'createdAt': FieldValue.serverTimestamp(),
        'eSignature': signatureUrl,
        'status': 'Evidence Submitted',
        'userId': currentUser.uid,
      };

      // Add evidence to "CaseEvidence" collection with formal document ID
      await docRef.set(evidenceData);

      // Update case status to "Evidence Submitted"
      await _updateCaseStatus();

      _showSuccessDialog();
    } catch (e) {
      _showErrorSnackBar('Error submitting evidence: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _updateCaseStatus() async {
    try {
      // Check if case exists in incidents collection
      final incidentDoc = await FirebaseFirestore.instance
          .collection('incidents')
          .doc(widget.caseId)
          .get();

      if (incidentDoc.exists) {
        await incidentDoc.reference.update({'status': 'Evidence Submitted'});
        return;
      }

      // Check if case exists in missingPersons collection
      final missingPersonDoc = await FirebaseFirestore.instance
          .collection('missingPersons')
          .doc(widget.caseId)
          .get();

      if (missingPersonDoc.exists) {
        await missingPersonDoc.reference.update({'status': 'Evidence Submitted'});
        return;
      }

      throw Exception('Case not found in any collection');
    } catch (e) {
      print('Error updating case status: $e');
      // Don't throw here as evidence was submitted successfully
    }
  }

  void _showSuccessDialog() {
    // Show success snackbar instead of dialog
    _showSuccessSnackBar(
      'Evidence submitted successfully for case ${widget.caseNumber}. '
      'Case status updated to "Evidence Submitted".'
    );
    
    // Navigate back to the previous screen after a short delay
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // Build validation feedback UI section
  Widget _buildValidationFeedback() {
    if (_validationStatus == ValidationStatus.none) {
      return SizedBox.shrink();
    }
    
    return Container(
      key: _validationSectionKey,
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getValidationBorderColor(),
          width: 2,
        ),
        color: _getValidationBackgroundColor(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getValidationIcon(),
                color: _getValidationIconColor(),
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  _getValidationTitle(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _getValidationIconColor(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _validationMessage,
            style: TextStyle(fontSize: 14, color: Colors.black),
          ),
          if (_validationStatus == ValidationStatus.processing)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_getValidationIconColor()),
                ),
              ),
            ),
          if (_validationStatus == ValidationStatus.humanDetected && _validationConfidence.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                "Confidence score: $_validationConfidence%",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Helper methods for validation UI
  IconData _getValidationIcon() {
    switch (_validationStatus) {
      case ValidationStatus.processing:
        return Icons.hourglass_top;
      case ValidationStatus.error:
        return Icons.error_outline;
      case ValidationStatus.warning:
        return Icons.warning_amber;
      case ValidationStatus.noHuman:
        return Icons.person_off;
      case ValidationStatus.humanDetected:
        return Icons.person;
      case ValidationStatus.success:
        return Icons.check_circle_outline;
      default:
        return Icons.info_outline;
    }
  }

  Color _getValidationIconColor() {
    switch (_validationStatus) {
      case ValidationStatus.processing:
        return Colors.blue;
      case ValidationStatus.error:
        return Colors.red;
      case ValidationStatus.warning:
        return Colors.orange;
      case ValidationStatus.noHuman:
        return Colors.orange;
      case ValidationStatus.humanDetected:
        return Colors.green;
      case ValidationStatus.success:
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Color _getValidationBorderColor() {
    switch (_validationStatus) {
      case ValidationStatus.processing:
        return Colors.blue.shade300;
      case ValidationStatus.error:
        return Colors.red.shade300;
      case ValidationStatus.warning:
        return Colors.orange.shade300;
      case ValidationStatus.noHuman:
        return Colors.orange.shade300;
      case ValidationStatus.humanDetected:
        return Colors.green.shade300;
      case ValidationStatus.success:
        return Colors.green.shade300;
      default:
        return Colors.grey.shade300;
    }
  }

  Color _getValidationBackgroundColor() {
    switch (_validationStatus) {
      case ValidationStatus.processing:
        return Colors.blue.shade50;
      case ValidationStatus.error:
        return Colors.red.shade50;
      case ValidationStatus.warning:
        return Colors.orange.shade50;
      case ValidationStatus.noHuman:
        return Colors.orange.shade50;
      case ValidationStatus.humanDetected:
        return Colors.green.shade50;
      case ValidationStatus.success:
        return Colors.green.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  String _getValidationTitle() {
    switch (_validationStatus) {
      case ValidationStatus.processing:
        return "Processing...";
      case ValidationStatus.error:
        return "Error";
      case ValidationStatus.warning:
        return "Warning";
      case ValidationStatus.noHuman:
        return "No Person Detected";
      case ValidationStatus.humanDetected:
        return "Person Detected";
      case ValidationStatus.success:
        return "Success";
      default:
        return "Information";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Evidence Submission", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0D47A1),
              Color(0xFF1565C0),
              Color(0xFFE3F2FD),
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section with improved styling
                Container(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.assignment_turned_in,
                              size: 48,
                              color: Colors.white,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Reunion Evidence Submission',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Please provide all required evidence to verify reunification',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withOpacity(0.9),
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Missing Person Name Section with improved styling
                Container(
                  margin: EdgeInsets.only(bottom: 20),
                  child: Card(
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.grey.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFF0D47A1).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: Color(0xFF0D47A1),
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Missing Person Name',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' *',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.red.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _missingPersonNameController,
                                style: TextStyle(fontSize: 16, color: Colors.black),
                                decoration: InputDecoration(
                                  hintText: 'Enter missing person\'s full name',
                                  hintStyle: TextStyle(color: Colors.grey.shade500),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Color(0xFF0D47A1), width: 2),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Upload Photo Evidence Section with improved styling
                Container(
                  margin: EdgeInsets.only(bottom: 20),
                  child: Card(
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.grey.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.photo_camera,
                                    color: Colors.green.shade700,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Upload Photo Evidence',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' *',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.red.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),

                            // Enhanced image picker buttons
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.blue.withOpacity(0.3),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: _pickImages,
                                      icon: Icon(Icons.photo_library, size: 20),
                                      label: Text(
                                        'Gallery',
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue.shade600,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.3),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: _pickFromCamera,
                                      icon: Icon(Icons.camera_alt, size: 20),
                                      label: Text(
                                        'Camera',
                                        style: TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green.shade600,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),

                            // Add validation feedback here
                            _buildValidationFeedback(),

                            // Enhanced selected images grid
                            if (_selectedImages.isNotEmpty) ...[
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                                    SizedBox(width: 8),
                                    Text(
                                      'Selected Images (${_selectedImages.length}/5)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 12),
                              GridView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                                itemCount: _selectedImages.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          spreadRadius: 1,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(12),
                                            image: DecorationImage(
                                              image: FileImage(_selectedImages[index]),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () => _removeImage(index),
                                            child: Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade600,
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black.withOpacity(0.3),
                                                    spreadRadius: 1,
                                                    blurRadius: 2,
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Statement of Reunion Section with improved styling
                Container(
                  margin: EdgeInsets.only(bottom: 20),
                  child: Card(
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.grey.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.description,
                                    color: Colors.orange.shade700,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Statement of Reunion',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' *',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.red.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 1,
                                    blurRadius: 3,
                                    offset: Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _statementController,
                                maxLines: 6,
                                style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black),
                                decoration: InputDecoration(
                                  hintText: 'Describe the circumstances of the reunion...',
                                  hintStyle: TextStyle(color: Colors.grey.shade500),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Color(0xFF0D47A1), width: 2),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // E-Signature Section with improved styling
                Container(
                  margin: EdgeInsets.only(bottom: 32),
                  child: Card(
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [Colors.white, Colors.grey.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.draw,
                                    color: Colors.purple.shade700,
                                    size: 20,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'E-Signature',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        TextSpan(
                                          text: ' *',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.red.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            
                            // Enhanced signature pad or saved signature
                            if (_signatureImage == null) ...[
                              Container(
                                height: 200,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300, width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Signature(
                                    controller: _signatureController,
                                    backgroundColor: Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Sign above with your finger or stylus',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.red.withOpacity(0.2),
                                            spreadRadius: 1,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: OutlinedButton.icon(
                                        onPressed: _clearSignature,
                                        icon: Icon(Icons.clear, size: 18),
                                        label: Text(
                                          'Clear',
                                          style: TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red.shade600,
                                          side: BorderSide(color: Colors.red.shade600, width: 2),
                                          padding: EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          backgroundColor: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(0xFF0D47A1).withOpacity(0.3),
                                            spreadRadius: 1,
                                            blurRadius: 4,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton.icon(
                                        onPressed: _saveSignature,
                                        icon: Icon(Icons.save, size: 18),
                                        label: Text(
                                          'Save',
                                          style: TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF0D47A1),
                                          foregroundColor: Colors.white,
                                          padding: EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          elevation: 0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ] else ...[
                              Container(
                                height: 200,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.green.shade400, width: 3),
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.green.shade50,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.2),
                                      spreadRadius: 2,
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Stack(
                                    children: [
                                      Image.memory(
                                        _signatureImage!,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green.shade600,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.check, color: Colors.white, size: 16),
                                              SizedBox(width: 4),
                                              Text(
                                                'Saved',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF0D47A1).withOpacity(0.2),
                                        spreadRadius: 1,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _signatureImage = null;
                                      });
                                      _signatureController.clear();
                                    },
                                    icon: Icon(Icons.edit, color: Color(0xFF0D47A1), size: 18),
                                    label: Text(
                                      'Edit Signature',
                                      style: TextStyle(
                                        color: Color(0xFF0D47A1),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(color: Color(0xFF0D47A1), width: 2),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Enhanced Submit Button
                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF0D47A1).withOpacity(0.4),
                        spreadRadius: 2,
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitEvidence,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF0D47A1),
                      disabledBackgroundColor: Colors.grey.shade400,
                      padding: EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              ),
                              SizedBox(width: 16),
                              Text(
                                'Submitting Evidence...',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Submit Evidence',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
