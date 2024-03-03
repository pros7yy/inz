// ignore_for_file: use_build_context_synchronously

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:projekt_inz/screens/auth.dart';
import 'package:projekt_inz/screens/browse.dart';
import 'package:projekt_inz/screens/create.dart';
import 'package:projekt_inz/screens/profile.dart';
import 'package:projekt_inz/screens/events.dart';

class ChoiceScreen extends StatelessWidget {
  const ChoiceScreen({
    Key? key,
  });

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

  Future<void> _navigateToCreateScreen(BuildContext context) async {
    final hasUserProfile = await _checkUserProfile();
    if (hasUserProfile) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CreateScreen(),
        ),
      );
    } else {
      _showProfileErrorDialog(context);
    }
  }

  void _showProfileErrorDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Brak uzupełnionego profilu'),
          content: const Text(
              'Aby stworzyć wydarzenie, uzupełnij swoje dane w profilu.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Link Us',
          style: TextStyle(
            color: Color.fromARGB(255, 255, 115, 35),
          ),
        ),
        backgroundColor: Color.fromARGB(255, 27, 27, 27),
        actions: [
          IconButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const AuthScreen()),
              );
            },
            icon: const Icon(
              Icons.exit_to_app,
              color: Color.fromARGB(255, 255, 115, 35),
            ),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 130,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BrowseScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 27, 27, 27),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                icon: const Icon(
                  Icons.search,
                  color: Color.fromARGB(255, 255, 115, 35),
                ),
                label: const Text(
                  'Przeglądaj wydarzenia',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 130,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToCreateScreen(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 27, 27, 27),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                icon: const Icon(
                  Icons.add,
                  color: Color.fromARGB(255, 255, 115, 35),
                ),
                label: const Text(
                  '  Stwórz wydarzenie   ',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 130,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EventsScreen(
                          userId: user.uid,
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color.fromARGB(255, 27, 27, 27),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                ),
                icon: const Icon(
                  Icons.event,
                  color: Color.fromARGB(255, 255, 115, 35),
                ),
                label: const Text(
                  '  Twoje wydarzenia   ',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Color.fromARGB(255, 27, 27, 27),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.person,
                color: Color.fromARGB(255, 255, 115, 35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
