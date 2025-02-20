import '../core/app_export.dart';

class ProfileAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 50,
      backgroundColor: const Color.fromARGB(255, 131, 131, 131),
      backgroundImage: AssetImage(ImageConstant.profile),
    );
  }
}