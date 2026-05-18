import 'package:supabase_flutter/supabase_flutter.dart';

class ReportRepository {

  final SupabaseClient supabase = Supabase.instance.client;

  Future<void> submitReport({
    required String reportBy,
    required String targetType,
    required int targetId,
    required String reason,
  }) async {

    await supabase
        .from('report')
        .insert({
          'report_by': reportBy,
          'target_type': targetType,
          'target_id': targetId,
          'reason': reason,
        });
  }
}