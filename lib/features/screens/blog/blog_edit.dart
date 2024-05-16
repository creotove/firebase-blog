// ignore_for_file: avoid_print

import 'dart:io';

import 'package:blog/authentication.dart';
import 'package:blog/widgets/gradient_button.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

class BlogEditPage extends StatefulWidget {
  final AuthenticationBloc authBloc;
  final String blogId;

  const BlogEditPage({
    super.key,
    required this.authBloc,
    required this.blogId,
  });

  @override
  _BlogEditPageState createState() => _BlogEditPageState();
}

class _BlogEditPageState extends State<BlogEditPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  File? _image;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
    _fetchBlogDetails();
  }

  void _fetchBlogDetails() async {
    try {
      final blogSnapshot = await FirebaseFirestore.instance
          .collection('blogs')
          .doc(widget.blogId)
          .get();

      if (blogSnapshot.exists) {
        setState(() {
          _titleController.text = blogSnapshot['title'];
          _contentController.text = blogSnapshot['content'];
        });
      }
    } catch (e) {
      print('Error fetching blog details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Blog'),
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
                  : Container(
                      height: 150,
                      child: Image.file(_image!, fit: BoxFit.cover),
                    ),
              const SizedBox(height: 16.0),
              GradientButton(buttonText: 'Update Blog', onPressed: _updateBlog)
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

  Future<void> _updateBlog() async {
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

      // Update blog data in Firestore
      await FirebaseFirestore.instance
          .collection('blogs')
          .doc(widget.blogId)
          .update({
        'title': title,
        'content': content,
        'image_url': imageUrl,
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
