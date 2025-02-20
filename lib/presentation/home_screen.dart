import '../core/app_export.dart';
import '../widgets/grid_item.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(),
      drawer: AppDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 Header Image
            Image.asset(ImageConstant.pnp,
                height: 200, width: double.infinity, fit: BoxFit.cover),
            SizedBox(height: 20),

            // 🔹 Explore Section Title
            Text(
              "EXPLORE",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            // 🔹 GridView for Features // make it row
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                crossAxisCount: 4,
                children: [
                  GridItem(
                    icon: Icons.person_search,
                    label: "VIEW MISSING PERSON",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MissingPersonScreen()),
                      );
                    },
                  ),
                  GridItem(
                    icon: Icons.file_upload,
                    label: "FILL UP FILE",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => FillUpFormScreen()),
                      );
                    },
                  ),
                  GridItem(
                    icon: Icons.email,
                    label: "SUBMIT ANONYMOUS TIP",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SubmitTipScreen()),
                      );
                    },
                  ),
                  GridItem(
                    icon: Icons.track_changes,
                    label: "TRACK THE CASE",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TrackCaseScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            // 🔹 About Us Section (Added Below Grid)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("About Us",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Text(
                    "FINDLINK is a platform designed to assist the community in reporting missing persons and other suspicious activities.",
                    textAlign: TextAlign.justify,
                  ),
                  SizedBox(height: 6),
                  Image.asset(ImageConstant.aboutus, fit: BoxFit.cover),
                ],
              ),
            ),
          ],
        ),
      ),

      // 🔹 Floating Action Button for Chatbot
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatbotScreen()),
          );
        },
        child: Icon(Icons.chat),
        backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      ),
    );
  }
}
