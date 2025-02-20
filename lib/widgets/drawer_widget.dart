import '../core/app_export.dart';
import '../presentation/home_screen.dart';

class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Color(0xFF0D47A1),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Color(0xFF0D47A1),
              ),
              child: Text(
                'Navigation Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home, color: Colors.white),
              title: Text('Home', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => HomeScreen())
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.search, color: Colors.white),
              title: Text('View Missing Person', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => MissingPersonScreen())
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.description, color: Colors.white),
              title: Text('Fill Up Form', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => FillUpFormScreen())
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
