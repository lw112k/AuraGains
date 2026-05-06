/// Trainer application model — maps to the `trainer_applications` table.
///
/// DB schema: id, user_id, full_name, email, gender, years_experience,
///            specialization, bio, cert_urls (array), status, created_at
class TrainerApplication {
  const TrainerApplication({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.email,
    required this.specialization,
    required this.yearsExperience,
    required this.bio,
    required this.certUrls,
    required this.status,
    required this.createdAt,
    this.gender = '',
  });

  final String id;
  final String userId;
  final String fullName;
  final String email;
  final String gender;
  final int yearsExperience;
  final String specialization;
  final String bio;
  final List<String> certUrls;
  /// One of: 'pending', 'approved', 'rejected'
  final String status;
  final DateTime createdAt;

  /// Builds a TrainerApplication from a Supabase row.
  factory TrainerApplication.fromSupabase(Map<String, dynamic> row) {
    return TrainerApplication(
      id: row['id'] as String? ?? '',
      userId: row['user_id'] as String? ?? '',
      fullName: row['full_name'] as String? ?? '',
      email: row['email'] as String? ?? '',
      gender: row['gender'] as String? ?? '',
      yearsExperience: (row['years_experience'] as num?)?.toInt() ?? 0,
      specialization: row['specialization'] as String? ?? '',
      bio: row['bio'] as String? ?? '',
      certUrls: (row['cert_urls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      status: row['status'] as String? ?? 'pending',
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  TrainerApplication copyWith({String? status}) => TrainerApplication(
        id: id,
        userId: userId,
        fullName: fullName,
        email: email,
        gender: gender,
        yearsExperience: yearsExperience,
        specialization: specialization,
        bio: bio,
        certUrls: certUrls,
        status: status ?? this.status,
        createdAt: createdAt,
      );

  @override
  String toString() =>
      'TrainerApplication(id: $id, userId: $userId, status: $status)';
}
