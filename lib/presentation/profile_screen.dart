import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_export.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

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
    {'stage': 'Resolved Case', 'status': 'Pending'},
    {'stage': 'Unresolved Case', 'status': 'Pending'},
  ];
  
  // Map to convert status to step number (1-indexed)
  final Map<String, int> _statusToStep = {
    'Reported': 1,
    'Under Review': 2,
    'Case Verified': 3,
    'In Progress': 4,
    'Resolved Case': 5,
    'Unresolved Case': 6,
    'Resolved': 5, // Map 'Resolved' to 'Resolved Case' step
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
        
        allCases.add({
          'id': doc.id,
          'caseNumber': incidentDetails['incidentId'] ?? doc.id,
          'name': _extractName(data),
          'dateCreated': _formatTimestamp(incidentDetails['createdAt']),
          'status': data['status'] ?? 'Reported',
          'progress': _generateProgressSteps(data['status'] ?? 'Reported'),
          'pdfUrl': data['pdfUrl'],
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
        
        allCases.add({
          'id': doc.id,
          'caseNumber': data['case_id'] ?? doc.id,
          'name': data['name'] ?? 'Unknown Person',
          'dateCreated': _formatTimestamp(data['datetime_reported']),
          'status': data['status'] ?? 'Reported',
          'progress': _generateProgressSteps(data['status'] ?? 'Reported'),
          'pdfUrl': data['pdfUrl'],
          'rawData': data,
        });
      }
      
      // Fetch from archivedCases collection
      final QuerySnapshot archivedCasesQuery = await FirebaseFirestore.instance
          .collection('archivedCases')
          .where('userId', isEqualTo: currentUser.uid)
          .get();

      for (final doc in archivedCasesQuery.docs) {
        final data = doc.data() as Map<String, dynamic>;
        String status = data['status'] ?? 'Reported';
        
        // For archivedCases, if status is "Resolved", map it to "Resolved Case"
        if (status == 'Resolved' && data['source'] == 'archivedCases') {
          status = 'Resolved Case';
        }
        
        allCases.add({
          'id': doc.id,
          'caseNumber': data['incidentId'] ?? doc.id,
          'name': _extractName(data),
          'dateCreated': _formatTimestamp(data['createdAt']),
          'status': status,
          'progress': _generateProgressSteps(status),
          'pdfUrl': data['pdfUrl'],
          'rawData': data,
        });
      }
      
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

  Future<String?> _showEditNameDialog() async {
    TextEditingController nameController = TextEditingController(text: _name);
    bool isValidName = true;
    String errorText = '';
    
    return showDialog<String>(
      context: context,
      barrierDismissible: true, // Allow dismissing by tapping outside
      barrierColor: Colors.black54, // Semi-transparent barrier
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AnimatedContainer(
              duration: Duration(milliseconds: 300),
              child: AlertDialog(
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
                      Icons.person_outline,
                      color: Color(0xFF0D47A1),
                      size: 48,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Edit Your Name',
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
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        onChanged: (value) {
                          setState(() {
                            if (value.isEmpty) {
                              isValidName = false;
                              errorText = 'Name cannot be empty';
                            } else if (value.length < 3) {
                              isValidName = false;
                              errorText = 'Name must be at least 3 characters';
                            } else {
                              isValidName = true;
                              errorText = '';
                            }
                          });
                        },
                        style: TextStyle(
                          fontSize: 16,
                          color: Color.fromARGB(255, 0, 0, 0), // Changed text color to green
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Your Name',
                          labelStyle: TextStyle(
                            color: Color.fromARGB(255, 0, 0, 0), // Changed label color to green
                            fontWeight: FontWeight.w500,
                          ),
                          errorText: !isValidName ? errorText : null,
                          prefixIcon: Icon(Icons.person, color: Color(0xFF0D47A1)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: const Color.fromARGB(255, 0, 0, 0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Color.fromARGB(255, 0, 0, 0), width: 2), // Changed focused border to green
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
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
                    onPressed: isValidName ? () {
                      Navigator.of(context).pop(nameController.text.trim());
                    } : null,
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
                      'SAVE',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                actionsPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                actionsAlignment: MainAxisAlignment.spaceBetween,
              ),
            );
          }
        );
      },
    );
  }

  Future<void> _updateUserName(String newName) async {
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        // First, find the user document by uid
        final QuerySnapshot userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: currentUser.uid)
            .limit(1)
            .get();
            
        if (userQuery.docs.isNotEmpty) {
          // Update in Firestore using document reference
          await userQuery.docs.first.reference.update({
            'displayName': newName
          });
          
          // Update in Firebase Auth
          await currentUser.updateDisplayName(newName);
          
          setState(() => _name = newName);
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Name updated successfully')),
          );
        } else {
          throw Exception('User document not found');
        }
      }
    } catch (e) {
      print('Error updating name: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating name. Please try again.')),
      );
    }
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
    await AuthService().signOutUser(context);
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
                    "Sign Out",
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
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 2),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.white, size: 20),
                            onPressed: () async {
                              final newName = await _showEditNameDialog();
                              if (newName != null && newName.isNotEmpty) {
                                await _updateUserName(newName);
                              }
                            },
                          ),
                        ],
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
                    SizedBox(height: 16),                    // Case Cards
                    Container(
                      height: 270, // Increased height for better content display
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
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _casesData.length,
                              itemBuilder: (context, index) {
                                final caseData = _casesData[index];
                                
                                // Determine card color and icon based on status
                                Color statusColor;
                                IconData statusIcon;
                                
                                switch(caseData['status']) {
                                  case 'In Progress':
                                    statusColor = Colors.orange;
                                    statusIcon = Icons.sync;
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
                                
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCaseIndex = index;
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    margin: EdgeInsets.only(right: 16, bottom: 8),
                                    width: MediaQuery.of(context).size.width * 0.8,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: _selectedCaseIndex == index ? 
                                        Colors.blue.shade50 : 
                                        Colors.white,
                                      border: Border.all(
                                        color: _selectedCaseIndex == index ? 
                                          Color(0xFF0D47A1) : 
                                          Colors.grey.shade300,
                                        width: _selectedCaseIndex == index ? 2 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (_selectedCaseIndex == index ? 
                                            Colors.blue.withOpacity(0.2) : 
                                            Colors.black.withOpacity(0.08)),
                                          spreadRadius: 0,
                                          blurRadius: 12,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Selected indicator
                                        if (_selectedCaseIndex == index)
                                          Positioned(
                                            top: 12,
                                            right: 12,
                                            child: Container(
                                              padding: EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Color(0xFF0D47A1),
                                                shape: BoxShape.circle,
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.blue.withOpacity(0.3),
                                                    blurRadius: 8,
                                                    offset: Offset(0, 3),
                                                  ),
                                                ],
                                              ),
                                              child: Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                          
                                        // Card content
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(20, 20, 20, 20),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Status badge with icon
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: statusColor.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(20),
                                                  border: Border.all(color: statusColor, width: 1),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      statusIcon,
                                                      size: 14,
                                                      color: statusColor,
                                                    ),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      caseData['status'],
                                                      style: TextStyle(
                                                        color: statusColor,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 16),
                                              
                                              // Case ID with copy button
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      "Case ID: ${caseData['caseNumber']}",
                                                      style: TextStyle(
                                                        fontSize: 18,
                                                        fontWeight: FontWeight.bold,
                                                        color: Color(0xFF0D47A1),
                                                      ),
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
                                                      padding: EdgeInsets.all(6),
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade100,
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        Icons.copy_outlined,
                                                        size: 16,
                                                        color: Colors.grey.shade700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 12),
                                                // Missing Person info with enhanced styling
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50.withOpacity(0.7),
                                                  borderRadius: BorderRadius.circular(14),
                                                  border: Border.all(color: Colors.blue.shade200, width: 1),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      padding: EdgeInsets.all(8),
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
                                                        size: 16,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                    SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            "Missing Person",
                                                            style: TextStyle(
                                                              fontSize: 13,
                                                              color: Colors.blue.shade800,
                                                              fontWeight: FontWeight.w600,
                                                              letterSpacing: 0.3,
                                                            ),
                                                          ),
                                                          SizedBox(height: 3),
                                                          Text(
                                                            caseData['name'],
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: TextStyle(
                                                              fontSize: 17,
                                                              fontWeight: FontWeight.w700,
                                                              color: Colors.black.withOpacity(0.85),
                                                              height: 1.2,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              
                                              Spacer(),
                                              
                                              // Date reported with styled badge
                                              Container(
                                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      Icons.calendar_today,
                                                      size: 14,
                                                      color: Colors.grey[700],
                                                    ),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      "Reported: ${caseData['dateCreated']}",
                                                      style: TextStyle(
                                                        color: Colors.grey[700],
                                                        fontSize: 13,
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              
                                              // PDF viewer button if PDF available
                                              if (caseData['pdfUrl'] != null && caseData['pdfUrl'].toString().isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 8.0),
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      // Launch PDF viewer (This would need URL launcher package implementation)
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text('Opening PDF viewer...'))
                                                      );
                                                    },
                                                    child: Container(
                                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                      decoration: BoxDecoration(
                                                        color: Colors.red.shade50,
                                                        borderRadius: BorderRadius.circular(8),
                                                        border: Border.all(color: Colors.red.shade200)
                                                      ),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            Icons.picture_as_pdf,
                                                            size: 16,
                                                            color: Colors.red,
                                                          ),
                                                          SizedBox(width: 6),
                                                          Text(
                                                            "View PDF",
                                                            style: TextStyle(
                                                              color: Colors.red,
                                                              fontWeight: FontWeight.w600,
                                                              fontSize: 13,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
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
                            height: 90,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _casesData[_selectedCaseIndex]['progress'].length,
                              itemBuilder: (context, index) {
                                final stage = _casesData[_selectedCaseIndex]['progress'][index];
                                Color color = stage['status'] == 'Completed' 
                                    ? Colors.green 
                                    : stage['status'] == 'In Progress' 
                                        ? Colors.orange 
                                        : stage['status'] == 'N/A'
                                            ? Colors.grey.shade400
                                            : Colors.grey;
                                
                                return Container(
                                  width: MediaQuery.of(context).size.width / 3.5,
                                  child: Column(
                                    children: [
                                      CircleAvatar(
                                        radius: 20,
                                        backgroundColor: color.withOpacity(0.2),
                                        child: CircleAvatar(
                                          radius: 15,
                                          backgroundColor: color,
                                          child: Icon(
                                            stage['status'] == 'Completed' 
                                                ? Icons.check 
                                                : stage['status'] == 'In Progress' 
                                                    ? Icons.refresh 
                                                    : stage['status'] == 'N/A'
                                                        ? Icons.remove
                                                        : Icons.hourglass_empty,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        stage['stage'],
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        stage['status'],
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
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
  }
}
