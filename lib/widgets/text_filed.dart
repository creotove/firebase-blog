import 'package:flutter/material.dart';

class BlogEditor extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final String labelText;
  const BlogEditor({
    super.key,
    required this.controller,
    required this.hintText,
    required this.labelText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 60,
          child: TextFormField(
              maxLines: null,
              controller: controller,
              validator: (value) =>
                  value!.isEmpty ? 'Please enter $hintText' : null,
              decoration: InputDecoration(
                labelText: labelText,
                hintText: hintText,
              )),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
