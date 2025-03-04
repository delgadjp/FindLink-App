import '/core/app_export.dart';
class SectionTitle extends StatelessWidget {
  final String title;
  final Color backgroundColor;

  const SectionTitle({
    Key? key,
    required this.title,
    required this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      padding: EdgeInsets.all(8),
      width: double.infinity,
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}
