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
        // Get user data from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          
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
        }
      }
    } catch (e) {
      print('Error fetching user data: $e');
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
        // Update in Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({'displayName': newName});
        
        // Update in Firebase Auth
        await currentUser.updateDisplayName(newName);
        
        setState(() => _name = newName);
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
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${currentUser.uid}.jpg');
      
      // Upload file
      await storageRef.putFile(imageFile);
      
      // Get download URL
      final String downloadURL = await storageRef.getDownloadURL();
      
      // Update Firebase Auth profile
      await currentUser.updatePhotoURL(downloadURL);
      
      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'photoURL': downloadURL});
      
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
        SnackBar(content: Text('Error updating profile picture. Please try again.')),
      );
    }
  }

  Future<void> _signOut() async {
    await AuthService().signOutUser(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text("Profile", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blue.shade900,
      ),
      drawer: AppDrawer(),
      body: _isLoading 
      ? Center(child: CircularProgressIndicator())
      : SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.shade900,
                Colors.blue.shade800,
              ],
            ),
          ),
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
                SizedBox(height: 16),
              ],
            ),
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
