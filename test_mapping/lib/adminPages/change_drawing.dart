import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeDrawing extends StatefulWidget {
  const ChangeDrawing({super.key, required this.logOutFunction, required this.refreshTokenFunction});

  final Function logOutFunction;
  final Function refreshTokenFunction;

  @override
  State<ChangeDrawing> createState() => _ChangeDrawingState();
}

class _ChangeDrawingState extends State<ChangeDrawing> {
  File? _selectedImage;
  ImageSource? _lastImageSource;


  Future<void> _pickImage(ImageSource source) async {
    _lastImageSource = source;
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      _showImagePreview(File(pickedFile.path));
    }
  }

  Future<void> _pickFile() async {
    _lastImageSource = null;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.image
      );
    if (result != null && result.files.single.path != null) {
      _showImagePreview(File(result.files.single.path!));
    }
  }

  Future<void> saveImagePath(File image) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("saved_image", image.path);
  }

  void _showImagePreview(File image) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Preview Image"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.file(image, width: 500, height: 500, fit: BoxFit.cover),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() => _selectedImage = null);
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (_lastImageSource != null) {
                  _pickImage(_lastImageSource!);
                } else {
                  _pickFile();
                }
              },
              child: Text("Retry"),
            ),
            TextButton(
              onPressed: () {
                setState(() => _selectedImage = image);
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme
            .of(context)
            .colorScheme
            .inversePrimary,
        title: Text("Change Drawing"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Adds some padding
        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,
          // Aligns content to the top-left
          children: <Widget>[
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              // Center-aligns buttons
              children: [
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.camera),
                  child: Row(
                    children: [
                      Text("Take Photo",style: TextStyle(fontSize: 16, color: Colors.white),),
                      SizedBox(width: 5),
                      Icon(Icons.camera_alt, color: Colors.white,)
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    backgroundColor: Colors.blue,
                  ),
                  
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () => _pickImage(ImageSource.gallery),
                  child: Row(
                    children: [
                      Text("Choose from Gallery",style: TextStyle(fontSize: 16, color: Colors.white),),
                      SizedBox(width: 5),
                      Icon(Icons.photo_library_rounded, color: Colors.white,)
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    backgroundColor: Colors.blue,
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _pickFile,
                  child: Row(
                    children: [
                      Text("Choose from Files",style: TextStyle(fontSize: 16, color: Colors.white),),
                      SizedBox(width: 5),
                      Icon(Icons.file_present_rounded, color: Colors.white,)
                    ],
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20), // Adds spacing before the image
            if (_selectedImage != null)
              Center( // Centers the image
                child: Column(
                  children: [
                    Image.file(
                      _selectedImage!,
                      width: 500,
                      height: 500,
                      fit: BoxFit.cover,
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(

                      onPressed: () async {
                        if (_selectedImage != null) {
                          await saveImagePath(_selectedImage!);
                          Navigator.pushNamed(context, "/homePage");
                        }
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Save",style: TextStyle(fontSize: 16, color: Colors.white),),
                          SizedBox(height: 5),
                          Icon(Icons.save,color: Colors.white,)
                        ],
                      ),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        backgroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
