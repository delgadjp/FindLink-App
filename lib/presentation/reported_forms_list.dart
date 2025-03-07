import 'package:flutter/material.dart';
import '../core/app_export.dart';
import 'track_case_screen.dart';

class ReportedFormsList extends StatefulWidget {
  @override
  _ReportedFormsListState createState() => _ReportedFormsListState();

  // Sample data for all cases - in a real app this would come from a database
  final List<Map<String, dynamic>> allCaseData = [
    {
      'caseNumber': '001',
      'name': 'John Smith',
      'dateCreated': '2023-10-15',
      'status': 'In Progress',
      'description': 'Missing since October 10, 2023',
      'location': 'Manila City',
      'type': 'Missing Person',
      'assignedTo': 'Det. Maria Santos'
    },
    {
      'caseNumber': '002',
      'name': 'Maria Garcia',
      'dateCreated': '2023-09-22',
      'status': 'Under Investigation',
      'description': 'Missing since September 15, 2023',
      'location': 'Quezon City',
      'type': 'Missing Person',
      'assignedTo': 'Det. John Doe'
    },
    {
      'caseNumber': '003',
      'name': 'David Lee',
      'dateCreated': '2023-11-05',
      'status': 'Reported',
      'description': 'Missing since November 1, 2023',
      'location': 'Makati City',
      'type': 'Missing Person',
      'assignedTo': 'Pending Assignment'
    }
  ];
}

class _ReportedFormsListState extends State<ReportedFormsList> {
  String _selectedFilter = 'All';
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20),
      itemCount: widget.allCaseData.length,
      itemBuilder: (context, index) {
        final caseData = widget.allCaseData[index];
        return _buildCaseCard(context, caseData);
      },
    );
  }

  Widget _buildCaseCard(BuildContext context, Map<String, dynamic> caseData) {
    Color statusColor;
    IconData statusIcon;
    
    switch (caseData['status']) {
      case 'In Progress':
        statusColor = Colors.orange;
        statusIcon = Icons.loop;
        break;
      case 'Under Investigation':
        statusColor = Colors.blue;
        statusIcon = Icons.search;
        break;
      case 'Resolved':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.report_problem;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TrackCaseScreen(caseData: caseData),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Case #${caseData['caseNumber']}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        SizedBox(width: 4),
                        Text(
                          caseData['status']!,
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                caseData['name']!,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                caseData['description']!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    caseData['location']!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    "Reported on: ${caseData['dateCreated']}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, size: 16, color: Colors.blue.shade900),
                      SizedBox(width: 4),
                      Text(
                        caseData['assignedTo']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "Track Case >",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue.shade900,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void showFilterOptions(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Filter Reports'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('All Reports'),
              onTap: () => Navigator.pop(context, 'All'),
            ),
            ListTile(
              title: Text('In Progress'),
              onTap: () => Navigator.pop(context, 'In Progress'),
            ),
            ListTile(
              title: Text('Under Investigation'),
              onTap: () => Navigator.pop(context, 'Under Investigation'),
            ),
            ListTile(
              title: Text('Resolved'),
              onTap: () => Navigator.pop(context, 'Resolved'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      );
    },
  );
}
