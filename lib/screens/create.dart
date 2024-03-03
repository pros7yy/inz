import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'choice.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({Key? key}) : super(key: key);

  @override
  _CreateScreenState createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> {
  File? _eventImage;
  final _auth = FirebaseAuth.instance;
  var _eventDate = '';
  var _eventDescription = '';
  var _eventCity = '';
  var _eventStreet = '';
  var _eventHour = '';
  var _selectedCategory;
  final _formKey = GlobalKey<FormState>();

  List<String> eventCategories = [
    'Koncerty',
    'Wyjście na drinka',
    'Sportowe',
    'Edukacyjne',
    'Sztuka i kultura',
    'Film i teatr',
    'Rekreacyjne',
    'Domówka',
    'E-sport',
    'Spotkania networkingowe',
    'Inne',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stwórz wydarzenie',
            style: TextStyle(color: Color.fromARGB(255, 255, 115, 35))),
        backgroundColor: Color.fromARGB(255, 27, 27, 27),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: InkWell(
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
                      customBorder: const CircleBorder(),
                      child: ClipOval(
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: _eventImage != null
                              ? Image.memory(
                                  Uint8List.fromList(
                                      _eventImage!.readAsBytesSync()),
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                )
                              : Image.asset(
                                  'assets/images/placeholder2.png',
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 350,
                    margin: const EdgeInsets.only(top: 20),
                    child: DropdownButtonFormField(
                      value: _selectedCategory,
                      items: [
                        for (String category in eventCategories)
                          DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Wybierz kategorię';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Kategoria wydarzenia',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: 350,
                    margin: const EdgeInsets.only(top: 5),
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Opis wydarzenia',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'To pole jest wymagane';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _eventDescription = value!;
                      },
                    ),
                  ),
                  Container(
                    width: 350,
                    margin: const EdgeInsets.only(top: 10),
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Miasto',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'To pole jest wymagane';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _eventCity = value!;
                      },
                    ),
                  ),
                  Container(
                    width: 350,
                    margin: const EdgeInsets.only(top: 10),
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Ulica (opcjonalne)',
                      ),
                      onSaved: (value) {
                        _eventStreet = value!;
                      },
                    ),
                  ),
                  Container(
                    width: 350,
                    margin: const EdgeInsets.only(top: 10),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Data wydarzenia',
                        hintText: 'DD/MM/RRRR',
                        errorStyle: TextStyle(color: Colors.red),
                      ),
                      validator: validateDate,
                      onSaved: (value) {
                        _eventDate = value!;
                      },
                    ),
                  ),
                  Container(
                    width: 350,
                    margin: const EdgeInsets.only(top: 10),
                    child: TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Godzina wydarzenia',
                        hintText: 'np. 20:00',
                        errorStyle: TextStyle(color: Colors.red),
                      ),
                      validator: validateTime,
                      onSaved: (value) {
                        _eventHour = value!;
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                      onPressed: _createEvent,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 27, 27, 27),
                      ),
                      child: const Text('Stwórz wydarzenie',
                          style: TextStyle(
                            color: Color.fromARGB(255, 255, 115, 35),
                          ))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _onPickImage(File pickedImage) {
    setState(() {
      _eventImage = pickedImage;
    });
  }

  Future<void> _createEvent() async {
    final isValid = _formKey.currentState?.validate();
    if (!isValid!) {
      return;
    }

    _formKey.currentState?.save();

    final user = _auth.currentUser;
    if (user == null) {
      return;
    }

    if (_eventImage != null) {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('events_images')
          .child(
              '${user.uid} + (${DateTime.now().toUtc().toIso8601String()}.jpg');

      await storageRef.putFile(_eventImage!);
      final imageURL = await storageRef.getDownloadURL();

      final eventRef =
          FirebaseFirestore.instance.collection('event_info').doc();
      final eventId = eventRef.id;

      await eventRef.set({
        'event_id': eventId,
        'image_url': imageURL,
        'Imię i Nazwisko twórcy': '${user.displayName}',
        'Opis wydarzenia': _eventDescription.toUpperCase(),
        'Data wydarzenia': _eventDate,
        'Miasto':
            _eventCity.substring(0, 1).toUpperCase() + _eventCity.substring(1),
        'Ulica': _eventStreet.isNotEmpty
            ? _eventStreet.substring(0, 1).toUpperCase() +
                _eventStreet.substring(1)
            : '',
        'Godzina wydarzenia': _eventHour,
        'Kategoria wydarzenia': _selectedCategory,
        'Id twórcy': user.uid,
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ChoiceScreen()),
      );
    }
  }

  String? validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'To pole jest wymagane';
    }

    final validCharacters = RegExp(r'^\d{2}\.\d{2}.\d{4}$');
    if (!validCharacters.hasMatch(value)) {
      return 'Nieprawidłowy format daty (DD/MM/RRRR)';
    }

    List<String> dateParts = value.split('.');
    int day = int.tryParse(dateParts[0]) ?? 0;
    int month = int.tryParse(dateParts[1]) ?? 0;
    int year = int.tryParse(dateParts[2]) ?? 0;

    if (day < 1 || day > 31 || month < 1 || month > 12 || year < 1900) {
      return 'Nieprawidłowa data';
    }

    DateTime parsedDate = DateTime(year, month, day);

    if (parsedDate.isBefore(DateTime.now().subtract(Duration(days: 1)))) {
      return 'Podana data jest przeszła';
    }

    return null;
  }

  String? validateTime(String? value) {
    if (value == null || value.isEmpty) {
      return 'To pole jest wymagane';
    }
    final validCharacters = RegExp(r'^\d{2}:\d{2}$');
    if (!validCharacters.hasMatch(value)) {
      return 'Nieprawidłowy format godziny (np. 20:00)';
    }
    return null;
  }
}
