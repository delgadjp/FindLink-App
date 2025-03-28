import '../core/app_export.dart';


class AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        color: Color(0xFF0D47A1),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Color(0xFF0D47A1),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 500,
                        height: 500,
                        child: Image.asset(
                          ImageConstant.logoFinal,
                        ),
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
                  ListTile(
                    leading: Icon(Icons.person, color: Colors.white),
                    title: Text('Profile', style: TextStyle(color: Colors.white)),
                    onTap: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => ProfileScreen())
                      );
                    },
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ListTile(
                leading: Icon(Icons.logout, color: Colors.white),
                title: Text('Sign Out', style: TextStyle(color: Colors.white)),
                onTap: () {
                  AuthService().signOutUser(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
