import 'package:supabase_flutter/supabase_flutter.dart';

class UserEventRepository {
  final _supabase = Supabase.instance.client;

  Future<void> recordPostViewEvent({
    required int postId,
    required String userId,
  }) async {
    await _supabase
        .from('user_event')
        .insert({
          'post_id': postId,
          'user_id': userId,
          'event_type': 'view',
        });
  }
}