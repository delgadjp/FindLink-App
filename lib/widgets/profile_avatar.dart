import '../core/app_export.dart';

class ProfileAvatar extends StatelessWidget {
  final VoidCallback? onEditPressed;
  final String? imageUrl;

  const ProfileAvatar({this.onEditPressed, this.imageUrl});

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
          child: CircleAvatar(
            radius: 50,
            backgroundColor: const Color.fromARGB(255, 131, 131, 131),
            backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                ? NetworkImage(imageUrl!) as ImageProvider
                : AssetImage(ImageConstant.profile),
          ),
        ),
        if (onEditPressed != null)
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