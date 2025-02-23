import '../core/app_export.dart';

class MissingPersonScreen extends StatefulWidget {
  @override
  _MissingPersonScreenState createState() => _MissingPersonScreenState();
}

class _MissingPersonScreenState extends State<MissingPersonScreen> {
  final List<Map<String, String>> reports = [
    {
      'organization': 'Philippine National Police',
      'image': ImageConstant.investigation,
      'description': '"Help us find the missing person in Bicol"',
      'date': '01.01.2001',
      'profile': ImageConstant.logoPNP
    },
    {
      'organization': 'PNP Juan Dela Cruz',
      'image': ImageConstant.pic,
      'description': '"Help us find the missing person in Bicol"',
      'date': '01.01.2001',
      'profile': ImageConstant.icon
    }
  ];

  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          "Missing Persons",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF0D47A1),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              // Show filter options
            },
          ),
        ],
      ),
      drawer: AppDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          // Implement refresh logic
        },
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              color: Color(0xFF0D47A1),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search missing persons...',
                  hintStyle: TextStyle(color: Colors.white70),
                  prefixIcon: Icon(Icons.search, color: Colors.white70),
                  filled: true,
                  fillColor: Colors.white24,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Recent Cases',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () {
                      // Show all cases
                    },
                    child: Text('See All'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  if (searchQuery.isEmpty || 
                      report['description']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
                      report['organization']!.toLowerCase().contains(searchQuery.toLowerCase())) {
                    return MissingPersonCard(report: report);
                  }
                  return SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add new missing person report
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
