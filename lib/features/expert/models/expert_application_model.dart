/// This model represents the structure of an expert application as it exists 
/// in the Supabase 'expert_application' table.
class ExpertApplicationModel {
  // We use 'int' here because the Supabase database uses 'bigint' for this ID.
  final int? expertApplicationId; 
  
  // We use 'String' for the user ID because Supabase auth IDs are UUIDs.
  final String userId;            
  
  final String expertTitle;
  final int experienceYear;       
  final String experienceDescription;
  
  // This tracks if the admin has approved or rejected the application.
  // Defaults to 'pending' when first created.
  final String applicationStatus; 
  
  final DateTime? createDate;

  // Constructor requires all essential fields to create an application.
  ExpertApplicationModel({
    this.expertApplicationId,
    required this.userId,
    required this.expertTitle,
    required this.experienceYear,
    required this.experienceDescription,
    this.applicationStatus = 'pending',
    this.createDate,
  });

  /// Factory method to convert a JSON map (returned from Supabase) into our Dart object.
  factory ExpertApplicationModel.fromJson(Map<String, dynamic> json) {
    return ExpertApplicationModel(
      expertApplicationId: json['expert_application_id'] as int?,
      userId: json['user_id'] as String,
      expertTitle: json['expert_title'] as String,
      experienceYear: json['experience_year'] as int,
      experienceDescription: json['experience_description'] as String,
      // Provide a fallback of 'pending' if the database returns null
      applicationStatus: json['application_status'] as String? ?? 'pending',
      // Convert the string date from the database into a Flutter DateTime object
      createDate: json['create_date'] != null 
          ? DateTime.parse(json['create_date'] as String) 
          : null,
    );
  }

  /// Converts this Dart object back into a JSON map so we can send it to Supabase.
  Map<String, dynamic> toJson() {
    return {
      // Only include the ID if it's not null (usually the DB generates this automatically)
      if (expertApplicationId != null) 'expert_application_id': expertApplicationId,
      'user_id': userId,
      'expert_title': expertTitle,
      'experience_year': experienceYear,
      'experience_description': experienceDescription,
      'application_status': applicationStatus,
      // Note: create_date is omitted here because Supabase sets it automatically via DEFAULT now()
    };
  }
}