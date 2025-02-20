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
      body: Padding(
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: [
            Text(
              "Process Status",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: statusStages
                  .asMap()
                  .map((index, stage) {
                    Color color;
                    if (stage['status'] == 'Completed') {
                      color = Colors.green;
                    } else if (stage['status'] == 'In Progress') {
                      color = Colors.orange;
                    } else {
                      color = Colors.grey;
                    }

                    return MapEntry(
                      index,
                      Column(
                        children: [
                          Text(
                            stage['stage']!,
                            style: TextStyle(color: color, fontSize: 12),
                          ),
                          SizedBox(height: 5),
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: color,
                            child: Icon(
                              index < statusStages.length - 1
                                  ? Icons.arrow_forward
                                  : Icons.check,
                              color: Colors.white,
                              size: 15,
                            ),
                          ),
                        ],
                      ),
                    );
                  })
                  .values
                  .toList(),
            ),
            SizedBox(height: 20),
            LinearProgressIndicator(
              value: statusStages
                      .indexWhere((stage) => stage['status'] == 'In Progress') / 
                  (statusStages.length - 1),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 10),
            Text(
              "Current Status: ${statusStages.last['status']}",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
