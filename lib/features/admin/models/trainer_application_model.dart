/// Trainer application model — maps to the `expert_application` table.
///
/// DB column names used by the team's Supabase schema:
///   expert_application_id, user_id, application_status,
///   create_date, full_name, email, gender,
///   years_experience, specialization, bio, cert_urls
///
/// Used by [ApplicationsScreen] and [VerifyTrainerScreen].
class TrainerApplication {
  const TrainerApplication({
    required this.id,
    required this.userId,
    required this.status,
    required this.createdAt,
    this.fullName = '',
    this.email = '',
    this.gender = '',
    this.yearsExperience = 0,
    this.specialization = '',
    this.bio = '',
    this.certUrls = const [],
  });

  final String id;
  final String userId;

  /// One of: 'pending' | 'approved' | 'rejected'
  final String status;
  final DateTime createdAt;
  final String fullName;
  final String email;
  final String gender;
  final int yearsExperience;
  final String specialization;
  final String bio;
  final List<String> certUrls;

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory TrainerApplication.fromSupabase(Map<String, dynamic> row) {
    final certRaw = row['cert_urls'];
    final certs = certRaw is List
        ? certRaw.map((e) => e.toString()).toList()
        : <String>[];

    return TrainerApplication(
      id: (row['expert_application_id'] ?? row['id'] ?? '').toString(),
      userId: (row['user_id'] ?? '').toString(),
      status: row['application_status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(
              (row['create_date'] ?? row['created_at']) as String? ?? '') ??
          DateTime.now(),
      fullName: row['full_name'] as String? ?? '',
      email: row['email'] as String? ?? '',
      gender: row['gender'] as String? ?? '',
      yearsExperience: (row['years_experience'] as num?)?.toInt() ?? 0,
      specialization: row['specialization'] as String? ?? '',
      bio: row['bio'] as String? ?? '',
      certUrls: certs,
    );
  }

  TrainerApplication copyWith({String? status}) => TrainerApplication(
        id: id,
        userId: userId,
        status: status ?? this.status,
        createdAt: createdAt,
        fullName: fullName,
        email: email,
        gender: gender,
        yearsExperience: yearsExperience,
        specialization: specialization,
        bio: bio,
        certUrls: certUrls,
      );

  @override
  String toString() =>
      'TrainerApplication(id: $id, fullName: $fullName, status: $status)';
}
