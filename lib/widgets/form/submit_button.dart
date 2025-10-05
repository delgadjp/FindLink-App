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
          // Disable the button when loading
          disabledBackgroundColor: Color(0xFF1E215A).withOpacity(0.6),
        ),
        onPressed: isLoading
            ? null
            : onPressed ??
                () {
                  if (formKey.currentState?.validate() ?? false) {
                    // Proceed with form submission
                  }
                },
        child: isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'SUBMIT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
