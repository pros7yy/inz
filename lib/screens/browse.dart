// ignore_for_file: sort_child_properties_last

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:projekt_inz/screens/participants.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({Key? key}) : super(key: key);

  @override
  _BrowseScreenState createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  TextEditingController _locationController = TextEditingController();
  String? _searchLocation;
  String? _selectedCategory;
  bool _isSearchButtonPressed = false;

  Future<bool> _checkUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null &&
        user.displayName != null &&
        user.displayName!.trim().isNotEmpty &&
        user.displayName!.trim().contains(" ")) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> _showProfileErrorDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Brak uzupełnionego profilu'),
          content: const Text(
              'Aby dodać wydarzenie do Twoich Wydarzeń, uzupełnij swoje dane w profilu.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> checkAndDeleteOutdatedEvents() async {
    DateTime currentDateTimeWarsaw =
        DateTime.now().toUtc().add(const Duration(hours: 1));

    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('event_info').get();

    for (QueryDocumentSnapshot eventSnapshot in querySnapshot.docs) {
      Map<String, dynamic> event = eventSnapshot.data() as Map<String, dynamic>;

      String date = event['Data wydarzenia'];
      String time = event['Godzina wydarzenia'];
      DateTime eventDateTime = parseDateTime(date, time);

      if (currentDateTimeWarsaw
          .isAfter(eventDateTime.add(Duration(minutes: 1)))) {
        await FirebaseFirestore.instance
            .collection('event_info')
            .doc(eventSnapshot.id)
            .delete();
      }
    }
  }

  DateTime parseDateTime(String dateString, String timeString) {
    try {
      DateFormat dateFormat = DateFormat("dd.MM.yyyy HH:mm");
      DateTime parsedDateTime = dateFormat.parse("$dateString $timeString");
      return parsedDateTime;
    } catch (e) {
      DateFormat dateFormat = DateFormat("yyyy-MM-dd HH:mm");
      return dateFormat.parse("$dateString $timeString");
    }
  }

  Future<void> addToEvents(Map<String, dynamic> event) async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return;
    }

    String userId = user.uid;

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('user_events')
        .doc(userId)
        .collection('events')
        .where('Opis wydarzenia', isEqualTo: event['Opis wydarzenia'])
        .where('Imię i Nazwisko twórcy',
            isEqualTo: event['Imię i Nazwisko twórcy'])
        .where('Miasto', isEqualTo: event['Miasto'])
        .where('Ulica', isEqualTo: event['Ulica'])
        .where('Data wydarzenia', isEqualTo: event['Data wydarzenia'])
        .where('Godzina wydarzenia', isEqualTo: event['Godzina wydarzenia'])
        .where('image_url', isEqualTo: event['image_url'])
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Komunikat'),
            content: Text('To wydarzenie zostało już dodane.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      await FirebaseFirestore.instance
          .collection('user_events')
          .doc(userId)
          .collection('events')
          .add(event);
    }
  }

  Future<void> _navigateToAddEvent(
      BuildContext context, Map<String, dynamic> event) async {
    final hasUserProfile = await _checkUserProfile();
    if (hasUserProfile) {
      await addToEvents(event);
    } else {
      _showProfileErrorDialog(context);
    }
  }

  Future<void> _onSlideActionTap(
      BuildContext context, String eventId, Map<String, dynamic> event) async {
    final hasUserProfile = await _checkUserProfile();
    if (hasUserProfile) {
      User? user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        List<String> participantIds = List.from(event['Participant IDs'] ?? []);

        if (!participantIds.contains(user.uid)) {
          participantIds.add(user.uid);
        }

        await FirebaseFirestore.instance
            .collection('event_info')
            .doc(eventId)
            .update({'Participant IDs': participantIds});

        await _navigateToAddEvent(context, event);
      }
    } else {
      _showProfileErrorDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    checkAndDeleteOutdatedEvents();
    List<String> availableCategories = [
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Przeglądaj wydarzenia',
            style: TextStyle(color: Color.fromARGB(255, 255, 115, 35))),
        backgroundColor: Color.fromARGB(255, 27, 27, 27),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 55.0,
                      child: TextField(
                        controller: _locationController,
                        onChanged: (value) {
                          setState(() {
                            _searchLocation =
                                value.isNotEmpty ? value.toLowerCase() : null;
                          });
                        },
                        onTap: () {
                          setState(() {
                            if (_locationController.text.isEmpty) {
                              _searchLocation = null;
                            }
                            _isSearchButtonPressed = true;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: _searchLocation == null ||
                                  _searchLocation!.isEmpty
                              ? 'Wpisz lokalizację'
                              : '',
                          labelStyle: TextStyle(
                            color: Colors.grey,
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: _searchLocation == null ||
                                      _searchLocation!.isEmpty
                                  ? Colors.grey
                                  : Colors.grey,
                            ),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: _searchLocation == null ||
                                      _searchLocation!.isEmpty
                                  ? Colors.grey
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Container(
                    height: 55.0,
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      items: [
                        DropdownMenuItem(
                          value: 'Wszystkie',
                          child: Text('Wszystkie'),
                        ),
                        for (String category in availableCategories)
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
                      hint: Text(
                        'Wybierz kategorię',
                      ),
                    ),
                  ),
                ],
              ),
            ),
            StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('event_info')
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Text('Ładowanie...');
                }

                final events = snapshot.data!.docs;
                final currentUser = FirebaseAuth.instance.currentUser;

                events.sort((a, b) {
                  final creatorA = a['Id twórcy'];
                  final creatorB = b['Id twórcy'];

                  if (currentUser != null) {
                    if (creatorA == currentUser.uid) {
                      return -1;
                    } else if (creatorB == currentUser.uid) {
                      return 1;
                    }
                  }

                  return 0;
                });

                final filteredEvents = events.where((event) {
                  final location = event['Miasto'].toString().toLowerCase() +
                      ' ' +
                      event['Ulica'].toString().toLowerCase();
                  return (_selectedCategory == 'Wszystkie' ||
                      (location.contains(_searchLocation ?? '') &&
                          (event['Kategoria wydarzenia'] == _selectedCategory ||
                              _selectedCategory == null)));
                }).toList();

                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event =
                        filteredEvents[index].data() as Map<String, dynamic>;
                    final eventId = filteredEvents[index].id;
                    final isCurrentUserEvent =
                        event['Id twórcy'] == currentUser?.uid;
                    return Slidable(
                      actionPane: SlidableDrawerActionPane(),
                      actionExtentRatio: 0.25,
                      child: Card(
                        child: Column(
                          children: [
                            Stack(
                              alignment: Alignment.topLeft,
                              children: [
                                SizedBox(
                                  height: 510.0,
                                  child: Image.network(
                                    event['image_url'],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (currentUser != null &&
                                          event['Id twórcy'] == currentUser.uid)
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color.fromARGB(255, 41, 41,
                                                41), // ciemnoszare tło
                                          ),
                                          child: IconButton(
                                            icon: Icon(Icons.delete),
                                            color: Color.fromARGB(
                                                255, 255, 35, 35),
                                            onPressed: () async {
                                              await FirebaseFirestore.instance
                                                  .collection('event_info')
                                                  .doc(eventId)
                                                  .delete();
                                            },
                                          ),
                                        ),
                                      GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ParticipantsScreen(
                                                eventId: eventId,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          width: 50, // szerokość okręgu
                                          height: 50, // wysokość okręgu
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color.fromARGB(255, 41, 41,
                                                41), // ciemnoszare tło
                                          ),
                                          child: Icon(
                                            Icons.people,
                                            color: Color.fromARGB(
                                                255, 255, 115, 35),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            ListTile(
                              title: Text(event['Opis wydarzenia']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Data i Godzina: ${event['Data wydarzenia']} ${event['Godzina wydarzenia']}',
                                  ),
                                  if (event['Miasto'] != null &&
                                      event['Ulica'] != null)
                                    Text(
                                      'Lokalizacja: ${event['Miasto']} ${event['Ulica']}',
                                    ),
                                  if (event['Imię i Nazwisko twórcy'] != null)
                                    Text(
                                      'Autor: ${event['Imię i Nazwisko twórcy']}',
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      secondaryActions: [
                        IconSlideAction(
                          color: Color.fromARGB(255, 255, 115, 35),
                          icon: Icons.check,
                          onTap: () async {
                            await _onSlideActionTap(context, eventId, event);
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
