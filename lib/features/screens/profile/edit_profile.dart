import 'package:blog/authentication.dart';
import 'package:blog/widgets/text_filed.dart';
import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  final AuthenticationBloc authBloc;
  const EditProfilePage({Key? key, required this.authBloc}) : super(key: key);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  TextEditingController nameController = TextEditingController();
  DateTime? selectedDate;
  String? selectedGender;
  final _formkey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (!_formkey.currentState!.validate()) {
            return;
          }
          final name = nameController.text;
          final updatedProfile = await widget.authBloc.updateUserDetails(
            name: name,
            dob: selectedDate as DateTime,
            gender: selectedGender as String,
          );
          if (updatedProfile) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully'),
              ),
            );
            Navigator.pop(context);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update profile'),
              ),
            );
            // Navigator.pop(context);
          }
        },
        child: const Icon(Icons.save),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formkey,
            child: Column(
              children: [
                BlogEditor(
                  hintText: 'Please enter your name',
                  controller: nameController,
                  labelText: 'Name',
                ),
                SizedBox(height: 10),
                // Date of Birth picker
                ListTile(
                  title: Text(
                    selectedDate == null
                        ? 'Date of Birth'
                        : 'Date of Birth: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                  ),
                  onTap: () => _selectDate(context),
                ),
                SizedBox(height: 10),
                // Gender dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    border: OutlineInputBorder(),
                  ),
                  value: selectedGender,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedGender = newValue;
                    });
                  },
                  items: <String>['Male', 'Female', 'Other']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
