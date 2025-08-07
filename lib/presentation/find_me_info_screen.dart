import 'package:flutter/material.dart';

class FindMeInfoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About FindMe Feature'),
        backgroundColor: Color.fromARGB(255, 18, 32, 47),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMainCard(),
            SizedBox(height: 16),
            _buildHowItWorksCard(),
            SizedBox(height: 16),
            _buildPrivacyCard(),
            SizedBox(height: 16),
            _buildFamilySharingCard(),
            SizedBox(height: 24),
            _buildImportantNote(),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, size: 32, color: Colors.blue),
                SizedBox(width: 12),
                Text(
                  'What is FindMe?',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'FindMe enables location tracking for safety purposes and family location sharing. Your location can be shared with trusted family members or accessed by authorities when you are reported missing.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How it Works',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildStepItem('1', 'Enable FindMe', 'Turn on location tracking with your consent'),
            _buildStepItem('2', 'Add Family Members', 'Add trusted contacts for family sharing'),
            _buildStepItem('3', 'Grant Permissions', 'Choose who can access your location'),
            _buildStepItem('4', 'Stay Connected', 'Family can see your location when permitted'),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy & Security',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildPrivacyPoint('🔒', 'Data is encrypted and secured'),
            _buildPrivacyPoint('👥', 'Individual permissions per contact'),
            _buildPrivacyPoint('�', 'Can be disabled anytime'),
            _buildPrivacyPoint('📅', 'Location history kept for 30 days'),
            _buildPrivacyPoint('⚖️', 'Complies with Data Privacy Act'),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilySharingCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Family Location Sharing',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('With family sharing enabled:'),
            SizedBox(height: 8),
            Text('• Family members can see your location continuously'),
            Text('• No need to be reported missing for family access'),
            Text('• You control individual permissions per contact'),
            Text('• Remote actions (like sound alerts) if permitted'),
          ],
        ),
      ),
    );
  }

  Widget _buildImportantNote() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(Icons.info, color: Colors.blue, size: 32),
          SizedBox(height: 8),
          Text(
            'Emergency Response',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[800],
            ),
          ),
          SizedBox(height: 4),
          Text(
            'This feature helps locate missing persons by securely tracking location data and sharing it with authorized contacts during emergencies.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blue[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String title, String description) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  description,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyPoint(String emoji, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 16)),
          SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
