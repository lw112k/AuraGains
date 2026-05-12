//conversation, conversation_participant, message tables
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message_model.dart';

class MessageRepository {
  final _supabase = Supabase.instance.client;

  // ==========================================
  // 1. CONVERSATION MANAGEMENT
  // ==========================================

  /// Creates a new conversation and adds the initial participants
  Future<String> createConversation({
    String? name,
    String? picUrl,
    required List<String> participantUserIds,
  }) async {
    try {
      // Step 1: Create the conversation and get its ID
      final convoResponse = await _supabase.from('conversation').insert({
        'conversation_name': name,
        'conversation_pic_url': picUrl,
      }).select('conversation_id').single();

      final newConvoId = convoResponse['conversation_id'].toString();

      // Step 2: Add all users to the conversation_participant table
      final participantsToInsert = participantUserIds.map((userId) {
        return {
          'conversation_id': newConvoId,
          'user_id': userId,
          'conversation_role': 'member', 
        };
      }).toList();

      await _supabase.from('conversation_participant').insert(participantsToInsert);
      
      return newConvoId;
    } catch (e) {
      print('Error creating conversation: $e');
      rethrow;
    }
  }

  
  Future<List<dynamic>> getUserConversations(String userId) async {
    try {
      final data = await _supabase
          .from('conversation_participant')
          .select('''
            conversation_id,
            last_read_at, 
            conversation (
              conversation_id,
              conversation_name,
              conversation_pic_url,
              conversation_participant (
                user_id,
                user (
                  username,
                  profile_pic_url
                )
              )
            )
          ''')
          .eq('user_id', userId);

      final List<dynamic> enrichedData = [];
      
      for (var item in data) {
        final convoId = item['conversation_id'];
        
        // Grab the latest message AND its sender_id
        final msgData = await _supabase
            .from('message')
            .select('content_text, create_date, sender_id')
            .eq('conversation_id', convoId)
            .order('create_date', ascending: false)
            .limit(1);

        final mutableItem = Map<String, dynamic>.from(item);
        bool hasUnread = false; // Default to false

        if (msgData.isNotEmpty) {
          mutableItem['last_message_text'] = msgData.first['content_text'];
          mutableItem['last_message_time'] = msgData.first['create_date'];
          
          // --- UNREAD LOGIC ---
          final senderId = msgData.first['sender_id'];
          final msgTime = DateTime.parse(msgData.first['create_date']);
          final lastReadStr = item['last_read_at'];
          
          // Only show unread dot if YOU didn't send the message
          if (senderId != userId) {
            if (lastReadStr != null) {
              final lastReadTime = DateTime.parse(lastReadStr);
              hasUnread = msgTime.isAfter(lastReadTime);
            } else {
              hasUnread = true; // Never been read
            }
          }
        } else {
          mutableItem['last_message_text'] = "No messages yet";
          mutableItem['last_message_time'] = null;
        }
        
        mutableItem['has_unread'] = hasUnread; 
        enrichedData.add(mutableItem);
      }
          
      return enrichedData;
    } catch (e) {
      print('Error fetching user conversations: $e');
      return [];
    }
  }

  Future<void> markConversationAsRead(String conversationId, String userId) async {
    try {
      await _supabase
          .from('conversation_participant')
          .update({'last_read_at': DateTime.now().toUtc().toIso8601String()})
          .eq('conversation_id', conversationId)
          .eq('user_id', userId);
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  // ==========================================
  // 2. MESSAGING (REAL-TIME)
  // ==========================================

  /// Sends a single message
  Future<void> sendMessage(MessageModel message) async {
    try {
      await _supabase.from('message').insert(message.toJson());
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  /// 🔴 REAL-TIME: Listens to new messages in a conversation instantly
  Stream<List<MessageModel>> streamMessages(String conversationId) {
    return _supabase
        .from('message')
        .stream(primaryKey: ['message_id']) 
        .eq('conversation_id', conversationId)
        .order('create_date', ascending: false) 
        .map((listOfMaps) => listOfMaps.map((map) => MessageModel.fromJson(map)).toList()
        );
  }
  // ==========================================
  // 3. USER SEARCH
  // ==========================================

  /// Searches the user table for matching usernames
  Future<List<dynamic>> searchUsers(String query) async {
    try {
      final data = await _supabase
          .from('user')
          .select('user_id, username, profile_pic_url')
          .ilike('username', '%$query%')
          .limit(10); 
          
      return data;
    } catch (e) {
      print('Error searching users: $e');
      return [];
    }
  }

  /// Checks if a 1-on-1 chat exists. If yes, returns it. If not, creates it.
  Future<String> getOrCreate1on1Chat(String currentUserId, String targetUserId) async {
    try {
      // 1. Get all conversation IDs the current user is in
      final myChats = await _supabase
          .from('conversation_participant')
          .select('conversation_id')
          .eq('user_id', currentUserId);

      final myChatIds = (myChats as List).map((e) => e['conversation_id']).toList();

      if (myChatIds.isNotEmpty) {
        // 2. Check if the target user is in any of those exact same conversations
        final sharedChats = await _supabase
            .from('conversation_participant')
            .select('conversation_id')
            .eq('user_id', targetUserId)
            .inFilter('conversation_id', myChatIds); 

        if (sharedChats.isNotEmpty) {
          // Chat already exists! Return the existing conversation ID
          return sharedChats.first['conversation_id'].toString();
        }
      }

      // 3. If we reach here, no chat exists. Let's create a new one!
      return await createConversation(
        participantUserIds: [currentUserId, targetUserId],
      );
    } catch (e) {
      print('Error getting/creating chat: $e');
      rethrow;
    }
  }
}