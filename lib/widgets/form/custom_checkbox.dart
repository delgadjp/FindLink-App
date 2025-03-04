import '/core/app_export.dart';

class CustomCheckbox extends StatelessWidget {
  final String label;
  final bool value;
  final Function(bool?) onChanged;

  const CustomCheckbox({
    Key? key,
    required this.label,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: 0.8, // Make checkbox smaller
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              visualDensity: VisualDensity.compact,
              activeColor: Colors.blue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.black),
          ),
        ],
      ),
    );
  }
}
