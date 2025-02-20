import '../core/app_export.dart';

class ReportedFormsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: 2,
      itemBuilder: (context, index) {
        return Card(
          color: const Color.fromARGB(255, 255, 255, 255),
          elevation: 5,
          shadowColor: const Color.fromARGB(255, 0, 0, 0),
          child: ListTile(
            leading: Image.asset(
              ImageConstant.pic, // Use local image
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
            title: Text(
              'MISSING: Juan Dela Cruz',
              style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)), // Changed color to black
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date Created: mm/dd/yyyy',
                  style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)), // Changed color to black
                ),
                Text(
                  'Date Case Closed: mm/dd/yyyy',
                  style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0)), // Changed color to black
                ),
                Row(
                  children: [
                    Chip(
                      label: Text(
                        'Pending',
                        style: TextStyle(color: Colors.black), // Changed color to black
                      ),
                      backgroundColor: const Color.fromARGB(255, 255, 232, 131),
                      shape: StadiumBorder(side: BorderSide.none),
                    ),
                    SizedBox(width: 10),
                    Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 235, 96, 96)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => TrackCaseScreen()),
                        );
                      },
                      child: Text('Track Case', style: TextStyle(color: const Color.fromARGB(255, 0, 0, 0))),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}