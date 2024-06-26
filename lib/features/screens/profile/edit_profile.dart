// ignore_for_file: use_build_context_synchronously

import 'package:blog/authentication.dart';
import 'package:blog/widgets/text_filed.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  final AuthenticationBloc authBloc;
  const EditProfilePage({super.key, required this.authBloc});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  DateTime? selectedDate;
  String? selectedGender;

  @override
  void initState() {
    super.initState();
    _initializeUserDetails();
  }

  Future<void> _initializeUserDetails() async {
    final user = await widget.authBloc.getUserDetails();
    setState(() {
      nameController.text = user['username'] ?? '';
      selectedDate = (user['dob'] as Timestamp?)?.toDate();
      selectedGender = user['gender'];
    });
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final name = nameController.text;
    final updatedProfile = await widget.authBloc.updateUserDetails(
      name: name,
      dob: selectedDate!,
      gender: selectedGender!,
    );

    final snackBar = SnackBar(
      content: Text(updatedProfile
          ? 'Profile updated successfully'
          : 'Failed to update profile'),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);

    if (updatedProfile) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveProfile,
        child: const Icon(Icons.save),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildProfileTextField(
                    'Name', 'Please enter your name', nameController),
                const SizedBox(height: 10),
                _buildDatePickerTile(context),
                const SizedBox(height: 10),
                _buildGenderDropdown(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTextField(
      String label, String hint, TextEditingController controller) {
    return BlogEditor(
      hintText: hint,
      controller: controller,
      labelText: label,
    );
  }

  Widget _buildDatePickerTile(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(
          selectedDate == null
              ? 'Date of Birth'
              : 'Date of Birth: ${_formatDate(selectedDate!)}',
        ),
        trailing: const Icon(Icons.calendar_today),
        onTap: () => _selectDate(context),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
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
    );
  }
}
