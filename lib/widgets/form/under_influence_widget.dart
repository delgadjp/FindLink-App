import '/core/app_export.dart';
class UnderInfluenceCheckboxes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "UNDER THE INFLUENCE OF:",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        SizedBox(height: 10),
        Wrap(
          spacing: 20,
          runSpacing: 10,
          children: [
            _buildDisabledCheckbox("NO"),
            _buildDisabledCheckbox("DRUGS"),
            _buildDisabledCheckbox("LIQUOR"),
            _buildDisabledCheckbox("OTHERS"),
          ],
        ),
      ],
    );
  }

  Widget _buildDisabledCheckbox(String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          margin: EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}
