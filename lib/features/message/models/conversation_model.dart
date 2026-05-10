// conversation_model.dart
class ConversationModel {
  final String conversationId;
  final String? conversationName; 
  final String? conversationPicUrl;

  ConversationModel({
    required this.conversationId,
    this.conversationName,
    this.conversationPicUrl,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) => ConversationModel(
    conversationId: json['conversation_id'].toString(),
    conversationName: json['conversation_name'] as String?,
    conversationPicUrl: json['conversation_pic_url'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'conversation_name': conversationName,
    'conversation_pic_url': conversationPicUrl,
    
  };
}