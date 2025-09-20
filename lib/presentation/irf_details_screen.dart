import '/core/app_export.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IRFDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> caseData;

  const IRFDetailsScreen({
    Key? key,
    required this.caseData,
  }) : super(key: key);

  @override
  _IRFDetailsScreenState createState() => _IRFDetailsScreenState();
}

class _IRFDetailsScreenState extends State<IRFDetailsScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final rawData = widget.caseData['rawData'] as Map<String, dynamic>? ?? {};
    final incidentDetails = rawData['incidentDetails'] as Map<String, dynamic>? ?? {};
    final itemA = rawData['itemA'] as Map<String, dynamic>? ?? {};
    final itemC = rawData['itemC'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'IRF Details',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF1565C0),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          // Print/Export button (for future implementation)
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Export feature coming soon')),
              );
            },
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
                  colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card with Case Information
                      _buildHeaderCard(),
                      SizedBox(height: 16),
                      
                      // Incident Details Section
                      _buildIncidentDetailsSection(incidentDetails),
                      SizedBox(height: 16),
                      
                      // Reporting Person Section (Item A)
                      _buildReportingPersonSection(itemA),
                      SizedBox(height: 16),
                      
                      // Missing Person Section (Item C)
                      _buildMissingPersonSection(itemC),
                      SizedBox(height: 16),
                      
                      // Case Status and History Section
                      _buildCaseStatusSection(),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF8F9FA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF1565C0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.description,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Incident Report Form',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1565C0),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Case ID: ${widget.caseData['caseId'] ?? 'N/A'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor(widget.caseData['status']).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getStatusColor(widget.caseData['status']),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(widget.caseData['status']),
                    color: _getStatusColor(widget.caseData['status']),
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Text(
                    widget.caseData['status'] ?? 'Unknown',
                    style: TextStyle(
                      color: _getStatusColor(widget.caseData['status']),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentDetailsSection(Map<String, dynamic> incidentDetails) {
    return _buildSectionCard(
      title: 'Incident Details',
      icon: Icons.event_note,
      children: [
        _buildDetailRow('Type of Incident', incidentDetails['typeOfIncident'] ?? 'N/A'),
        _buildDetailRow('Date & Time of Incident', _formatDateTime(incidentDetails['dateTimeOfIncident'])),
        _buildDetailRow('Place of Incident', incidentDetails['placeOfIncident'] ?? 'N/A'),
        _buildDetailRow('Date Reported', _formatDateTime(incidentDetails['reportedAt'])),
        if (incidentDetails['narrative'] != null && incidentDetails['narrative'].toString().isNotEmpty)
          _buildNarrativeRow('Narrative', incidentDetails['narrative']),
        if (incidentDetails['imageUrl'] != null && incidentDetails['imageUrl'].toString().isNotEmpty)
          _buildImageRow('Attached Image', incidentDetails['imageUrl']),
      ],
    );
  }

  Widget _buildReportingPersonSection(Map<String, dynamic> itemA) {
    return _buildSectionCard(
      title: 'Reporting Person Information',
      icon: Icons.person,
      children: [
        _buildDetailRow('Full Name', _buildFullName(itemA)),
        _buildDetailRow('Nickname', itemA['nickname'] ?? 'N/A'),
        _buildDetailRow('Age', '${itemA['age'] ?? 'N/A'}'),
        _buildDetailRow('Date of Birth', itemA['dateOfBirth'] ?? 'N/A'),
        _buildDetailRow('Sex/Gender', itemA['sexGender'] ?? 'N/A'),
        _buildDetailRow('Civil Status', itemA['civilStatus'] ?? 'N/A'),
        _buildDetailRow('Citizenship', itemA['citizenship'] ?? 'N/A'),
        _buildDetailRow('Place of Birth', itemA['placeOfBirth'] ?? 'N/A'),
        _buildDetailRow('Education', itemA['education'] ?? 'N/A'),
        _buildDetailRow('Occupation', itemA['occupation'] ?? 'N/A'),
        _buildDetailRow('Mobile Phone', itemA['mobilePhone'] ?? 'N/A'),
        _buildDetailRow('Home Phone', itemA['homePhone'] ?? 'N/A'),
        _buildDetailRow('Email', itemA['email'] ?? 'N/A'),
        _buildDetailRow('Current Address', _buildFullAddress(itemA)),
        if (itemA['otherAddress'] != null && itemA['otherAddress'].toString().isNotEmpty)
          _buildDetailRow('Other Address', _buildOtherAddress(itemA)),
        _buildDetailRow('ID Card Presented', itemA['idCard'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildMissingPersonSection(Map<String, dynamic> itemC) {
    return _buildSectionCard(
      title: 'Missing Person Information',
      icon: Icons.person_search,
      children: [
        _buildDetailRow('Full Name', _buildFullName(itemC)),
        _buildDetailRow('Nickname', itemC['nickname'] ?? 'N/A'),
        _buildDetailRow('Age', '${itemC['age'] ?? 'N/A'}'),
        _buildDetailRow('Date of Birth', itemC['dateOfBirth'] ?? 'N/A'),
        _buildDetailRow('Sex/Gender', itemC['sexGender'] ?? 'N/A'),
        _buildDetailRow('Civil Status', itemC['civilStatus'] ?? 'N/A'),
        _buildDetailRow('Citizenship', itemC['citizenship'] ?? 'N/A'),
        _buildDetailRow('Place of Birth', itemC['placeOfBirth'] ?? 'N/A'),
        _buildDetailRow('Education', itemC['education'] ?? 'N/A'),
        _buildDetailRow('Occupation', itemC['occupation'] ?? 'N/A'),
        _buildDetailRow('Mobile Phone', itemC['mobilePhone'] ?? 'N/A'),
        _buildDetailRow('Home Phone', itemC['homePhone'] ?? 'N/A'),
        _buildDetailRow('Email', itemC['email'] ?? 'N/A'),
        _buildDetailRow('Current Address', _buildFullAddress(itemC)),
        if (itemC['otherAddress'] != null && itemC['otherAddress'].toString().isNotEmpty)
          _buildDetailRow('Other Address', _buildOtherAddress(itemC)),
        if (itemC['idCard'] != null && itemC['idCard'].toString().isNotEmpty)
          _buildDetailRow('ID Card Information', itemC['idCard'] ?? 'N/A'),
      ],
    );
  }

  Widget _buildCaseStatusSection() {
    return _buildSectionCard(
      title: 'Case Information',
      icon: Icons.info,
      children: [
        _buildDetailRow('Case Type', widget.caseData['type'] ?? 'N/A'),
        _buildDetailRow('Current Status', widget.caseData['status'] ?? 'N/A'),
        _buildDetailRow('Date Created', widget.caseData['dateCreated'] ?? 'N/A'),
        _buildDetailRow('Last Updated', _formatDateTime(widget.caseData['rawData']['updatedAt'])),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF1565C0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Color(0xFF1565C0),
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ),
          Text(
            ': ',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrativeRow(String label, String narrative) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              narrative.isNotEmpty ? narrative : 'N/A',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageRow(String label, String imageUrl) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
          SizedBox(height: 8),
          GestureDetector(
            onTap: () => _showImageDialog(imageUrl),
            child: Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.grey[400], size: 40),
                          SizedBox(height: 8),
                          Text(
                            'Unable to load image',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap to view full image',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white, size: 30),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Flexible(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white,
                          padding: EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error, color: Colors.grey[400], size: 60),
                              SizedBox(height: 16),
                              Text(
                                'Unable to load image',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _buildFullName(Map<String, dynamic> data) {
    List<String> nameParts = [];
    
    if (data['firstName'] != null && data['firstName'].toString().isNotEmpty) {
      nameParts.add(data['firstName'].toString());
    }
    
    if (data['middleName'] != null && data['middleName'].toString().isNotEmpty) {
      nameParts.add(data['middleName'].toString());
    }
    
    if (data['familyName'] != null && data['familyName'].toString().isNotEmpty) {
      nameParts.add(data['familyName'].toString());
    }
    
    if (data['qualifier'] != null && data['qualifier'].toString().isNotEmpty && data['qualifier'] != 'None') {
      nameParts.add(data['qualifier'].toString());
    }
    
    return nameParts.isNotEmpty ? nameParts.join(' ') : 'N/A';
  }

  String _buildFullAddress(Map<String, dynamic> data) {
    List<String> addressParts = [];
    
    if (data['currentAddress'] != null && data['currentAddress'].toString().isNotEmpty) {
      addressParts.add(data['currentAddress'].toString());
    }
    
    if (data['villageSitio'] != null && data['villageSitio'].toString().isNotEmpty) {
      addressParts.add(data['villageSitio'].toString());
    }
    
    if (data['barangay'] != null && data['barangay'].toString().isNotEmpty) {
      addressParts.add(data['barangay'].toString());
    }
    
    if (data['town'] != null && data['town'].toString().isNotEmpty) {
      addressParts.add(data['town'].toString());
    }
    
    if (data['province'] != null && data['province'].toString().isNotEmpty) {
      addressParts.add(data['province'].toString());
    }
    
    return addressParts.isNotEmpty ? addressParts.join(', ') : 'N/A';
  }

  String _buildOtherAddress(Map<String, dynamic> data) {
    List<String> addressParts = [];
    
    if (data['otherAddress'] != null && data['otherAddress'].toString().isNotEmpty) {
      addressParts.add(data['otherAddress'].toString());
    }
    
    if (data['otherVillage'] != null && data['otherVillage'].toString().isNotEmpty) {
      addressParts.add(data['otherVillage'].toString());
    }
    
    if (data['otherBarangay'] != null && data['otherBarangay'].toString().isNotEmpty) {
      addressParts.add(data['otherBarangay'].toString());
    }
    
    if (data['otherTownCity'] != null && data['otherTownCity'].toString().isNotEmpty) {
      addressParts.add(data['otherTownCity'].toString());
    }
    
    if (data['otherProvince'] != null && data['otherProvince'].toString().isNotEmpty) {
      addressParts.add(data['otherProvince'].toString());
    }
    
    return addressParts.isNotEmpty ? addressParts.join(', ') : 'N/A';
  }

  String _formatDateTime(dynamic dateTime) {
    if (dateTime == null) return 'N/A';
    
    try {
      DateTime dt;
      if (dateTime is Timestamp) {
        dt = dateTime.toDate();
      } else if (dateTime is Map && dateTime['seconds'] != null) {
        dt = DateTime.fromMillisecondsSinceEpoch(dateTime['seconds'] * 1000);
      } else if (dateTime is String) {
        dt = DateTime.parse(dateTime);
      } else if (dateTime is DateTime) {
        dt = dateTime;
      } else {
        return dateTime.toString();
      }
      
      return DateFormat('MMM dd, yyyy hh:mm a').format(dt);
    } catch (e) {
      return dateTime.toString();
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'reported':
        return Colors.blue;
      case 'under review':
        return Colors.orange;
      case 'case verified':
        return Colors.purple;
      case 'in progress':
        return Colors.amber;
      case 'evidence submitted':
        return Colors.indigo;
      case 'resolved case':
      case 'resolved':
        return Colors.green;
      case 'unresolved case':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'reported':
        return Icons.report;
      case 'under review':
        return Icons.visibility;
      case 'case verified':
        return Icons.verified;
      case 'in progress':
        return Icons.autorenew;
      case 'evidence submitted':
        return Icons.assignment_turned_in;
      case 'resolved case':
      case 'resolved':
        return Icons.check_circle;
      case 'unresolved case':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }
}