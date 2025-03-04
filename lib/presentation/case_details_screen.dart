import '../core/app_export.dart';
import '../models/missing_person_model.dart';

class CaseDetailsScreen extends StatelessWidget {
  final MissingPerson person;

  const CaseDetailsScreen({Key? key, required this.person}) : super(key: key);

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D47A1),
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: double.infinity,
      height: 300,
      child: person.imageUrl.isNotEmpty
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                person.imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  print('Error loading image: $error');
                  return Container(
                    color: Colors.grey[200],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Image not available'),
                      ],
                    ),
                  );
                },
              ),
            )
          : Container(
              color: Colors.grey[200],
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('No image available'),
                ],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Case Details'),
        backgroundColor: Color(0xFF0D47A1),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Name', person.name),
                    _buildInfoRow('Case ID', person.caseId),
                    _buildInfoRow('Description', person.descriptions),
                    _buildInfoRow('Address', person.address),
                    _buildInfoRow('Last Seen At', person.placeLastSeen),
                    _buildInfoRow('Last Seen Date', person.datetimeLastSeen),
                    _buildInfoRow('Date Reported', person.datetimeReported),
                    _buildInfoRow('Complainant', person.complainant),
                    _buildInfoRow('Relationship', person.relationship),
                    _buildInfoRow('Contact', person.contactNo),
                    if (person.additionalInfo.isNotEmpty)
                      _buildInfoRow('Additional Info', person.additionalInfo),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: _buildImage(),
            ),
            // ...existing button code...
          ],
        ),
      ),
    );
  }
}
