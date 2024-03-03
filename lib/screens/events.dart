import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventsScreen extends StatelessWidget {
  final String userId;

  const EventsScreen({Key? key, required this.userId}) : super(key: key);

  Future<void> removeFromUserEvents(String eventId) async {
    await FirebaseFirestore.instance
        .collection('user_events')
        .doc(userId)
        .collection('events')
        .doc(eventId)
        .delete();
  }

  Future<String> getEventId(String eventDocId) async {
    DocumentSnapshot eventDoc = await FirebaseFirestore.instance
        .collection('user_events')
        .doc(userId)
        .collection('events')
        .doc(eventDocId)
        .get();

    return eventDoc['event_id'];
  }

  Future<bool> checkUserProfileInfo(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users_profile_info')
        .doc(userId)
        .get();

    // Sprawdź, czy Imię i Nazwisko są uzupełnione
    return userDoc['Imie'] != null &&
        userDoc['Nazwisko'] != null &&
        userDoc['Imie'].trim().isNotEmpty &&
        userDoc['Nazwisko'].trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Twoje wydarzenia',
            style: TextStyle(color: Color.fromARGB(255, 255, 115, 35))),
        backgroundColor: Color.fromARGB(255, 27, 27, 27),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('user_events')
            .doc(userId)
            .collection('events')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Text('Ładowanie...');
          }

          final userEvents = snapshot.data!.docs;
          return ListView.builder(
            itemCount: userEvents.length,
            itemBuilder: (context, index) {
              final eventDetails =
                  userEvents[index].data() as Map<String, dynamic>;
              final eventId = userEvents[index].id;

              return Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.delete),
                            color: Color.fromARGB(255, 255, 115, 35),
                            onPressed: () async {
                              await removeFromUserEvents(eventId);
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.chat),
                            color: Color.fromARGB(255, 255, 115, 35),
                            onPressed: () async {
                              // Pobierz event_id z bazy danych
                              String eventDocId = userEvents[index].id;
                              String eventId = await getEventId(eventDocId);

                              // Sprawdź, czy użytkownik ma uzupełnione dane profilowe
                              bool hasProfileInfo =
                                  await checkUserProfileInfo(userId);

                              if (hasProfileInfo) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatScreen(
                                      eventId: eventId,
                                      userId: userId,
                                    ),
                                  ),
                                );
                              } else {
                                // Wyświetl komunikat o błędzie
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: Text('Błąd'),
                                      content: Text(
                                          'Aby dołączyć do czatu, uzupełnij swoje dane profilowe.'),
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
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (eventDetails['image_url'] != null)
                          Container(
                            height: 150,
                            width: 150,
                            child: Image.network(
                              eventDetails['image_url'],
                              fit: BoxFit.scaleDown,
                            ),
                          ),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  eventDetails['Opis wydarzenia'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Data i godzina: ${eventDetails['Data wydarzenia']} ${eventDetails['Godzina wydarzenia']}',
                                ),
                                if (eventDetails['Miasto'] != null &&
                                    eventDetails['Ulica'] != null)
                                  Text(
                                    'Lokalizacja: ${eventDetails['Miasto']} ${eventDetails['Ulica']}',
                                  ),
                                if (eventDetails['Imię i Nazwisko twórcy'] !=
                                    null)
                                  Text(
                                    'Autor: ${eventDetails['Imię i Nazwisko twórcy']}',
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String eventId;
  final String userId;

  const ChatScreen({Key? key, required this.eventId, required this.userId})
      : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class UserNameWidget extends StatelessWidget {
  final String userName;
  final String imageUrl;

  const UserNameWidget(
      {Key? key, required this.userName, required this.imageUrl})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              // Handle image tap here, for example, show the full-resolution image
              _showFullResolutionImage(context, imageUrl);
            },
            child: CircleAvatar(
              backgroundImage: NetworkImage(imageUrl),
              radius: 20,
            ),
          ),
          SizedBox(width: 8),
          Text(
            '$userName',
            style: TextStyle(
              fontSize: 11.0,
            ),
          ),
        ],
      ),
    );
  }

  void _showFullResolutionImage(BuildContext context, String imageUrl) {
    // Implement logic to show the full-resolution image here
    // For example, you can use a dialog or navigate to a new screen
    // with the full-resolution image.
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
          ),
        );
      },
    );
  }
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  Map<String, Map<String, String>> _userNames = {};
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    if (_currentUser != null) {
      _fetchUserName(_currentUser!.uid);
    }
  }

  Future<void> _fetchUserName(String userId) async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users_profile_info')
        .doc(userId)
        .get();

    Map<String, String> userData = {
      'userName': '${userDoc['Imie']} ${userDoc['Nazwisko']}',
      'imageUrl': userDoc['Image_url'],
    };

    setState(() {
      _userNames[userId] = userData;
    });
  }

  Future<void> sendMessage(String message) async {
    if (_currentUser != null) {
      await FirebaseFirestore.instance
          .collection('event_chats')
          .doc(widget.eventId)
          .collection('messages')
          .add({
        'userId': _currentUser?.uid,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Czat',
            style: TextStyle(color: Color.fromARGB(255, 255, 115, 35))),
        backgroundColor: Color.fromARGB(255, 27, 27, 27),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('event_chats')
                  .doc(widget.eventId)
                  .collection('messages')
                  .orderBy('timestamp')
                  .snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: Text('Ładowanie...'));
                }

                final messages = snapshot.data!.docs;
                return ListView.builder(
                  reverse: false,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final messageData =
                        messages[index].data() as Map<String, dynamic>;
                    final message = messageData['message'];
                    final userId = messageData['userId'];

                    String userName = _getUserName(userId);
                    bool isCurrentUser = userId == _currentUser?.uid;

                    return Align(
                      alignment: isCurrentUser
                          ? Alignment.topRight
                          : Alignment.topLeft,
                      child: Container(
                        margin: const EdgeInsets.all(4.0),
                        child: Card(
                          color: isCurrentUser
                              ? Color.fromARGB(255, 32, 32, 34)
                              : null,
                          elevation: 2.0,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                UserNameWidget(
                                  userName: userName,
                                  imageUrl: _getUserImageUrl(userId),
                                ),
                                Text(
                                  message,
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    color: isCurrentUser ? Colors.white : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Napisz wiadomość...',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send),
                  color: Color.fromARGB(255, 255, 115, 35),
                  onPressed: () {
                    final message = _messageController.text;
                    if (message.isNotEmpty) {
                      sendMessage(message);
                      _messageController.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getUserName(String userId) {
    if (_userNames.containsKey(userId)) {
      return _userNames[userId]?['userName'] ?? '';
    } else {
      _fetchUserName(userId);
      return '';
    }
  }

  String _getUserImageUrl(String userId) {
    if (_userNames.containsKey(userId)) {
      return _userNames[userId]?['imageUrl'] ?? '';
    } else {
      _fetchUserName(userId);
      return '';
    }
  }
}
