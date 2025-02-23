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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "View Missing Person",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Color(0xFF0D47A1),
      ),
      drawer: AppDrawer(),
      body: Padding(
        padding: EdgeInsets.all(10.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: reports.length,
                itemBuilder: (context, index) {
                  final report = reports[index];
                  return MissingPersonCard(report: report);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
