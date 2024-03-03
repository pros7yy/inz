// ignore_for_file: sized_box_for_whitespace, prefer_const_constructors, deprecated_member_use, avoid_print, library_private_types_in_public_api, use_key_in_widget_constructors

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _tempImage;
  final _auth = FirebaseAuth.instance;
  var _enteredFirstName = '';
  var _enteredLastName = '';
  final _formKey = GlobalKey<FormState>();
  Image? _userImage;

  @override
  void initState() {
    super.initState();
    _fetchUserProfileImage();
  }

  Future<void> _fetchUserProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    final storageRef = FirebaseStorage.instance
        .ref()
        .child('user_images')
        .child('${user.uid}.jpg');

    try {
      final url = await storageRef.getDownloadURL();
      setState(() {
        _userImage = Image.network(url);
      });
    } catch (e) {
      print('Błąd podczas pobierania zdjęcia użytkownika: $e');
    }
  }

  void _onPickImage(File pickedImage) {
    setState(() {
      _tempImage = pickedImage;
    });
  }

  Future<void> _updateProfileInfo() async {
    final isValid = _formKey.currentState?.validate();
    if (!isValid!) {
      return;
    }

    _formKey.currentState?.save();

    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    await user.updateProfile(
      displayName: '$_enteredFirstName $_enteredLastName',
    );

    if (_tempImage != null) {
      setState(() {
        _userImage = Image.file(_tempImage!);
      });

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_images')
          .child('${user.uid}.jpg');

      await storageRef.putFile(_tempImage!);
      final imageURL = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users_profile_info')
          .doc(user.uid)
          .set({
        'Image_url': imageURL,
        'Email': user.email,
        'Imie': _enteredFirstName,
        'Nazwisko': _enteredLastName,
      });
    } else {
      await FirebaseFirestore.instance
          .collection('users_profile_info')
          .doc(user.uid)
          .update({
        'Imie': _enteredFirstName,
        'Nazwisko': _enteredLastName,
      });
    }

    _fetchUserProfileImage();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Twój profil',
            style: TextStyle(color: Color.fromARGB(255, 255, 115, 35))),
        backgroundColor: Color.fromARGB(255, 27, 27, 27),
      ),
      body: Center(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () {
                  final imagePicker = ImagePicker();
                  imagePicker
                      .pickImage(source: ImageSource.gallery)
                      .then((pickedFile) {
                    if (pickedFile != null) {
                      _onPickImage(File(pickedFile.path));
                    }
                  });
                },
                customBorder: CircleBorder(),
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _tempImage != null
                      ? FileImage(_tempImage!)
                      : _userImage != null
                          ? _userImage!.image
                          : const AssetImage('assets/images/placeholder.png'),
                ),
              ),
              SizedBox(height: 20),
              Container(
                width: 350,
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Imię',
                  ),
                  initialValue: user?.displayName?.split(" ").first ?? '',
                  onSaved: (value) {
                    _enteredFirstName = value!;
                  },
                ),
              ),
              Container(
                width: 350,
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nazwisko',
                  ),
                  initialValue: user?.displayName?.split(" ").last ?? '',
                  onSaved: (value) {
                    _enteredLastName = value!;
                  },
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _updateProfileInfo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 27, 27, 27),
                ),
                child: const Text('Zapisz',
                    style: TextStyle(color: Color.fromARGB(255, 255, 115, 35))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
