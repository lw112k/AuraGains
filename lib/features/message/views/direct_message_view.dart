import 'package:flutter/material.dart';
import '../view_models/message_view_model.dart';
import '../models/message_model.dart';
import '../../../core/widgets/clickable_avatar.dart';
import '../../user_profile/views/user_profile_view.dart';

class DirectMessageView extends StatefulWidget {
  final MessageViewModel viewModel;
  final String conversationId;
  final String chatName;
  final String? targetPicUrl;
  final String targetUserId;

  const DirectMessageView({
    super.key,
    required this.viewModel,
    required this.conversationId,
    required this.chatName,
    this.targetPicUrl,
    required this.targetUserId,
  });

  @override
  State<DirectMessageView> createState() => _DirectMessageViewState();
}

class _DirectMessageViewState extends State<DirectMessageView> {
  final TextEditingController _messageController = TextEditingController();
  late Stream<List<MessageModel>> _chatStream;

  @override
  void initState() {
    super.initState();
    // 2. Initialize it ONCE
    _chatStream = widget.viewModel.getChatStream(widget.conversationId);
  }

  void _handleSend() {
    if (_messageController.text.isNotEmpty) {
      widget.viewModel.sendMessage(
        widget.conversationId,
        _messageController.text,
      );
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF121212);
    const Color fieldColor = Color(0xFF2A2A2A);
    const Color accentColor = Color(0xFF00E5FF);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: fieldColor,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClickableAvatar(
              profilePicUrl: widget.targetPicUrl,
              username: widget.chatName,
              radius: 16,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserProfileView(
                      targetUserId: widget.targetUserId,
                      currentUserId: widget.viewModel.currentUserId,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            Text(
              widget.chatName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _chatStream, // 3. Use the stored stream
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Say hi!"));
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  reverse: true, // 4. Set to true to pin to bottom
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg.senderId == widget.viewModel.currentUserId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 12,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isMe ? accentColor : fieldColor,
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isMe
                                ? const Radius.circular(0)
                                : const Radius.circular(16),
                            bottomLeft: !isMe
                                ? const Radius.circular(0)
                                : const Radius.circular(16),
                          ),
                        ),
                        child: Text(
                          msg.contentText ?? '',
                          style: TextStyle(
                            color: isMe ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // THE TEXT INPUT AREA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: bgColor,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: fieldColor,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: accentColor,
                    child: IconButton(
                      icon: const Icon(
                        Icons.send,
                        color: Colors.black,
                        size: 20,
                      ),
                      onPressed: _handleSend,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
