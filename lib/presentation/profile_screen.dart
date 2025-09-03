import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/core/app_export.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'evidence_submission_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = 'Your Name';
  String _email = 'user@example.com';
  String _memberSince = 'Member since: Jan 2023';
  String _profileImageUrl = '';
  bool _isLoading = true;
  Map<String, dynamic>? _userData;
  bool _isVerified = false;
  String _verificationStatus = 'Not Verified';
  
  List<Map<String, dynamic>> _casesData = [];
  int _selectedCaseIndex = 0;
  
  // Stream subscriptions for real-time updates
  List<StreamSubscription<QuerySnapshot>> _streamSubscriptions = [];
    // Status progression steps
  final List<Map<String, String>> _caseProgressSteps = [
    {'stage': 'Reported', 'status': 'Pending'},
    {'stage': 'Under Review', 'status': 'Pending'},
    {'stage': 'Case Verified', 'status': 'Pending'},
    {'stage': 'In Progress', 'status': 'Pending'},
    {'stage': 'Evidence Submitted', 'status': 'Pending'},
    {'stage': 'Unresolved Case', 'status': 'Pending'},
    {'stage': 'Resolved Case', 'status': 'Pending'},
  ];
    // Map to convert status to step number (1-indexed)
  final Map<String, int> _statusToStep = {
    'Reported': 1,
    'Under Review': 2,
    'Case Verified': 3,
    'In Progress': 4,
    'Evidence Submitted': 5,
    'Unresolved Case': 6,
    'Resolved Case': 7,
    'Resolved': 7, // Map 'Resolved' to 'Resolved Case' step
  };

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _initializeCaseStreams();
  }

  @override
  void dispose() {
    // Cancel all stream subscriptions
    for (var subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // Query users collection by uid field
        final QuerySnapshot userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('userId', isEqualTo: currentUser.uid) // Changed from 'uid' to 'userId'
            .limit(1)
            .get();

        if (userQuery.docs.isNotEmpty) {
          final userDoc = userQuery.docs.first;
          final userData = userDoc.data() as Map<String, dynamic>;
          _userData = userData;
          
          // Format the creation date
          String formattedDate = 'Member since: Jan 2023';
          if (userData['createdAt'] != null) {
            Timestamp creationTimestamp = userData['createdAt'] as Timestamp;
            DateTime creationDate = creationTimestamp.toDate();
            formattedDate = 'Member since: ${DateFormat('MMM yyyy').format(creationDate)}';
          }
          
          setState(() {
            _name = userData['displayName'] ?? currentUser.displayName ?? 'Your Name';
            _email = userData['email'] ?? currentUser.email ?? 'user@example.com';
            _profileImageUrl = userData['photoURL'] ?? currentUser.photoURL ?? '';
            _memberSince = formattedDate;
            
            // Set verification status
            _isVerified = userData['isValidated'] == true;
            
            // Set verification status text
            if (_isVerified) {
              _verificationStatus = 'Verified';
            } else if (userData['idSubmitted'] == true) {
              _verificationStatus = 'Pending Verification';
            } else if (userData['idRejected'] == true) {
              _verificationStatus = 'Verification Rejected';
            } else {
              _verificationStatus = 'Not Verified';
            }
          });
        } else {
          // Fallback to Firebase Auth user data if Firestore document doesn't exist
          setState(() {
            _name = currentUser.displayName ?? 'Your Name';
            _email = currentUser.email ?? 'user@example.com';
            _profileImageUrl = currentUser.photoURL ?? '';
            _memberSince = 'Member since: ${DateFormat('MMM yyyy').format(currentUser.metadata.creationTime ?? DateTime.now())}';
          });
          
          // If user doesn't exist in Firestore, create a document for them
          print('User document not found in Firestore. Creating a new document.');
          await AuthService().addUserToFirestore(currentUser, currentUser.email ?? '');
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile data. Please try again.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Initialize all case streams
  void _initializeCaseStreams() async {
    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    // Clear existing subscriptions
    for (var subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();

    // Stream from incidents collection
    final incidentsStream = FirebaseFirestore.instance
        .collection('incidents')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots();

    // Stream from missingPersons collection
    final missingPersonsStream = FirebaseFirestore.instance
        .collection('missingPersons')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots();

    // Stream from archivedCases collection
    final archivedCasesStream = FirebaseFirestore.instance
        .collection('archivedCases')
        .where('userId', isEqualTo: currentUser.uid)
        .snapshots();

    // Add stream subscriptions
    _streamSubscriptions.add(
      incidentsStream.listen((snapshot) => _updateCasesData())
    );
    
    _streamSubscriptions.add(
      missingPersonsStream.listen((snapshot) => _updateCasesData())
    );
    
    _streamSubscriptions.add(
      archivedCasesStream.listen((snapshot) => _updateCasesData())
    );
  }
  // Update cases data from all collections
  Future<void> _updateCasesData() async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final List<Map<String, dynamic>> allCases = [];
      
      // Fetch from incidents collection
      final QuerySnapshot incidentsQuery = await FirebaseFirestore.instance
          .collection('incidents')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      for (final doc in incidentsQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final incidentDetails = data['incidentDetails'] ?? {};
        final status = data['status'] ?? 'Reported';
        
        // Skip resolved cases as they are archived
        if (status == 'Resolved Case' || status == 'Resolved') {
          continue;
        }
        
        allCases.add({
          'id': doc.id,
          'caseNumber': incidentDetails['incidentId'] ?? doc.id,
          'name': _extractName(data),
          'dateCreated': _formatTimestamp(incidentDetails['createdAt']),
          'status': status,
          'progress': _generateProgressSteps(status),
          'rawData': data,
        });
      }
      
      // Fetch from missingPersons collection
      final QuerySnapshot missingPersonsQuery = await FirebaseFirestore.instance
          .collection('missingPersons')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      for (final doc in missingPersonsQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status'] ?? 'Reported';
        
        // Skip resolved cases as they are archived
        if (status == 'Resolved Case' || status == 'Resolved') {
          continue;
        }
        
        allCases.add({
          'id': doc.id,
          'caseNumber': data['case_id'] ?? doc.id,
          'name': data['name'] ?? 'Unknown Person',
          'dateCreated': _formatTimestamp(data['datetime_reported']),
          'status': status,
          'progress': _generateProgressSteps(status),
          'rawData': data,
        });
      }
      
      // Note: We don't fetch from archivedCases collection for active case tracking
      // as these are resolved cases that should not appear in the user's active case list
      
      // Sort all cases by date (newest first)
      allCases.sort((a, b) {
        final DateTime dateA = _parseDate(a['dateCreated']);
        final DateTime dateB = _parseDate(b['dateCreated']);
        return dateB.compareTo(dateA);
      });
      
      setState(() {
        _casesData = allCases;
        // Maintain selected index within bounds
        if (_selectedCaseIndex >= allCases.length) {
          _selectedCaseIndex = allCases.isEmpty ? 0 : allCases.length - 1;
        }
      });
    } catch (e) {
      print('Error updating user cases: $e');
    }
  }
  
  // Helper method to extract name from different data structures
  String _extractName(Map<String, dynamic> data) {
    if (data['itemC'] != null) {
      final itemC = data['itemC'];
      return ((itemC['firstName'] ?? '') +
          (itemC['middleName'] != null ? ' ${itemC['middleName']}' : '') +
          (itemC['familyName'] != null ? ' ${itemC['familyName']}' : '')).trim();
    } else if (data['name'] != null) {
      return data['name'];
    } else {
      return 'Unknown Person';
    }
  }
  
  // Helper method to format timestamp
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is Map && timestamp['seconds'] != null) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp['seconds'] * 1000);
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return '';
      }
      return DateFormat('dd MMM yyyy').format(dateTime);
    } catch (e) {
      print('Error formatting timestamp: $e');
      return '';
    }
  }
  
  // Helper method to parse date string back to DateTime
  DateTime _parseDate(String dateStr) {
    try {
      return DateFormat('dd MMM yyyy').parse(dateStr);
    } catch (e) {
      return DateTime.now();
    }
  }
  
  // Generate progress steps based on status
  List<Map<String, String>> _generateProgressSteps(String currentStatus) {
    final int currentStep = _statusToStep[currentStatus] ?? 1;
    
    return _caseProgressSteps.map((step) {
      final int stepNumber = _caseProgressSteps.indexOf(step) + 1;
      String status;
      
      if (stepNumber < currentStep) {
        status = 'Completed';
      } else if (stepNumber == currentStep) {
        status = 'In Progress';
      } else {
        status = 'Pending';
      }
      
      return {
        'stage': step['stage'] ?? '',
        'status': status,
      };
    }).toList();
  }

  Future<void> _updateProfilePicture() async {
    try {
      // Show options to pick image from gallery or camera
      final source = await showDialog<ImageSource>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Select Image Source'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Gallery'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Camera'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ],
            ),
          );
        },
      );

      if (source == null) return;

      // Pick image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );

      if (image == null) return;

      // Show loading indicator
      setState(() => _isLoading = true);
      
      // Upload to Firebase Storage
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) throw Exception('User not logged in');

      final File imageFile = File(image.path);
      
      // Create a reference with the user's UID
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${currentUser.uid}.jpg');
      
      // Upload the file with appropriate metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': currentUser.uid},
      );
      
      // Upload file
      await storageRef.putFile(imageFile, metadata);
      
      // Get download URL
      final String downloadURL = await storageRef.getDownloadURL();
      
      // Update Firebase Auth profile
      await currentUser.updatePhotoURL(downloadURL);
      
      // Find user document and update in Firestore
      final QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('uid', isEqualTo: currentUser.uid)
          .limit(1)
          .get();
      
      if (userQuery.docs.isNotEmpty) {
        await userQuery.docs.first.reference.update({
          'photoURL': downloadURL
        });
      } else {
        throw Exception('User document not found');
      }
      
      // Update local state
      setState(() {
        _profileImageUrl = downloadURL;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile picture updated successfully')),
      );
      
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error updating profile picture: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile picture: ${e.toString()}')),
      );
    }
  }

  Future<void> _signOut() async {
    final bool? shouldLogOut = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titlePadding: EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: EdgeInsets.fromLTRB(24, 0, 24, 0),
          backgroundColor: Colors.white,
          elevation: 5,
          title: Column(
            children: [
              Icon(
                Icons.logout,
                color: Color(0xFF0D47A1),
                size: 48,
              ),
              SizedBox(height: 16),
              Text(
                'Log Out',
                style: TextStyle(
                  color: Color(0xFF0D47A1),
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 16),
                Text(
                  'Are you sure you want to log out of your account?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade700,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(
                'CANCEL',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF0D47A1),
                foregroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'LOG OUT',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
          actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          actionsAlignment: MainAxisAlignment.spaceBetween,
        );
      },
    );

    if (shouldLogOut == true) {
      await AuthService().signOutUser(context);
    }
  }

  // Function to get verification status color
  Color _getVerificationStatusColor() {
    switch (_verificationStatus) {
      case 'Verified':
        return Colors.green;
      case 'Pending Verification':
        return Colors.orange;
      case 'Verification Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Function to get verification status icon
  IconData _getVerificationStatusIcon() {
    switch (_verificationStatus) {
      case 'Verified':
        return Icons.verified;
      case 'Pending Verification':
        return Icons.hourglass_top;
      case 'Verification Rejected':
        return Icons.cancel;
      default:
        return Icons.person_off;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text("Profile", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false),
        ),
        actions: [
          // Modified sign out button with icon positioned after text
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _signOut,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                minimumSize: Size(120, 40), // Set minimum size for the button
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Log Out",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 21, // Increased font size to match app bar title
                    ),
                  ),
                  SizedBox(width: 8),  // Space between text and icon
                  Icon(
                    Icons.logout, 
                    color: Colors.white,
                    size: 24, // Increased icon size
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: _isLoading 
      ? Center(child: CircularProgressIndicator())
      : Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D47A1), Colors.blue.shade100],
            stops: [0.0, 50],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Enhanced Profile section with verification status
              Container(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    children: [                      ProfileAvatar(
                        imageUrl: _profileImageUrl,
                        onEditPressed: () {
                          _updateProfilePicture();
                        },
                      ),
                      SizedBox(height: 16),                      Text(
                        _name,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      SizedBox(height: 8),
                      // Verification status badge
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getVerificationStatusColor().withOpacity(0.7),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getVerificationStatusIcon(),
                              size: 16,
                              color: _getVerificationStatusColor(),
                            ),
                            SizedBox(width: 6),
                            Text(
                              _verificationStatus,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      // User details in a card with better visual hierarchy
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildContactInfo(Icons.email, _email),
                            Divider(height: 16, thickness: 0.5, color: Colors.white30),
                            _buildContactInfo(Icons.calendar_today, _memberSince),
                          ],
                        ),
                      ),                    ],
                  ),
                ),
              ),
                // Track case content section
              Padding(
                padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Case Summary Header
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 500),
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(0xFF0D47A1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "CASE TRACKER",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),                    // Case Cards Carousel
                    Container(
                      height: 300, // Increased height to accommodate navigation
                      child: _casesData.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    size: 48,
                                    color: Colors.grey.withOpacity(0.6),
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    "No cases found.",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "When you submit a case, it will appear here",
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Column(
                              children: [
                                // Case card display area
                                Expanded(
                                  child: Center(
                                    child: Container(
                                      width: MediaQuery.of(context).size.width * 0.9,
                                      constraints: BoxConstraints(
                                        maxHeight: MediaQuery.of(context).size.height * 0.35, // Limit height
                                      ),
                                      child: _buildCaseCard(_selectedCaseIndex),
                                    ),
                                  ),
                                ),
                                  // Navigation controls below the card
                                if (_casesData.length > 1)
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final screenWidth = MediaQuery.of(context).size.width;
                                        final isSmallScreen = screenWidth < 360;
                                        
                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            // Previous button
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.only(right: 4),
                                                child: ElevatedButton.icon(
                                                  onPressed: () {
                                                    setState(() {
                                                      _selectedCaseIndex = _selectedCaseIndex > 0 
                                                          ? _selectedCaseIndex - 1 
                                                          : _casesData.length - 1;
                                                    });
                                                  },
                                                  icon: Icon(
                                                    Icons.skip_previous, 
                                                    size: isSmallScreen ? 16 : 18,
                                                  ),
                                                  label: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      isSmallScreen ? 'Prev' : 'Previous',
                                                      style: TextStyle(
                                                        fontSize: isSmallScreen ? 12 : 14,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.white,
                                                    foregroundColor: Color(0xFF0D47A1),
                                                    elevation: 2,
                                                    side: BorderSide(color: Color(0xFF0D47A1)),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                                                    ),
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: isSmallScreen ? 8 : 12, 
                                                      vertical: isSmallScreen ? 8 : 10,
                                                    ),
                                                    minimumSize: Size(isSmallScreen ? 80 : 100, 36),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            
                                            // Case indicator with current position
                                            Container(
                                              margin: EdgeInsets.symmetric(horizontal: 8),
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isSmallScreen ? 12 : 16, 
                                                vertical: isSmallScreen ? 8 : 10,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF0D47A1),
                                                borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                                              ),
                                              child: Text(
                                                '${_selectedCaseIndex + 1} / ${_casesData.length}',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: isSmallScreen ? 12 : 14,
                                                ),
                                              ),
                                            ),
                                            
                                            // Next button
                                            Expanded(
                                              child: Padding(
                                                padding: EdgeInsets.only(left: 4),
                                                child: ElevatedButton.icon(
                                                  onPressed: () {
                                                    setState(() {
                                                      _selectedCaseIndex = _selectedCaseIndex < _casesData.length - 1 
                                                          ? _selectedCaseIndex + 1 
                                                          : 0;
                                                    });
                                                  },
                                                  icon: Icon(
                                                    Icons.skip_next, 
                                                    size: isSmallScreen ? 16 : 18,
                                                  ),
                                                  label: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      'Next',
                                                      style: TextStyle(
                                                        fontSize: isSmallScreen ? 12 : 14,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: Colors.white,
                                                    foregroundColor: Color(0xFF0D47A1),
                                                    elevation: 2,
                                                    side: BorderSide(color: Color(0xFF0D47A1)),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(isSmallScreen ? 16 : 20),
                                                    ),
                                                    padding: EdgeInsets.symmetric(
                                                      horizontal: isSmallScreen ? 8 : 12, 
                                                      vertical: isSmallScreen ? 8 : 10,
                                                    ),
                                                    minimumSize: Size(isSmallScreen ? 80 : 100, 36),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                
                                // Dot indicators
                                if (_casesData.length > 1)
                                  Padding(
                                    padding: EdgeInsets.only(top: 8),
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final screenWidth = MediaQuery.of(context).size.width;
                                        final dotSize = screenWidth < 360 ? 8.0 : 10.0;
                                        final dotSpacing = screenWidth < 360 ? 3.0 : 4.0;
                                        
                                        return Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: List.generate(
                                            _casesData.length,
                                            (index) => GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _selectedCaseIndex = index;
                                                });
                                              },
                                              child: AnimatedContainer(
                                                duration: Duration(milliseconds: 200),
                                                margin: EdgeInsets.symmetric(horizontal: dotSpacing),
                                                width: index == _selectedCaseIndex ? dotSize + 2 : dotSize,
                                                height: index == _selectedCaseIndex ? dotSize + 2 : dotSize,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: index == _selectedCaseIndex
                                                      ? Color(0xFF0D47A1)
                                                      : Colors.grey.shade400,
                                                  boxShadow: index == _selectedCaseIndex ? [
                                                    BoxShadow(
                                                      color: Color(0xFF0D47A1).withOpacity(0.3),
                                                      spreadRadius: 1,
                                                      blurRadius: 3,
                                                    ),
                                                  ] : null,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                    ),SizedBox(height: 24),
                    SizedBox(height: 24),
                    
                    // Status Timeline Section
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 500),
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(0xFF0D47A1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "CASE PROGRESS",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),

                    // Timeline Visualization in a Card
                    if (_casesData.isNotEmpty)
                      Card(
                        elevation: 2,
                        color: Colors.blue.shade50,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Container(
                            height: 100, // Slightly increased for better visual balance
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _casesData[_selectedCaseIndex]['progress'].length,
                              itemBuilder: (context, index) {
                                final stage = _casesData[_selectedCaseIndex]['progress'][index];
                                Color color;
                                IconData icon;
                                
                                // Enhanced status handling with proper Evidence Submitted support
                                switch (stage['status']) {
                                  case 'Completed':
                                    color = Colors.green;
                                    icon = Icons.check_circle;
                                    break;
                                  case 'In Progress':
                                    color = Colors.orange;
                                    icon = Icons.pending;
                                    break;
                                  case 'Pending':
                                    color = Colors.grey.shade400;
                                    icon = Icons.hourglass_empty;
                                    break;
                                  default:
                                    color = Colors.grey;
                                    icon = Icons.circle_outlined;
                                }
                                
                                // Special handling for Evidence Submitted stage
                                if (stage['stage'] == 'Evidence Submitted') {
                                  if (stage['status'] == 'Completed') {
                                    color = Colors.teal;
                                    icon = Icons.upload_file;
                                  } else if (stage['status'] == 'In Progress') {
                                    color = Colors.orange;
                                    icon = Icons.upload_outlined;
                                  }
                                }
                                
                                return Container(
                                  width: MediaQuery.of(context).size.width / 3.8, // Slightly larger for better readability
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: color.withOpacity(0.15),
                                          border: Border.all(color: color, width: 2),
                                        ),
                                        child: Icon(
                                          icon,
                                          color: color,
                                          size: 20,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        stage['stage'],
                                        textAlign: TextAlign.center,
                                        maxLines: 2, // Allow text wrapping for longer stage names
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          height: 1.2,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        stage['status'],
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: Colors.grey[600],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    if (_casesData.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(
                          child: Text(
                            "No case progress to show.",
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ),
                    
                    // FindMe Features Section
                    SizedBox(height: 32),
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 500),
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(0xFF0D47A1),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "FINDME PROTECTION",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Color.fromARGB(255, 0, 0, 0),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    
                    // FindMe Buttons
                    Card(
                      elevation: 2,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            // Enhanced FindMe Settings Button
                            Container(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => FindMeSettingsScreen()),
                                  );
                                },
                                icon: Icon(Icons.security, size: 24),
                                label: Text(
                                  'FindMe Settings',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            
                            // Find My Devices Button
                            Container(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => FindMyDevicesScreen()),
                                  );
                                },
                                icon: Icon(Icons.devices, size: 24),
                                label: Text(
                                  'Find My Family',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade600,
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                ),
                              ),
                            ),
                            SizedBox(height: 12),
                            
                            // About FindMe Button
                            Container(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => FindMeInfoScreen()),
                                  );
                                },
                                icon: Icon(Icons.info_outline, size: 24),
                                label: Text(
                                  'About FindMe',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF0D47A1),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                ),
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfo(IconData icon, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: Colors.white70),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }  // Helper method to build a case card
  Widget _buildCaseCard(int index) {
    if (index >= _casesData.length) return Container();
    
    final caseData = _casesData[index];
    
    // Determine card color and icon based on status
    Color statusColor;
    IconData statusIcon;
    
    switch(caseData['status']) {
      case 'In Progress':
        statusColor = Colors.orange;
        statusIcon = Icons.sync;
        break;
      case 'Evidence Submitted':
        statusColor = Colors.teal;
        statusIcon = Icons.upload_file;
        break;
      case 'Resolved Case':
      case 'Resolved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'Under Review':
        statusColor = Colors.blue;
        statusIcon = Icons.visibility;
        break;
      case 'Case Verified':
        statusColor = Colors.purple;
        statusIcon = Icons.verified;
        break;
      case 'Unresolved Case':
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.info_outline;
    }
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(
          color: Color(0xFF0D47A1),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.2),
            spreadRadius: 0,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(8), // Further reduced padding from 12 to 8
        child: SingleChildScrollView( // Added scrollable container
          physics: ClampingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            // Status badge with icon
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), // Further reduced padding
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    statusIcon,
                    size: 10, // Further reduced from 11
                    color: statusColor,
                  ),
                  SizedBox(width: 2), // Reduced from 3
                  Text(
                    caseData['status'],
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 9, // Reduced from 10
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 6), // Reduced from 8
            
            // Case ID with copy button
            Row(
              children: [
                Expanded(
                  child: Text(
                    "Case ID: ${caseData['caseNumber']}",
                    style: TextStyle(
                      fontSize: 17, // Reduced from 16
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D47A1),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final data = ClipboardData(text: caseData['caseNumber'] ?? '');
                    Clipboard.setData(data);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Case ID copied to clipboard'),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(3), // Reduced from 4
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.copy_outlined,
                      size: 12, // Reduced from 14
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6), // Reduced from 8
              // Missing Person info with enhanced styling
            Container(
              height: 60, // Reduced height from 70 to 60
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Further reduced padding
              decoration: BoxDecoration(
                color: Colors.blue.shade50.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(4), // Reduced from 5
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade300, Colors.blue.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade300.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person_search,
                      size: 11, // Reduced from 12
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 6), // Reduced from 8
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Missing Person",
                          style: TextStyle(
                            fontSize: 11, // Reduced font size from 16
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 1),
                        Flexible( // Added Flexible to prevent overflow
                          child: Text(
                            caseData['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13, // Reduced from 16
                              fontWeight: FontWeight.w700,
                              color: Colors.black.withOpacity(0.85),
                              height: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 4), // Reduced from 6
            
            // Date reported with styled badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2), // Further reduced padding
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 9, // Reduced from 10
                    color: Colors.grey[700],
                  ),
                  SizedBox(width: 2), // Reduced from 3
                  Text(
                    "Reported: ${caseData['dateCreated']}",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 10, // Reduced from 12
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Upload Evidence button (only show when status is "In Progress")
            if (caseData['status'] == 'In Progress') ...[
              SizedBox(height: 8), // Reduced from 12
              Flexible( // Added Flexible to prevent overflow
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Get screen dimensions
                    final screenWidth = MediaQuery.of(context).size.width;
                    final screenHeight = MediaQuery.of(context).size.height;
                    final orientation = MediaQuery.of(context).orientation;
                    
                    // Dynamic sizing based on screen size - more aggressive reduction
                    double buttonHeight = screenHeight < 600 ? 28 : 32; // Further reduced height
                    double iconSize = screenWidth < 360 ? 14 : 16; // Reduced icon size
                    double fontSize = screenWidth < 360 ? 10 : 12; // Smaller font
                    double horizontalPadding = screenWidth < 360 ? 6 : 8; // Less padding
                    double verticalPadding = 4; // Fixed smaller vertical padding
                    
                    // Adjust for landscape orientation
                    if (orientation == Orientation.landscape) {
                      buttonHeight = 26; // Even smaller height in landscape
                      fontSize = 11; // Smaller font in landscape
                    }
                    
                    return Container(
                      width: double.infinity,
                      constraints: BoxConstraints(
                        minHeight: buttonHeight,
                        maxHeight: buttonHeight + 4, // Smaller flexibility range
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EvidenceSubmissionScreen(
                                caseId: caseData['id'],
                                caseNumber: caseData['caseNumber'],
                                caseName: caseData['name'],
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.upload_file, 
                          size: iconSize,
                        ),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Upload Evidence',
                            style: TextStyle(
                              fontSize: fontSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          elevation: 1, // Reduced elevation
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6), // Smaller radius
                          ),
                          padding: EdgeInsets.symmetric(
                            vertical: verticalPadding, 
                            horizontal: horizontalPadding,
                          ),
                          minimumSize: Size(double.infinity, buttonHeight),
                          maximumSize: Size(double.infinity, buttonHeight + 4),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            
            // Show Evidence Submitted status with action button
            if (caseData['status'] == 'Evidence Submitted') ...[
              SizedBox(height: 8), // Reduced from 12
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Reduced padding
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(6), // Smaller radius
                  border: Border.all(color: Colors.teal.shade200, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.teal.shade600,
                      size: 16, // Reduced from 18
                    ),
                    SizedBox(width: 6), // Reduced from 8
                    Expanded(
                      child: Text(
                        'Evidence has been submitted and is under review',
                        style: TextStyle(
                          color: Colors.teal.shade700,
                          fontSize: 11, // Reduced from 13
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ], // Close the if condition array for Evidence Submitted status
          ], // Close the children array of the Column
        ), // Close SingleChildScrollView
      ), 
      )// Close Padding
    ); // Close AnimatedContainer
  } // Close _buildCaseCard method
} // Close _ProfileScreenState class