// lib/screens/chat_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserName;
  final String? otherUserPhoto;
  
  const ChatScreen({
    Key? key,
    required this.conversationId,
    required this.otherUserName,
    this.otherUserPhoto,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isAttachmentMenuOpen = false;
  
  @override
  void initState() {
    super.initState();
    _markMessagesAsRead();
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _markMessagesAsRead() async {
    await _chatService.markMessagesAsRead(widget.conversationId);
  }
  
  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    _chatService.sendMessage(
      widget.conversationId,
      _messageController.text.trim(),
    );
    
    _messageController.clear();
    
    // Faire défiler vers le bas après l'envoi
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  Future<void> _pickImage() async {
    setState(() {
      _isAttachmentMenuOpen = false;
    });
    
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    
    if (image != null) {
      await _chatService.sendImage(
        widget.conversationId,
        File(image.path),
      );
    }
  }
  
  Future<void> _pickDocument() async {
    setState(() {
      _isAttachmentMenuOpen = false;
    });
    
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    
    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;
      
      await _chatService.sendDocument(
        widget.conversationId,
        file,
        fileName,
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.otherUserPhoto != null
                  ? NetworkImage(widget.otherUserPhoto!)
                  : null,
              child: widget.otherUserPhoto == null
                  ? const Icon(Icons.person)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(widget.otherUserName),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          // Liste des messages
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getConversationMessages(widget.conversationId),
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
                    child: Text('Aucun message'),
                  );
                }
                
                // Marquer les messages comme lus
                _markMessagesAsRead();
                
                List<MessageModel> messages = snapshot.data!.docs
                    .map((doc) => MessageModel.fromFirestore(doc))
                    .toList();
                
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    MessageModel message = messages[index];
                    bool isMe = message.senderId == FirebaseAuth.instance.currentUser!.uid;
                    
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          
          // Menu des pièces jointes
          if (_isAttachmentMenuOpen)
            Container(
              color: Colors.grey[200],
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image, color: Colors.green),
                    onPressed: _pickImage,
                    tooltip: 'Envoyer une image',
                  ),
                  IconButton(
                    icon: const Icon(Icons.attach_file, color: Colors.blue),
                    onPressed: _pickDocument,
                    tooltip: 'Envoyer un document',
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _isAttachmentMenuOpen = false;
                      });
                    },
                    tooltip: 'Fermer',
                  ),
                ],
              ),
            ),
          
          // Zone de saisie
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    setState(() {
                      _isAttachmentMenuOpen = !_isAttachmentMenuOpen;
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Écrivez un message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[300],
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Contenu du message
            _buildMessageContent(message),
            
            // Horodatage
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat.Hm().format(message.timestamp),
                    style: TextStyle(
                      fontSize: 12,
                      color: isMe ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(width: 4),
                  if (isMe)
                    Icon(
                      message.read ? Icons.done_all : Icons.done,
                      size: 14,
                      color: Colors.white70,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMessageContent(MessageModel message) {
    switch (message.type) {
      case MessageType.image:
        return GestureDetector(
          onTap: () {
            // Afficher l'image en plein écran
            showDialog(
              context: context,
              builder: (context) => Dialog(
                child: Image.network(message.content),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  message.content,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[200],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
        
      case MessageType.document:
        return GestureDetector(
          onTap: () async {
            // Ouvrir le document
            if (!await launchUrl(Uri.parse(message.content))) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Impossible d\'ouvrir le document')),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.insert_drive_file, color: Colors.blue),
                const SizedBox(width: 8),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.fileName ?? 'Document',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Text(
                        'Appuyez pour ouvrir',
                        style: TextStyle(fontSize: 12, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
        
      case MessageType.text:
      default:
        return Text(
          message.content,
          style: TextStyle(
            color: message.senderId == FirebaseAuth.instance.currentUser!.uid
                ? Colors.white
                : Colors.black,
          ),
        );
    }
  }
}