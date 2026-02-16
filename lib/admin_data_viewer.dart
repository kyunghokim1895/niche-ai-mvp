import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDataViewer extends StatelessWidget {
  const AdminDataViewer({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin: Data Viewer'),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('synthetic_conversations')
            .orderBy('created_at', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No data found yet.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final userP = data['user_persona'] ?? 'Unknown User';
              final adminP = data['admin_persona'] ?? 'Unknown Admin';
              final goal = data['goal'] ?? 'No Goal';
              final conversation = data['conversation'] as List<dynamic>? ?? [];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getColorForPersona(userP),
                    child: Text(userP.substring(0, 1)),
                  ),
                  title: Text('$userP vs $adminP', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Goal: $goal | Turns: ${conversation.length}'),
                  children: [
                    Container(
                      height: 300,
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.grey[100],
                      child: ListView.builder(
                        itemCount: conversation.length,
                        itemBuilder: (context, chatIndex) {
                          final chat = conversation[chatIndex] as Map<String, dynamic>;
                          final sender = chat['sender'];
                          final text = chat['text'];
                          final isUser = sender == 'user';

                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isUser ? Colors.blue[100] : Colors.grey[200], // Softer white
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[400]!),
                              ),
                              width: MediaQuery.of(context).size.width * 0.7,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sender.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isUser ? Colors.blue[900] : Colors.green[900],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    text,
                                    style: const TextStyle(
                                      color: Colors.black87, // High contrast text
                                      fontSize: 15,
                                      height: 1.4, // Better line spacing
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
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

  Color _getColorForPersona(String type) {
    switch (type) {
      case 'INTJ': return Colors.purple;
      case 'ENFP': return Colors.orange;
      case 'ISTJ': return Colors.blueGrey;
      case 'INFP': return Colors.green;
      case 'ESTP': return Colors.red;
      default: return Colors.grey;
    }
  }
}
