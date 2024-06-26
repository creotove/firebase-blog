// ignore_for_file: library_private_types_in_public_api, use_build_context_synchronously

import 'dart:io';

import 'package:blog/authentication.dart';
import 'package:blog/widgets/gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class AddBlogPage extends StatefulWidget {
  final AuthenticationBloc authBloc;

  const AddBlogPage({super.key, required this.authBloc});

  @override
  _AddBlogPageState createState() => _AddBlogPageState();
}

class _AddBlogPageState extends State<AddBlogPage> {
  final TextEditingController _titleController =
      TextEditingController(text: '');
  final TextEditingController _contentController =
      TextEditingController(text: '');
  File? _image;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Add New Blog'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Content'),
                maxLines: 5,
              ),
              const SizedBox(height: 16.0),
              _image == null
                  ? GradientButton(
                      buttonText: 'Pick Image', onPressed: _pickImage)
                  : SizedBox(
                      height: 150, // Set the height to fit under 150 pixels
                      child: Image.file(_image!, fit: BoxFit.cover),
                    ),
              const SizedBox(height: 16.0),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GradientButton(buttonText: 'Add Blog', onPressed: _addBlog),
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
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
    });
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
      final blog = await FirebaseFirestore.instance.collection('blogs').add({
        'title': title,
        'content': content,
        'image_url': imageUrl,
        'user_id': await widget.authBloc.getCurrentUserId(),
        'created_at': DateTime.now(),
        'updated_at': DateTime.now(),
        'username': await widget.authBloc.getCurrentUserName(),
      });

      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('user_id', isEqualTo: await widget.authBloc.getCurrentUserId())
          .get();

      // Assuming user_id is unique, there should be only one document in the query snapshot
      if (userQuery.docs.isNotEmpty) {
        final userDoc = userQuery.docs.first;
        // Update user document to add blogId
        await userDoc.reference.update({
          'blogs': FieldValue.arrayUnion([blog.id])
        });
      } else {
        // Handle case when user document doesn't exist (optional)
      }

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
