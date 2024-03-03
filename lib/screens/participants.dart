import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ParticipantsScreen extends StatelessWidget {
  final String eventId;

  const ParticipantsScreen({Key? key, required this.eventId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uczestnicy wydarzenia',
            style: TextStyle(color: Color.fromARGB(255, 255, 115, 35))),
        backgroundColor: Color.fromARGB(255, 27, 27, 27),
      ),
      body: Container(
        color: Color.fromARGB(255, 41, 41, 41),
        child: StreamBuilder(
          stream: FirebaseFirestore.instance
              .collection('event_info')
              .doc(eventId)
              .snapshots(),
          builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final eventInfo = snapshot.data!.data() as Map<String, dynamic>;
            final participantIds =
                List<String>.from(eventInfo['Participant IDs'] ?? []);

            return FutureBuilder(
              future: _fetchParticipantsData(participantIds),
              builder: (context,
                  AsyncSnapshot<List<Map<String, dynamic>>>
                      participantsSnapshot) {
                if (!participantsSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final participants = participantsSnapshot.data;

                return ListView.builder(
                  itemCount: participants!.length,
                  itemBuilder: (context, index) {
                    final participantData = participants[index];
                    final participantName = participantData['Imie'];
                    final participantLastName = participantData['Nazwisko'];
                    final participantImageUrl = participantData['Image_url'];

                    return Column(
                      children: [
                        ListTile(
                          leading: InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    _buildImageDialog(participantImageUrl),
                              );
                            },
                            child: CircleAvatar(
                              backgroundImage:
                                  NetworkImage(participantImageUrl),
                            ),
                          ),
                          title: Text('$participantName $participantLastName'),
                        ),
                        const Divider(
                          color: Colors.black,
                          thickness: 1.0,
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _fetchParticipantsData(
      List<String> participantIds) async {
    List<Map<String, dynamic>> participants = [];

    for (var userId in participantIds) {
      var userSnapshot = await FirebaseFirestore.instance
          .collection('users_profile_info')
          .doc(userId)
          .get();

      if (userSnapshot.exists) {
        var userData = userSnapshot.data() as Map<String, dynamic>;
        var userName = userData['Imie'];
        var userLastName = userData['Nazwisko'];
        var userImageUrl = userData['Image_url'];

        participants.add({
          'Imie': userName,
          'Nazwisko': userLastName,
          'Image_url': userImageUrl,
        });
      }
    }

    return participants;
  }

  Widget _buildImageDialog(String imageUrl) {
    return AlertDialog(
      content: Container(
        width: 300.0,
        height: 300.0,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
