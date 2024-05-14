// import 'dart:io';

// import 'package:blog/utils/pick_image.dart';
// import 'package:flutter/material.dart';
// import 'package:blog/authentication.dart';
// import 'package:firebase_storage/firebase_storage.dart';

// class ProfilePage extends StatefulWidget {
//   final AuthenticationBloc authBloc;
//   const ProfilePage({super.key, required this.authBloc});

//   @override
//   State<ProfilePage> createState() => _ProfilePageState();
// }

// class _ProfilePageState extends State<ProfilePage> {
//   File? _image;
//   String profilePicUrl = 'https://www.w3schools.com/howto/img_avatar.png';
//   String username = '';
//   String email = '';
//   String gender = '';
//   DateTime dob = DateTime.now();
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Profile'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Center(
//               child: CircleAvatar(
//                 radius: 60,
//                 backgroundImage: NetworkImage(profilePicUrl),
//               ),
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Username: $username',
//               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               'Email: $email',
//               style: TextStyle(fontSize: 18),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               'Gender: $gender',
//               style: TextStyle(fontSize: 18),
//             ),
//             const SizedBox(height: 10),
//             Text(
//               'Date of Birth: ${dob.day}/${dob.month}/${dob.year}',
//               style: TextStyle(fontSize: 18),
//             ),
//             // Add more user data fields as needed
//           ],
//         ),
//       ),
//     );
//   }

//   void _pickImage() async {
//     final pickedImage = await pickImage();
//     if (pickedImage != null) {
//       setState(() {
//         _image = pickedImage;
//       });
//     }
//   }
// }

import 'dart:io';
import 'package:blog/features/screens/profile/edit_profile.dart';
import 'package:blog/utils/pick_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:blog/authentication.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfilePage extends StatefulWidget {
  final AuthenticationBloc authBloc;
  const ProfilePage({Key? key, required this.authBloc}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  File? _image;
  String profilePicUrl = 'https://www.w3schools.com/howto/img_avatar.png';
  String username = '';
  String email = '';
  String gender = '';
  // DateTime dob = DateTime.now();
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
      if (user['avatar'] != null) {
        profilePicUrl = user['avatar'];
      } else {
        print('No image');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      EditProfilePage(authBloc: widget.authBloc),
                ),
              );
            },
            icon: const Icon(Icons.edit),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_image != null)
              GestureDetector(
                onTap: _pickImage,
                child: Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: FileImage(_image!),
                  ),
                ),
              )
            else
              GestureDetector(
                onTap: _pickImage,
                child: Center(
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: NetworkImage(profilePicUrl),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              'Username: $username',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Email: $email',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Text(
              'Gender: $gender',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            // Text(
            //   'Date of Birth: ${dob.day}/${dob.month}/${dob.year}',
            //   style: const TextStyle(fontSize: 18),
            // ),
          ],
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

      final Reference ref = FirebaseStorage.instance
          .ref()
          .child('profile_pictures/${DateTime.now()}.png');

      try {
        await ref.putFile(_image!);
        final String imageUrl = await ref.getDownloadURL();
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
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Profile picture saved successfully.')));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Failed to save profile picture. Please try again later.')));
      }
    }
  }
}
