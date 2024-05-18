import 'dart:io';
import 'package:blog/features/screens/profile/edit_profile.dart';
import 'package:blog/theme/app_pallete.dart';
import 'package:blog/utils/pick_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:blog/authentication.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';

class MyProfilePage extends StatefulWidget {
  final AuthenticationBloc authBloc;
  const MyProfilePage({Key? key, required this.authBloc}) : super(key: key);

  @override
  State<MyProfilePage> createState() => _MyProfilePageState();
}

class _MyProfilePageState extends State<MyProfilePage> {
  File? _image;
  String profilePicUrl = 'https://www.w3schools.com/howto/img_avatar.png';
  String username = '';
  String email = '';
  String gender = '';
  String dob = '';

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
  }

  void _fetchUserDetails() async {
    final user = await widget.authBloc.getUserDetails();
    setState(() {
      username = user['username'];
      email = user['email'];
      gender = user['gender'] ?? 'N/A';
      profilePicUrl = user['avatar'] ?? profilePicUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditProfilePage(authBloc: widget.authBloc),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              _buildProfileImage(),
              const SizedBox(height: 20),
              _buildProfileDetail('Username', username),
              _buildProfileDetail('Email', email),
              _buildProfileDetail('Gender', gender),
              GestureDetector(
                onTap: () async {
                  await AuthenticationBloc().signOut();
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (route) => false);
                },
                child: Card(
                  color: Colors.red,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: ListTile(
                    title: GestureDetector(
                      child: const Text(
                        "Logout",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    trailing: const Icon(Icons.logout, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _image != null
          ? FloatingActionButton(
              onPressed: _saveImage,
              tooltip: 'Save Image',
              child: const Icon(Icons.save),
            )
          : null,
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: 60,
        backgroundImage: _image != null
            ? FileImage(_image!)
            : NetworkImage(profilePicUrl) as ImageProvider,
        child: Align(
          alignment: Alignment.bottomRight,
          child: CircleAvatar(
            backgroundColor: Colors.white,
            radius: 18,
            child: Icon(
              Icons.camera_alt,
              size: 18,
              color: Colors.grey[800],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDetail(String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value),
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

  void _saveImage() async {
    if (_image != null) {
      final user = await widget.authBloc.getUserDetails();

      if (user['avatar'] != null && user['avatar'].isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(user['avatar']).delete();
          print('Old image deleted');
        } catch (e) {
          print('Error deleting old image: $e');
        }
      }

      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures/${DateTime.now()}.png');

      try {
        await ref.putFile(_image!);
        final imageUrl = await ref.getDownloadURL();
        final fetchedUser = await FirebaseFirestore.instance
            .collection('users')
            .where('user_id', isEqualTo: user['user_id'])
            .get();
        final docId = fetchedUser.docs[0].id;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(docId)
            .update({'avatar': imageUrl});

        setState(() {
          profilePicUrl = imageUrl;
          _image = null; // Clear the picked image
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture saved successfully.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Failed to save profile picture. Please try again later.')),
        );
      }
    }
  }
}
