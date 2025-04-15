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

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() => _isLoading = true);
    
    try {
      final User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // Query users-app collection by uid field
        final QuerySnapshot userQuery = await FirebaseFirestore.instance
            .collection('users-app')
            .where('uid', isEqualTo: currentUser.uid)
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

  Future<String?> _showEditNameDialog() async {
    TextEditingController nameController = TextEditingController(text: _name);
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Name'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'Name'),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(nameController.text);
              },
              child: Text('Save'),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                backgroundColor: const Color.fromARGB(255, 235, 96, 96),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Discard'),
            ),
          ],
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
            .collection('users-app')
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
          .collection('users-app')
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

  @override
  Widget build(BuildContext context) {
    // Sample case data to display in profile screen
    final Map<String, dynamic> sampleCaseData = {
      'caseNumber': '2023-0042',
      'name': 'John Smith',
      'dateCreated': '15 Apr 2023',
      'status': 'In Progress'
    };

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text("Profile", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
      ),
      drawer: AppDrawer(),
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
              // Profile section with blue gradient background
              Container(
                width: double.infinity,
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      ProfileAvatar(
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
                      _buildContactInfo(Icons.email, _email),
                      SizedBox(height: 8),
                      _buildContactInfo(Icons.calendar_today, _memberSince),
                    ],
                  ),
                ),
              ),
              
              // Track case content section
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Case Summary Card
                    Card(
                      elevation: 2,
                      color: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Case #${sampleCaseData['caseNumber']}",
                                  style: TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D47A1),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "In Progress",
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              sampleCaseData['name'] ?? "Unknown",
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Reported on: ${sampleCaseData['dateCreated'] ?? "Unknown date"}",
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
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
                    Card(
                      elevation: 2,
                      color: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Container(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: [
                              {'stage': 'Reported', 'status': 'Completed'},
                              {'stage': 'Under Investigation', 'status': 'In Progress'},
                              {'stage': 'Assigned Authorities', 'status': 'Pending'},
                              {'stage': 'Resolved', 'status': 'Pending'},
                            ].length,
                            itemBuilder: (context, index) {
                              final stages = [
                                {'stage': 'Reported', 'status': 'Completed'},
                                {'stage': 'Under Investigation', 'status': 'In Progress'},
                                {'stage': 'Assigned Authorities', 'status': 'Pending'},
                                {'stage': 'Resolved', 'status': 'Pending'},
                              ];
                              final stage = stages[index];
                              Color color = stage['status'] == 'Completed' 
                                  ? Colors.green 
                                  : stage['status'] == 'In Progress' 
                                      ? Colors.orange 
                                      : Colors.grey;
                              
                              return Container(
                                width: MediaQuery.of(context).size.width / 4,
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
                                                  : Icons.hourglass_empty,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      stage['stage']!,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      stage['status']!,
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
                    
                    // Latest Update Card
                    Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 16),
                      color: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.update, color: Color(0xFF0D47A1)),
                                SizedBox(width: 8),
                                Text(
                                  "Latest Update",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D47A1),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              "Investigation in progress by Officer John Doe",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Updated 2 hours ago",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Previous Updates Cards
                    Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      color: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person_search, color: Colors.orange),
                                SizedBox(width: 8),
                                Text(
                                  "Field Investigation",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              "Search operation conducted in Barangay San Antonio",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Updated 1 day ago",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      color: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.camera_alt, color: Colors.green),
                                    SizedBox(width: 8),
                                    Text(
                                      "Evidence Collected",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "Verified",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              "CCTV footage obtained from nearby establishment",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Updated 3 days ago",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      color: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.people_alt, color: Color(0xFF0D47A1)),
                                SizedBox(width: 8),
                                Text(
                                  "Witness Interview",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0D47A1),
                                  ),
                                ),
                                Spacer(),
                                Icon(Icons.lock_outline, size: 16, color: Colors.grey),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              "Conducted interviews with 3 witnesses",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                            Text(
                              "[Additional details restricted]",
                              style: TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Updated 5 days ago",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    Card(
                      elevation: 2,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      color: Colors.blue.shade50,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.report_problem, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  "Initial Report",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              "Case filed and assigned to Investigation Unit",
                              style: TextStyle(
                                fontSize: 14,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                            SizedBox(height: 8),
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.person_pin, size: 20, color: Colors.grey[600]),
                                  SizedBox(width: 8),
                                  Text(
                                    "Assigned to: Det. Maria Santos",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Updated 1 week ago",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Add some bottom padding
                    SizedBox(height: 16),
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
