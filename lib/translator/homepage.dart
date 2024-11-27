import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ocr_extra/translator/displaypicturescreen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:velocity_x/velocity_x.dart';
import 'camera_screen.dart';

class ScanImagePage extends StatelessWidget {
  const ScanImagePage({Key? key}) : super(key: key);

  Future<void> _requestCameraPermission(BuildContext context) async {
    final status = await Permission.camera.request();

    if (status.isGranted) {
      // Initialize the camera and navigate to the camera screen
      final cameras = await availableCameras();
      final firstCamera = cameras.first;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraScreen(camera: firstCamera),
        ),
      );
    } else if (status.isDenied) {
      // Permission is denied by the user, show a dialog or message
      _showPermissionDeniedDialog(context);
    } else if (status.isPermanentlyDenied) {
      // Permission is permanently denied, open app settings
      await openAppSettings();
    }
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permission Denied"),
        content: const Text(
            "Camera permission is required to scan images. Please enable it in the settings."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    final ImagePicker _picker = ImagePicker();
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (kDebugMode) {
        print("Photo picked: ${pickedFile.path}");
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              DisplayPictureScreen(imagePath: pickedFile.path),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(

        children: [
          240.heightBox,
          Semantics(
            label:"Take Picture or Pick image from gallery for scan and translate." ,
            child: "Take Picture or Pick image from gallery for scan and translate."
                .text
                .gray600
                .semiBold
                .lg
                .make(),
          ),
              16.heightBox,
          Semantics(
            label: "Please note that the translation function is still under development, so it may not be able to translate all languages or all types of text.",
            child: "Please note that the translation function is still under development, so it may not be able to translate all languages or all types of text."
                .text
                .red400
                .make(),
          ),
          24.heightBox,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Semantics(
                label: "Click here to take picture",
                child: CustomButton(
                  onPressed: () => _requestCameraPermission(context),
                  icon: Iconsax.camera,
                  title: "Take picture",
                ),
              ),
              24.widthBox,
              Semantics(
                label: "Click here to go gallery",
                child: CustomButton(
                  onPressed: () => _pickImageFromGallery(context),
                  icon: Iconsax.gallery,
                  title: 'Gallery',
                ),
              )
            ],
          ),
        ],
      ).pOnly(left: 20,right: 20),
    );
  }
}

class CustomButton extends StatelessWidget {
  const CustomButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.title,
  });
  final VoidCallback onPressed;
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 64,
          color: Vx.white,
        ),
        2.heightBox,
        title.text.bold.white.lg.make()
      ],
    )
        .p12()
        .box
        .width(120)
        .gray900
        .rounded
        .make()
        .centered()
        .onTap(() => onPressed());
  }
}
