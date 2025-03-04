import '../core/app_export.dart';
import '../models/missing_person_model.dart';
import 'image_viewer_screen.dart';

class CaseDetailsScreen extends StatefulWidget {
  final MissingPerson person;

  const CaseDetailsScreen({Key? key, required this.person}) : super(key: key);

  @override
  State<CaseDetailsScreen> createState() => _CaseDetailsScreenState();
}

class _CaseDetailsScreenState extends State<CaseDetailsScreen> {
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
            child: Text(
              value,
              style: TextStyle(color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: double.infinity,
      height: 300,
      child: widget.person.imageUrl.isNotEmpty
          ? GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImageViewerScreen(
                      imageUrl: widget.person.imageUrl,
                      title: widget.person.name,
                    ),
                  ),
                );
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      widget.person.imageUrl,
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
                          color: Colors.blue.shade50,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Color(0xFF0D47A1)),
                              SizedBox(height: 8),
                              Text('Image not available', style: TextStyle(color: Color(0xFF0D47A1))),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.zoom_in,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported, size: 48, color: Color(0xFF0D47A1)),
                  SizedBox(height: 8),
                  Text('No image available', style: TextStyle(color: Color(0xFF0D47A1))),
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
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D47A1), Colors.blue.shade100],
            stops: [0.0, 50],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('Name', widget.person.name),
                      _buildInfoRow('Case ID', widget.person.caseId),
                      _buildInfoRow('Description', widget.person.descriptions),
                      _buildInfoRow('Address', widget.person.address),
                      _buildInfoRow('Last Seen At', widget.person.placeLastSeen),
                      _buildInfoRow('Last Seen Date', widget.person.datetimeLastSeen),
                      _buildInfoRow('Date Reported', widget.person.datetimeReported),
                      _buildInfoRow('Complainant', widget.person.complainant),
                      _buildInfoRow('Relationship', widget.person.relationship),
                      _buildInfoRow('Contact', widget.person.contactNo),
                      if (widget.person.additionalInfo.isNotEmpty)
                        _buildInfoRow('Additional Info', widget.person.additionalInfo),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 2,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildImage(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
