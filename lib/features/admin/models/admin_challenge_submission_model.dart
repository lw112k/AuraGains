// =====================================================================
// ADMIN CHALLENGE SUBMISSION MODEL
// Maps to the `challenge_submission` table, joined with user and challenge.
// Schema: chall_submission_id, chall_id, submitted_by, chall_status,
//         vid_evidence_url, submission_date, reject_reason
// =====================================================================

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is num) return v.toInt();
  if (v is String) {
    final i = int.tryParse(v);
    if (i != null) return i;
    final d = double.tryParse(v);
    if (d != null) return d.toInt();
  }
  return null;
}

DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  if (v is String) return DateTime.tryParse(v);
  if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
  if (v is double) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
  return null;
}

String _toStr(dynamic v) {
  if (v == null) return '';
  if (v is String) return v;
  return v.toString();
}

class AdminChallengeSubmissionModel {
  final int challSubmissionId;
  final int challId;
  final String challengeName; // joined from challenge table
  final String submittedBy;
  final String? username; // joined from user table
  final String? vidEvidenceUrl;
  final String challStatus; // 'pending', 'approved', 'rejected'
  final DateTime? submissionDate;
  final String? rejectReason;

  const AdminChallengeSubmissionModel({
    required this.challSubmissionId,
    required this.challId,
    required this.challengeName,
    required this.submittedBy,
    this.username,
    this.vidEvidenceUrl,
    required this.challStatus,
    this.submissionDate,
    this.rejectReason,
  });

  factory AdminChallengeSubmissionModel.fromJson(
    Map<String, dynamic> json, {
    String? challengeName,
    String? username,
  }) {
    return AdminChallengeSubmissionModel(
      challSubmissionId: _toInt(json['chall_submission_id']) ??
          (throw ArgumentError('Missing required field: chall_submission_id')),
      challId: _toInt(json['chall_id']) ?? 0,
      challengeName:
          challengeName ?? json['challenge_name'] as String? ?? '',
      submittedBy: _toStr(json['submitted_by']),
      username: username ?? json['username'] as String?,
      vidEvidenceUrl: json['vid_evidence_url'] as String?,
      challStatus: json['chall_status'] as String? ?? 'pending',
      submissionDate: _toDate(json['submission_date']),
      rejectReason: json['reject_reason'] as String?,
    );
  }

  AdminChallengeSubmissionModel copyWith({
    String? challStatus,
    String? rejectReason,
  }) =>
      AdminChallengeSubmissionModel(
        challSubmissionId: challSubmissionId,
        challId: challId,
        challengeName: challengeName,
        submittedBy: submittedBy,
        username: username,
        vidEvidenceUrl: vidEvidenceUrl,
        challStatus: challStatus ?? this.challStatus,
        submissionDate: submissionDate,
        rejectReason: rejectReason ?? this.rejectReason,
      );
}
