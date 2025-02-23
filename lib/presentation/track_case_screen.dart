import '../core/app_export.dart';

class TrackCaseScreen extends StatelessWidget {
  final List<Map<String, String>> statusStages = [
    {'stage': 'Reported', 'status': 'Completed'},
    {'stage': 'Under Investigation', 'status': 'In Progress'},
    {'stage': 'Assigned Authorities', 'status': 'Pending'},
    {'stage': 'Resolved', 'status': 'Pending'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Track Case", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Color(0xFF0D47A1),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: Row(
                // You can add items to the Row here if needed
                ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Case Information Card
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Case #12345",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Reported on: 15 March 2024",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
              
              // Status Timeline Section
              Text(
                "Case Progress",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D47A1),
                ),
              ),
              SizedBox(height: 16),
              
              // Timeline Visualization
              Container(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: statusStages.length,
                  itemBuilder: (context, index) {
                    final stage = statusStages[index];
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
              
              // Latest Update Card
              Card(
                elevation: 2,
                margin: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Latest Update",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Investigation in progress by Officer John Doe",
                        style: TextStyle(fontSize: 14),
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
            ],
          ),
        ),
      ),
    );
  }
}
