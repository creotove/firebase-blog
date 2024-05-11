import 'dart:io';

import 'package:blog/authentication.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class AddBlogPage extends StatefulWidget {
  final AuthenticationBloc authBloc;

  const AddBlogPage({required this.authBloc});

  @override
  _AddBlogPageState createState() => _AddBlogPageState();
}

class _AddBlogPageState extends State<AddBlogPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  File? _image;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Blog'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _contentController,
                decoration: InputDecoration(labelText: 'Content'),
                maxLines: 5,
              ),
              const SizedBox(height: 16.0),
              _image == null
                  ? ElevatedButton(
                      onPressed: _pickImage,
                      child: const Text('Pick Image'),
                    )
                  : Container(
                      height: 150, // Set the height to fit under 150 pixels
                      child: Image.file(_image!, fit: BoxFit.cover),
                    ),
              const SizedBox(height: 16.0),
              ElevatedButton(
                onPressed: _addBlog,
                child: const Text('Add Blog'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickImage() async {
    final pickedImage = await pickImage();
    if (pickedImage != null) {
      setState(() {
        _image = pickedImage;
      });
    }
  }

  Future<void> _addBlog() async {
    final String title = _titleController.text.trim();
    final String content = _contentController.text.trim();
    if (title.isNotEmpty && content.isNotEmpty && _image != null) {
      // Upload image to Firebase Storage
      Reference ref = FirebaseStorage.instance
          .ref()
          .child('blog_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
      UploadTask uploadTask = ref.putFile(_image!);
      TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
      String imageUrl = await taskSnapshot.ref.getDownloadURL();

      // Add blog data to Firestore
      FirebaseFirestore.instance.collection('blogs').add({
        'title': title,
        'content': content,
        'image_url': imageUrl,
        'poster_id': await widget.authBloc
            .getCurrentUserId(), // Assuming you have a method to get the current user ID
        'created_at': DateTime.now(),
        'updated_at': DateTime.now(),
      });

      // Navigate back to previous screen
      Navigator.pop(context);
    } else {
      // Show error if any of the fields are empty
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Please fill in all fields and select an image.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

Future<File?> pickImage() async {
  try {
    final xFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (xFile != null) {
      return File(xFile.path);
    }
    return null;
  } catch (e) {
    return null;
  }
}
