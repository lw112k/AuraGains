import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/message_view_model.dart';
import 'direct_message_view.dart';

// --- THEME VARIABLES ---
const Color _bgColor = Color(0xFF121212);
const Color _fieldColor = Color(0xFF2A2A2A);
const Color _accentColor = Color(0xFF00E5FF);
const Color _textPrimary = Colors.white;
const Color _textSecondary = Colors.grey;

class MessageView extends StatelessWidget {
  const MessageView({super.key});

  @override
  Widget build(BuildContext context) {
    final chatVM = context.watch<ChatViewModel>();

    return Container(
      color: _bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10), 
          
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: _fieldColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              style: const TextStyle(color: _textPrimary),
              onChanged: (value) {
                chatVM.searchForUsers(value); 
              },
              decoration: const InputDecoration(
                icon: Icon(Icons.search, color: _textSecondary),
                hintText: 'Search Username',
                hintStyle: TextStyle(color: _textSecondary),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Dynamic Title
          Text(chatVM.isSearching ? 'Search Results' : 'Messages', 
              style: const TextStyle(color: _textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Chat List OR Search Results
          Expanded(
            child: chatVM.isLoading
                ? const Center(child: CircularProgressIndicator(color: _accentColor))
                : chatVM.isSearching
                    // SHOW SEARCH RESULTS
                    ? ListView.builder(
                        itemCount: chatVM.searchResults.length,
                        itemBuilder: (context, index) {
                          final user = chatVM.searchResults[index];
                          return _buildUserSearchTile(context, chatVM, user);
                        },
                      )
                    // SHOW EXISTING CHATS
                    : chatVM.conversations.isEmpty
                        ? const Center(child: Text("No messages yet.", style: TextStyle(color: _textSecondary)))
                        : ListView.builder(
                            itemCount: chatVM.conversations.length,
                            itemBuilder: (context, index) {
                              final item = chatVM.conversations[index];
                              final convo = item['conversation'];
                              final convoId = convo['conversation_id'].toString();

                              final participants = convo['conversation_participant'] as List<dynamic>? ?? [];
                              String displayTitle = convo['conversation_name'] ?? 'Chat'; 
                              String otherUserId = '';
                              
                              try {
                                final otherUser = participants.firstWhere(
                                  (p) => p['user_id'].toString() != chatVM.currentUserId,
                                );
                                otherUserId = otherUser['user_id'].toString();
                                if (otherUser['user'] != null && otherUser['user']['username'] != null) {
                                  displayTitle = otherUser['user']['username'];
                                }
                              } catch (e) {}

                              final lastMessageText = item['last_message_text'] ?? 'No messages yet';
                              final lastMessageTime = _formatTime(item['last_message_time'] as String?);
                              final hasUnread = item['has_unread'] as bool? ?? false;
                              

                              return _buildChatTile(
                                context, chatVM, convoId, displayTitle, 
                                lastMessageText, lastMessageTime, hasUnread, 
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS & FUNCTIONS
  // ==========================================

  Widget _buildUserSearchTile(BuildContext context, ChatViewModel viewModel, Map<String, dynamic> user) {
    final targetUserId = user['user_id'].toString();
    final username = user['username'] ?? 'Unknown';

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _accentColor,
        child: Text(username[0].toUpperCase(), style: const TextStyle(color: Colors.black)),
      ),
      title: Text(username, style: const TextStyle(color: _textPrimary)),
      trailing: const Icon(Icons.message, color: _textSecondary),
      onTap: () async {
        final convoId = await viewModel.startDirectMessage(targetUserId);
        
        if (convoId != null && context.mounted) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => DirectMessageView(
              viewModel: viewModel,
              conversationId: convoId,
              chatName: username,
            ),
          )).then((_) {
            viewModel.loadConversations();
          });
        }
      },
    );
  }

  Widget _buildChatTile(BuildContext context, ChatViewModel viewModel, String convoId, String name, String lastMsg, String time, bool hasUnread) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: () async {
        // MARK AS READ IN DATABASE BEFORE OPENING
        await viewModel.markAsRead(convoId);

        if (context.mounted) {
          Navigator.push(context, MaterialPageRoute(
            builder: (_) => DirectMessageView(
              viewModel: viewModel,
              conversationId: convoId,
              chatName: name,
            ),
          )).then((_) {
              viewModel.loadConversations();
          });
        }
      },
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _fieldColor,
            child: Text(name[0].toUpperCase(), style: const TextStyle(color: _textPrimary)),
          ),
          
        ],
      ),
      // Unread Msg
      title: Text(name, style: TextStyle(color: _textPrimary, fontWeight: hasUnread ? FontWeight.w900 : FontWeight.bold)),
      subtitle: Text(
        lastMsg, 
        style: TextStyle(color: hasUnread ? Colors.white : _textSecondary, fontSize: 13, fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal), 
        maxLines: 1, 
        overflow: TextOverflow.ellipsis
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time, style: TextStyle(color: hasUnread ? _accentColor : _textSecondary, fontSize: 12)),
          if (hasUnread) ...[
            const SizedBox(height: 4),
            // THE UNREAD DOT
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: _accentColor,
                shape: BoxShape.circle,
              ),
            )
          ]
        ],
      ),
    );
  }

  /// Converts Supabase timestamps into human-readable time 
  String _formatTime(String? dateString) {
    if (dateString == null) return '';
    
    final date = DateTime.parse(dateString).toLocal();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0 && now.day == date.day) {
      int hour = date.hour > 12 ? date.hour - 12 : date.hour == 0 ? 12 : date.hour;
      String minute = date.minute.toString().padLeft(2, '0');
      String amPm = date.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $amPm';
    } else if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[date.weekday - 1];
    } else {
      return '${date.month}/${date.day}';
    }
  }
}