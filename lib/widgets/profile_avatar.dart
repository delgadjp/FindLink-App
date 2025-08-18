import '/core/app_export.dart';

class ProfileAvatar extends StatelessWidget {
  final VoidCallback? onEditPressed;
  final String? imageUrl;
  final double radius;
  final bool isLoading;

  const ProfileAvatar({
    this.onEditPressed, 
    this.imageUrl, 
    this.radius = 50, 
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white,
              width: 3.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: isLoading 
              ? CircleAvatar(
                  radius: radius,
                  backgroundColor: const Color.fromARGB(255, 131, 131, 131),
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.0,
                  ),
                )
              : CircleAvatar(
                  radius: radius,
                  backgroundColor: const Color.fromARGB(255, 131, 131, 131),
                  backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                      ? NetworkImage(imageUrl!) as ImageProvider
                      : AssetImage(ImageConstant.profile),
                  onBackgroundImageError: (exception, stackTrace) {
                    print("Error loading profile image: $exception");
                    // We can't update the widget directly here as this is not a stateful widget,
                    // but we can at least show the error in console
                  },
                ),
        ),
        if (onEditPressed != null && !isLoading)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade900,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: IconButton(
                icon: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                onPressed: onEditPressed,
                constraints: BoxConstraints.tightFor(width: 36, height: 36),
                padding: EdgeInsets.zero,
              ),
            ),
          ),
      ],
    );
  }
}