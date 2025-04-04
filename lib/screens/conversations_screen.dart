// lib/screens/conversations_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/chat_service.dart';
import '../models/conversation_model.dart';
import 'chat_screen.dart';
import 'package:intl/intl.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({Key? key}) : super(key: key);

  @override
  _ConversationsScreenState createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ChatService _chatService = ChatService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getUserConversations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text('Erreur: ${snapshot.error}'),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('Aucune conversation'),
            );
          }
          
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              ConversationModel conversation = ConversationModel.fromFirestore(
                snapshot.data!.docs[index],
              );
              
              return FutureBuilder<DocumentSnapshot>(
                future: _getOtherUserData(conversation.participants),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(
                      leading: CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      title: Text('Chargement...'),
                    );
                  }
                  
                  Map<String, dynamic> userData = 
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userData['photoUrl'] != null
                          ? NetworkImage(userData['photoUrl'])
                          : null,
                      child: userData['photoUrl'] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(userData['fullName'] ?? 'Utilisateur'),
                    subtitle: conversation.lastMessage != null
                        ? Text(
                            conversation.lastMessage!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : const Text('Aucun message'),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (conversation.lastMessageTime != null)
                          Text(
                            _formatDate(conversation.lastMessageTime!),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        const SizedBox(height: 4),
                        FutureBuilder<int>(
                          future: _getUnreadCount(conversation.id),
                          builder: (context, countSnapshot) {
                            if (!countSnapshot.hasData || countSnapshot.data == 0) {
                              return const SizedBox.shrink();
                            }
                            
                            return Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                countSnapshot.data.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            conversationId: conversation.id,
                            otherUserName: userData['fullName'] ?? 'Utilisateur',
                            otherUserPhoto: userData['photoUrl'],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showNewConversationDialog(context);
        },
        child: const Icon(Icons.add),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
  
  Future<DocumentSnapshot> _getOtherUserData(List<String> participants) async {
    String currentUserId = _chatService._auth.currentUser!.uid;
    String otherUserId = participants.firstWhere((id) => id != currentUserId);
    
    return await _firestore.collection('users').doc(otherUserId).get();
  }
  
  Future<int> _getUnreadCount(String conversationId) async {
    QuerySnapshot unreadMessages = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('read', isEqualTo: false)
        .where('senderId', isNotEqualTo: _chatService._auth.currentUser!.uid)
        .get();
    
    return unreadMessages.size;
  }
  
  String _formatDate(DateTime date) {
    DateTime now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return DateFormat.Hm().format(date);
    } else if (date.day == now.day - 1 && date.month == now.month && date.year == now.year) {
      return 'Hier';
    } else {
      return DateFormat.yMd().format(date);
    }
  }
  
  void _showNewConversationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle conversation'),
        content: FutureBuilder<QuerySnapshot>(
          future: _firestore.collection('users').get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            
            List<DocumentSnapshot> users = snapshot.data!.docs
                .where((doc) => doc.id != _chatService._auth.currentUser!.uid)
                .toList();
            
            return SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  Map<String, dynamic> userData = 
                      users[index].data() as Map<String, dynamic>;
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: userData['photoUrl'] != null
                          ? NetworkImage(userData['photoUrl'])
                          : null,
                      child: userData['photoUrl'] == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(userData['fullName'] ?? 'Utilisateur'),
                    subtitle: Text(userData['role'] == 'provider' || userData['role'] == 'UserRole.provider'
                        ? 'Prestataire'
                        : 'Client'),
                    onTap: () async {
                      Navigator.pop(context);
                      
                      String conversationId = await _chatService.createConversation(
                        users[index].id,
                      );
                      
                      if (!mounted) return;
                      
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            conversationId: conversationId,
                            otherUserName: userData['fullName'] ?? 'Utilisateur',
                            otherUserPhoto: userData['photoUrl'],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
}