
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/app_export.dart';
import 'package:intl/intl.dart';

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
    // This would typically involve using image_picker and Firebase Storage
    // For now, we'll just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Profile picture update functionality will be implemented soon.')),
    );
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
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Colors.white),
            tooltip: 'New Report',
            onPressed: () => Navigator.pushNamed(context, '/new_report'),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: Colors.white),
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: _isLoading 
      ? Center(child: CircularProgressIndicator())
      : SingleChildScrollView(
        child: Column(
          children: [
            Container(
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
              child: Column(
                children: [
                  Container(
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
                        _buildUserStats(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Your Reported Forms',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => showFilterOptions(context),
                          icon: Icon(Icons.filter_list),
                          label: Text('Filter'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search reports...',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 500,
                    child: ReportedFormsList(),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
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
  
  Widget _buildUserStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        UserStatsCard(
          count: "0",
          label: "Reports",
          icon: Icons.description,
        ),
        SizedBox(width: 12),
        UserStatsCard(
          count: "0",
          label: "Active",
          icon: Icons.auto_graph,
        ),
        SizedBox(width: 12),
        UserStatsCard(
          count: "0",
          label: "Pending",
          icon: Icons.pending_actions,
        ),
        SizedBox(width: 12),
        UserStatsCard(
          count: "0",
          label: "Resolved",
          icon: Icons.check_circle,
        ),
      ],
    );
  }
}
