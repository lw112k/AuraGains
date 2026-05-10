// conversation_participant_model.dart
class ConversationParticipantModel {
  final String conversationId;
  final String userId;
  final String conversationRole;

  ConversationParticipantModel({
    required this.conversationId,
    required this.userId,
    required this.conversationRole,
  });

  factory ConversationParticipantModel.fromJson(Map<String, dynamic> json) => ConversationParticipantModel(
    conversationId: json['conversation_id'].toString(),
    userId: json['user_id'] as String,
    conversationRole: json['conversation_role'] as String,
  );

  Map<String, dynamic> toJson() => {
    'conversation_id': conversationId,
    'user_id': userId,
    'conversation_role': conversationRole,
  };
}