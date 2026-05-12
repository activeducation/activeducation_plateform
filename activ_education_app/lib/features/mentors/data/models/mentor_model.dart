class MentorModel {
  final String id;
  final String fullName;
  final String specialty;
  final String? bio;
  final String? avatarUrl;
  final int? yearsExperience;
  final bool isVerified;
  final int? hourlyRate;
  final List<String>? availableSlots;
  final String? location;
  final String? linkedinUrl;

  MentorModel({
    required this.id,
    required this.fullName,
    required this.specialty,
    this.bio,
    this.avatarUrl,
    this.yearsExperience,
    this.isVerified = false,
    this.hourlyRate,
    this.availableSlots,
    this.location,
    this.linkedinUrl,
  });

  factory MentorModel.fromJson(Map<String, dynamic> json) {
    return MentorModel(
      id: json['id'] ?? '',
      fullName: json['full_name'] ?? '',
      specialty: json['specialty'] ?? '',
      bio: json['bio'],
      avatarUrl: json['avatar_url'],
      yearsExperience: json['years_experience'],
      isVerified: json['is_verified'] ?? false,
      hourlyRate: json['hourly_rate'],
      availableSlots: json['available_slots'] != null
          ? List<String>.from(json['available_slots'])
          : null,
      location: json['location'],
      linkedinUrl: json['linkedin_url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'specialty': specialty,
    'bio': bio,
    'avatar_url': avatarUrl,
    'years_experience': yearsExperience,
    'is_verified': isVerified,
    'hourly_rate': hourlyRate,
    'available_slots': availableSlots,
    'location': location,
    'linkedin_url': linkedinUrl,
  };

  String get initials {
    final parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : 'M';
  }
}

class MentorReview {
  final String id;
  final String userId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  MentorReview({
    required this.id,
    required this.userId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory MentorReview.fromJson(Map<String, dynamic> json) {
    return MentorReview(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}