import '../core/app_export.dart';
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
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 15,
                height: 1.3,
              ),
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
                      width: double.infinity,
                      height: 300,
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

  Widget _buildStatusChip() {
    final status = widget.person.status.isNotEmpty ? widget.person.status : 'UNRESOLVED';
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'resolved':
        bgColor = Colors.green.shade100;
        textColor = Colors.green.shade900;
        break;
      case 'pending':
        bgColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        break;
      default:
        bgColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      backgroundColor: bgColor,
      padding: EdgeInsets.symmetric(horizontal: 8),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Case Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _buildStatusChip(),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D47A1), Colors.blue.shade100],
            stops: [0.0, 0.5],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.only(top: AppBar().preferredSize.height + MediaQuery.of(context).padding.top + 16, left: 16, right: 16, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Card (now at the top)
              Hero(
                tag: 'missing_person_image_${widget.person.caseId}',
                child: Card(
                  elevation: 8,
                  shadowColor: Colors.black.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: _buildImage(),
                  ),
                ),
              ),
              
              SizedBox(height: 16),
                // Merged person name and info card
              Card(
                elevation: 6,
                shadowColor: Colors.black.withOpacity(0.2),
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Person name and case ID
                      Text(
                        widget.person.name,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1),
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: 6),
                      
                      SizedBox(height: 24),
                      
                      // Case information section
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Color(0xFF0D47A1)),
                          SizedBox(width: 10),
                          Text(
                            'Case Information',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Divider(thickness: 2, color: Colors.blue.shade100, height: 24),
                      SizedBox(height: 8),
                      _buildInfoRow('Description', widget.person.descriptions),
                      _buildInfoRow('Address', widget.person.address),
                      _buildInfoRow('Last Seen At', widget.person.placeLastSeen),
                      _buildInfoRow('Last Seen Date', widget.person.datetimeLastSeen),
                      _buildInfoRow('Date Reported', widget.person.datetimeReported),
                      
                      SizedBox(height: 20),
                      Row(
                        children: [
                          Icon(Icons.contact_phone_outlined, color: Color(0xFF0D47A1)),
                          SizedBox(width: 10),
                          Text(
                            'Contact Information',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Divider(thickness: 2, color: Colors.blue.shade100, height: 24),
                      SizedBox(height: 8),
                      _buildInfoRow('Complainant', widget.person.complainant),
                      _buildInfoRow('Relationship', widget.person.relationship),
                      _buildInfoRow('Contact', widget.person.contactNo),
                      
                      if (widget.person.additionalInfo.isNotEmpty) ...[
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Icon(Icons.notes_outlined, color: Color(0xFF0D47A1)),
                            SizedBox(width: 10),
                            Text(
                              'Additional Information',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0D47A1),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Divider(thickness: 2, color: Colors.blue.shade100, height: 24),
                        SizedBox(height: 8),
                        _buildInfoRow('Notes', widget.person.additionalInfo),
                      ],
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Action button with improved styling
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.4),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  icon: Icon(Icons.tips_and_updates, size: 24),
                  label: Text(
                    'Report a Sighting',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SubmitTipScreen(person: widget.person),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
