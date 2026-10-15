/// Modeles de l'espace mentorat : relation eleve/mentor, seance, suggestion.
///
/// Aucune valeur n'est inventee quand l'API n'en fournit pas : un champ absent
/// reste `null` et l'interface s'abstient de l'afficher, plutot que de montrer
/// un defaut qui passerait pour une information.
library;

/// Canaux d'une seance. La visio n'est pas le defaut : WhatsApp et le telephone
/// passent la ou la visio ne passe pas. Liste alignee sur la migration 030.
enum SessionChannel {
  whatsapp('whatsapp', 'WhatsApp'),
  telephone('telephone', 'Téléphone'),
  presentiel('presentiel', 'En présentiel'),
  visio('visio', 'Visioconférence');

  const SessionChannel(this.value, this.label);
  final String value;
  final String label;

  static SessionChannel? fromValue(String? v) {
    for (final c in SessionChannel.values) {
      if (c.value == v) return c;
    }
    return null;
  }
}

class MentorSession {
  final String id;
  final String relationshipId;
  final DateTime scheduledAt;
  final int durationMin;
  final SessionChannel? channel;
  final String status;
  final String proposedBy;
  final String? topic;
  final String? notes;

  const MentorSession({
    required this.id,
    required this.relationshipId,
    required this.scheduledAt,
    required this.durationMin,
    required this.status,
    required this.proposedBy,
    this.channel,
    this.topic,
    this.notes,
  });

  factory MentorSession.fromJson(Map<String, dynamic> json) {
    return MentorSession(
      id: json['id'] as String,
      relationshipId: json['relationship_id'] as String,
      scheduledAt: DateTime.parse(json['scheduled_at'] as String).toLocal(),
      durationMin: json['duration_min'] as int? ?? 45,
      channel: SessionChannel.fromValue(json['channel'] as String?),
      status: json['status'] as String? ?? 'proposed',
      proposedBy: json['proposed_by'] as String? ?? 'mentee',
      topic: json['topic'] as String?,
      notes: json['notes'] as String?,
    );
  }

  bool get isUpcoming =>
      status != 'cancelled' && scheduledAt.isAfter(DateTime.now());

  String get statusLabel => switch (status) {
        'confirmed' => 'Confirmée',
        'done' => 'Terminée',
        'cancelled' => 'Annulée',
        _ => 'Proposée',
      };
}

class Mentorship {
  final String id;
  final String mentorId;
  final String status;
  final String? goal;
  final String? message;
  final SessionChannel? preferredChannel;
  final String? declineReason;
  final DateTime? createdAt;
  final String? mentorName;
  final String? mentorSpecialty;
  final String? mentorAvatarUrl;
  final List<MentorSession> sessions;

  const Mentorship({
    required this.id,
    required this.mentorId,
    required this.status,
    this.goal,
    this.message,
    this.preferredChannel,
    this.declineReason,
    this.createdAt,
    this.mentorName,
    this.mentorSpecialty,
    this.mentorAvatarUrl,
    this.sessions = const [],
  });

  factory Mentorship.fromJson(Map<String, dynamic> json) {
    return Mentorship(
      id: json['id'] as String,
      mentorId: json['mentor_id'] as String,
      status: json['status'] as String? ?? 'pending',
      goal: json['goal'] as String?,
      message: json['message'] as String?,
      preferredChannel:
          SessionChannel.fromValue(json['preferred_channel'] as String?),
      declineReason: json['decline_reason'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String)?.toLocal(),
      mentorName: json['mentor_name'] as String?,
      mentorSpecialty: json['mentor_specialty'] as String?,
      mentorAvatarUrl: json['mentor_avatar_url'] as String?,
      sessions: (json['sessions'] as List<dynamic>? ?? [])
          .map((s) => MentorSession.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';

  String get statusLabel => switch (status) {
        'active' => 'Mentorat en cours',
        'completed' => 'Terminé',
        'cancelled' => 'Non retenue',
        _ => 'En attente de réponse',
      };

  /// Prochaine seance a venir, s'il y en a une.
  MentorSession? get nextSession {
    final upcoming = sessions.where((s) => s.isUpcoming).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return upcoming.isEmpty ? null : upcoming.first;
  }
}

/// Un mentor propose a l'eleve, avec ce qui justifie la proposition.
class MentorSuggestion {
  final String id;
  final String fullName;
  final String? specialty;
  final String? bio;
  final String? avatarUrl;
  final int? yearsExperience;
  final List<String> expertiseAreas;

  /// Termes communs entre le profil d'orientation et ce que le mentor annonce.
  /// Affiches tels quels : l'eleve doit pouvoir lire pourquoi on le lui propose.
  final List<String> matchTerms;
  final int slotsLeft;

  const MentorSuggestion({
    required this.id,
    required this.fullName,
    required this.matchTerms,
    required this.slotsLeft,
    this.specialty,
    this.bio,
    this.avatarUrl,
    this.yearsExperience,
    this.expertiseAreas = const [],
  });

  factory MentorSuggestion.fromJson(Map<String, dynamic> json) {
    return MentorSuggestion(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      specialty: json['specialty'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      yearsExperience: json['years_experience'] as int?,
      expertiseAreas: (json['expertise_areas'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      matchTerms: (json['match_terms'] as List<dynamic>? ?? [])
          .map((e) => e.toString())
          .toList(),
      slotsLeft: json['slots_left'] as int? ?? 0,
    );
  }

  bool get isFull => slotsLeft <= 0;
}
