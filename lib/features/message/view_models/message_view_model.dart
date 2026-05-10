import 'package:flutter/material.dart';
import '../repositories/message_repository.dart';
import '../models/message_model.dart';

class MessageViewModel extends ChangeNotifier {
  final MessageRepository _repository;
  final String currentUserId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  List<dynamic> _conversations = [];
  List<dynamic> get conversations => _conversations;

  bool _isSearching = false;
  bool get isSearching => _isSearching;

  List<dynamic> _searchResults = [];
  List<dynamic> get searchResults => _searchResults;

  Future<void> searchForUsers(String query) async {
    if (query.trim().isEmpty) {
      _isSearching = false;
      _searchResults.clear();
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    _searchResults = await _repository.searchUsers(query.trim());
    
    notifyListeners();
  }

  /// Called when a user taps on a search result
  Future<String?> startDirectMessage(String targetUserId) async {
    try {
      // Show loading overlay (optional, handled by UI usually)
      return await _repository.getOrCreate1on1Chat(currentUserId, targetUserId);
    } catch (e) {
      print("Failed to start chat: $e");
      return null;
    }
  }


  MessageViewModel({required MessageRepository repository, required this.currentUserId})
      : _repository = repository {
    loadConversations();
  }

  /// Fetches the list of conversations for the wireframe screen
  Future<void> loadConversations() async {
    _isLoading = true;
    notifyListeners();

    try {
      _conversations = await _repository.getUserConversations(currentUserId);
    } catch (e) {
      print("Error loading conversations: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Streams real-time messages for a specific chat
  Stream<List<MessageModel>> getChatStream(String conversationId) {
    return _repository.streamMessages(conversationId);
  }

  /// Sends a new message to the database
  Future<void> sendMessage(String conversationId, String text) async {
    if (text.trim().isEmpty) return;

    final newMessage = MessageModel(
      conversationId: conversationId,
      senderId: currentUserId,
      contentText: text.trim(),
      // createDate will be handled by Supabase default now()
    );

    try {
      await _repository.sendMessage(newMessage);
    } catch (e) {
      print("Error sending message: $e");
    }
  }


  /// Marks a specific chat as read in the database
  Future<void> markAsRead(String conversationId) async {
    await _repository.markConversationAsRead(conversationId, currentUserId);
  }
}