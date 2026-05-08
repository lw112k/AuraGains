/// Friend model — maps to the `friends` table.
///
/// DB schema: id, requester_id, receiver_id, status, created_at
/// status values: 'pending' | 'accepted'
class FriendModel {
  const FriendModel({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
  });

  final String id;

  /// `requester_id` — the user who sent the friend request.
  final String requesterId;

  /// `receiver_id` — the user who received the friend request.
  final String receiverId;

  /// One of: 'pending', 'accepted'
  final String status;

  final DateTime createdAt;

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';

  /// Builds a FriendModel from a Supabase row.
  factory FriendModel.fromSupabase(Map<String, dynamic> row) {
    return FriendModel(
      id: row['id'] as String? ?? '',
      requesterId: row['requester_id'] as String? ?? '',
      receiverId: row['receiver_id'] as String? ?? '',
      status: row['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  FriendModel copyWith({String? status}) => FriendModel(
        id: id,
        requesterId: requesterId,
        receiverId: receiverId,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  @override
  String toString() =>
      'FriendModel(id: $id, requesterId: $requesterId, receiverId: $receiverId, status: $status)';
}
