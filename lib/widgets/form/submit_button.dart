import '/core/app_export.dart';

class SubmitButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final VoidCallback? onPressed;
  final bool isLoading;

  const SubmitButton({
    Key? key, 
    required this.formKey, 
    this.onPressed,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF1E215A),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: isLoading ? null : onPressed ?? () {
          if (formKey.currentState?.validate() ?? false) {
            // Proceed with form submission
          }
        },
        child: isLoading 
          ? CircularProgressIndicator(color: Colors.white)
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send),
                SizedBox(width: 8),
                Text(
                  'Submit Form',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
      ),
    );
  }
}
