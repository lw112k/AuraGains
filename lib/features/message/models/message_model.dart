// message_model.dart
class MessageModel {
  final String? messageId;
  final String conversationId;
  final String senderId;
  final String? parentId; 
  final String? mediaType; 
  final String? contentText;
  final String? mediaUrl;
  final DateTime? createDate;

  MessageModel({
    this.messageId,
    required this.conversationId,
    required this.senderId,
    this.parentId,
    this.mediaType,
    this.contentText,
    this.mediaUrl,
    this.createDate,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: json['message_id'].toString(),
      conversationId: json['conversation_id'].toString(),
      senderId: json['sender_id'] as String,
      parentId: json['parent_id']?.toString(),
      mediaType: json['media_type'] as String?,
      contentText: json['content_text'] as String?,
      mediaUrl: json['media_url'] as String?,
      createDate: json['create_date'] != null ? DateTime.parse(json['create_date']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'sender_id': senderId,
      if (parentId != null) 'parent_id': parentId,
      if (mediaType != null) 'media_type': mediaType,
      if (contentText != null) 'content_text': contentText,
      if (mediaUrl != null) 'media_url': mediaUrl,
    };
  }
}