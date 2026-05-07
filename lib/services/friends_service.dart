import 'package:auragains/core/services/database_connection.dart';
import 'package:auragains/models/friend_model.dart';

/// Data-access layer for the `friends` table.
///
/// All methods use [DatabaseConnection.client].
/// Exceptions are rethrown so the calling ViewModel can update UI state.
///
/// TEAM NOTE (Zorrow): The `friends` table is used for both follow-style
/// relationships and friend requests. Confirm with the team whether
/// `status='accepted'` means mutual friendship or a one-way follow,
/// as this affects how [getFriends] interprets direction.
class FriendsService {
  final _client = DatabaseConnection.client;

  static const _table = 'friends';

  // ─────────────────────────────────────────────────────────
  // SEND REQUEST
  // ─────────────────────────────────────────────────────────

  /// Inserts a new friend request from [uid] to [targetId] with status='pending'.
  ///
  /// Checks both directions first to prevent duplicate rows:
  ///   (requester=uid, receiver=targetId) OR (requester=targetId, receiver=uid)
  /// If any row already exists (pending or accepted), the insert is skipped
  /// and the existing [FriendModel] is returned instead.
  ///
  /// Returns the newly inserted (or pre-existing) [FriendModel].
  Future<FriendModel> sendFriendRequest(String uid, String targetId) async {
    try {
      // Check if a relationship already exists in either direction.
      final existing = await _client
          .from(_table)
          .select()
          .or(
            'and(requester_id.eq.$uid,receiver_id.eq.$targetId),'
            'and(requester_id.eq.$targetId,receiver_id.eq.$uid)',
          )
          .maybeSingle();

      if (existing != null) {
        // Relationship already exists — return it without inserting.
        return FriendModel.fromSupabase(existing);
      }

      // No existing relationship — insert the new pending request.
      final inserted = await _client
          .from(_table)
          .insert({
            'requester_id': uid,
            'receiver_id': targetId,
            'status': 'pending',
          })
          .select()
          .single();

      return FriendModel.fromSupabase(inserted);
    } catch (e) {
      throw Exception('FriendsService.sendFriendRequest failed: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // ACCEPT REQUEST
  // ─────────────────────────────────────────────────────────

  /// Sets status='accepted' on the `friends` row identified by [requestId].
  ///
  /// [requestId] is the UUID primary key (`id`) of the friends row,
  /// NOT the requester's user id.
  Future<void> acceptRequest(String requestId) async {
    try {
      await _client
          .from(_table)
          .update({'status': 'accepted'})
          .eq('id', requestId);
    } catch (e) {
      throw Exception('FriendsService.acceptRequest failed: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // REMOVE / UNFOLLOW
  // ─────────────────────────────────────────────────────────

  /// Deletes the relationship row between [uid] and [targetId] in either direction.
  ///
  /// Covers both cases:
  ///   • uid sent the request  → requester_id=uid,    receiver_id=targetId
  ///   • uid received the request → requester_id=targetId, receiver_id=uid
  Future<void> removeFriend(String uid, String targetId) async {
    try {
      await _client.from(_table).delete().or(
            'and(requester_id.eq.$uid,receiver_id.eq.$targetId),'
            'and(requester_id.eq.$targetId,receiver_id.eq.$uid)',
          );
    } catch (e) {
      throw Exception('FriendsService.removeFriend failed: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // GET ACCEPTED FRIENDS
  // ─────────────────────────────────────────────────────────

  /// Fetches all accepted friends for [uid] with joined user profile data.
  ///
  /// Query: `friends` where (requester_id=uid OR receiver_id=uid) AND status='accepted'
  /// Joins both sides of the relationship to the `users` table so the ViewModel
  /// can determine which user is "the other person".
  ///
  /// Returns raw maps (not [FriendModel]) because [FriendModel] does not carry
  /// user profile fields. Each map contains:
  ///   - all `friends` columns (id, requester_id, receiver_id, status, created_at)
  ///   - `requester` → {id, username, avatar_url} from `users`
  ///   - `receiver`  → {id, username, avatar_url} from `users`
  ///
  /// ViewModel tip: check which of requester.id / receiver.id equals the current
  /// uid to identify the "other" user to display.
  ///
  /// TEAM NOTE (prompt named this `getSavedProtocols` — that appears to be a
  /// copy-paste error; the implementation is for fetching accepted friends).
  Future<List<Map<String, dynamic>>> getFriends(String uid) async {
    try {
      // .or() filter scoped to both directions; status filter applied after.
      final rows = await _client
          .from(_table)
          .select(
            '*, '
            'requester:requester_id(id, username, avatar_url), '
            'receiver:receiver_id(id, username, avatar_url)',
          )
          .or('requester_id.eq.$uid,receiver_id.eq.$uid')
          .eq('status', 'accepted')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      throw Exception('FriendsService.getFriends failed: $e');
    }
  }

  // ─────────────────────────────────────────────────────────
  // GET PENDING REQUESTS
  // ─────────────────────────────────────────────────────────

  /// Fetches all incoming pending friend requests for [uid].
  ///
  /// Query: `friends` where receiver_id=uid AND status='pending'
  /// Joins the `users` table on requester_id so the UI can display
  /// the sender's username and avatar without a second query.
  ///
  /// Returns raw maps for the same reason as [getFriends] — each map contains:
  ///   - all `friends` columns
  ///   - `requester` → {id, username, avatar_url} from `users`
  ///
  /// To get a typed [FriendModel] (without user details), call
  /// `FriendModel.fromSupabase(row)` on each element in the ViewModel.
  Future<List<Map<String, dynamic>>> getPendingRequests(String uid) async {
    try {
      final rows = await _client
          .from(_table)
          .select(
            '*, '
            'requester:requester_id(id, username, avatar_url)',
          )
          .eq('receiver_id', uid)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(rows);
    } catch (e) {
      throw Exception('FriendsService.getPendingRequests failed: $e');
    }
  }
}
