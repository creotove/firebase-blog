// ignore_for_file: avoid_print, library_private_types_in_public_api, use_build_context_synchronously, use_rethrow_when_possible

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
  String? _imageUrl;
  bool _isLoading = false;

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
          _imageUrl = blogSnapshot['image_url'];
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
        automaticallyImplyLeading: false,
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
              _image != null
                  ? SizedBox(
                      height: 150,
                      child: Image.file(_image!, fit: BoxFit.cover),
                    )
                  : _imageUrl != null
                      ? SizedBox(
                          height: 150,
                          child: Image.network(_imageUrl!, fit: BoxFit.cover),
                        )
                      : const Text('No image selected'),
              const SizedBox(height: 16.0),
              GradientButton(buttonText: 'Change Image', onPressed: _pickImage),
              const SizedBox(height: 16.0),
              _isLoading
                  ? const CircularProgressIndicator()
                  : GradientButton(
                      buttonText: 'Update Blog',
                      onPressed: () {
                        _updateBlog(_imageUrl);
                      })
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

  Future<void> _updateBlog(String? previousImageUrl) async {
    try {
      setState(() {
        _isLoading = true;
      });
      final String title = _titleController.text.trim();
      final String content = _contentController.text.trim();
      if (title.isNotEmpty && content.isNotEmpty) {
        String? imageUrl;

        if (_image != null) {
          await FirebaseStorage.instance.refFromURL(previousImageUrl!).delete();

          // Upload new image to Firebase Storage
          Reference ref = FirebaseStorage.instance.ref().child(
              'blog_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
          UploadTask uploadTask = ref.putFile(_image!);
          TaskSnapshot taskSnapshot = await uploadTask.whenComplete(() => null);
          imageUrl = await taskSnapshot.ref.getDownloadURL();
        } else {
          // If no new image is selected, keep the previous image URL
          imageUrl = _imageUrl;
        }

        // Create a map with updated data
        Map<String, dynamic> updatedData = {
          'title': title,
          'content': content,
          'updated_at': DateTime.now(),
        };

        // Add image_url to updated data if an image was selected
        if (imageUrl != null) {
          updatedData['image_url'] = imageUrl;
        }

        // Update blog data in Firestore
        await FirebaseFirestore.instance
            .collection('blogs')
            .doc(widget.blogId)
            .update(updatedData);

        // Navigate back to the previous screen
        Navigator.pop(context);
      } else {
        // Show error if any of the required fields are empty
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: const Text('Please fill in all fields.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print(e);
      throw e;
    } finally {
      setState(() {
        _isLoading = false;
      });
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
}
