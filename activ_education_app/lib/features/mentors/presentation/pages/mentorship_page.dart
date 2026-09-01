import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/feedback/state_views.dart';
import '../../data/models/mentorship_model.dart';
import '../widgets/mentorship_request_sheet.dart';

/// « Mon espace mentorat » : mes accompagnements et les mentors suggeres.
///
/// Deux onglets plutot qu'une page unique : une demande en attente et une
/// suggestion n'appellent pas la meme action, et les melanger obligeait a lire
/// un statut pour savoir quoi faire.
class MentorshipPage extends StatefulWidget {
  const MentorshipPage({super.key});

  @override
  State<MentorshipPage> createState() => _MentorshipPageState();
}

class _MentorshipPageState extends State<MentorshipPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  List<Mentorship> _mentorships = [];
  List<MentorSuggestion> _suggestions = [];
  bool _personalized = false;
  bool _loading = true;
  String? _error;

  Dio get _dio => getIt<Dio>(instanceName: 'apiClient');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Les deux appels sont independants : les lancer ensemble evite
      // d'attendre deux allers-retours sur une connexion lente.
      final results = await Future.wait([
        _dio.get(ApiEndpoints.mentorRelationships),
        _dio.get(ApiEndpoints.mentorSuggestions),
      ]);

      final rels = (results[0].data as List)
          .map((r) => Mentorship.fromJson(r as Map<String, dynamic>))
          .toList();
      final body = results[1].data as Map<String, dynamic>;
      final suggestions = (body['items'] as List)
          .map((m) => MentorSuggestion.fromJson(m as Map<String, dynamic>))
          .toList();

      if (!mounted) return;
      setState(() {
        _mentorships = rels;
        _suggestions = suggestions;
        _personalized = body['personalized'] as bool? ?? false;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger votre espace mentorat.';
      });
    }
  }

  Future<void> _requestMentorship(MentorSuggestion mentor) async {
    final sent = await showMentorshipRequestSheet(context, mentor);
    if (sent == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Mon espace mentorat', style: AppTypography.headlineSmall),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textTertiary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Mes mentorats (${_mentorships.length})'),
            const Tab(text: 'Mentors suggérés'),
          ],
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const LoadingView();
    if (_error != null) return ErrorView(message: _error!, onRetry: _load);

    return TabBarView(
      controller: _tabs,
      children: [_buildMentorships(), _buildSuggestions()],
    );
  }

  // ── Onglet 1 : mes mentorats ─────────────────────────────────────────────

  Widget _buildMentorships() {
    if (_mentorships.isEmpty) {
      return const EmptyView(
        icon: Iconsax.people,
        message: "Vous n'avez pas encore de mentorat.\n"
            "Parcourez les mentors suggérés pour faire une demande.",
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _mentorships.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _MentorshipCard(
          mentorship: _mentorships[i],
          onProposeSession: () => _proposeSession(_mentorships[i]),
        ),
      ),
    );
  }

  Future<void> _proposeSession(Mentorship mentorship) async {
    final proposal = await showSessionProposalSheet(context, mentorship);
    if (proposal == null) return;
    try {
      await _dio.post(
        ApiEndpoints.relationshipSessions(mentorship.id),
        data: proposal,
      );
      if (!mounted) return;
      AppSnackbar.success(context, 'Séance proposée à votre mentor.');
      _load();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, _reason(e) ?? 'La proposition a échoué.');
    }
  }

  /// Remonte le message du serveur : « action impossible » n'aide personne.
  String? _reason(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map) {
        final reason = data['message'] ?? data['detail'] ?? data['error'];
        if (reason is String && reason.trim().isNotEmpty) return reason;
      }
    }
    return null;
  }

  // ── Onglet 2 : suggestions ───────────────────────────────────────────────

  Widget _buildSuggestions() {
    if (_suggestions.isEmpty) {
      return const EmptyView(
        icon: Iconsax.user_search,
        message: 'Aucun mentor disponible pour le moment.',
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _suggestions.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          if (i == 0) return _buildSuggestionHeader();
          final mentor = _suggestions[i - 1];
          return _SuggestionCard(
            mentor: mentor,
            alreadyRequested:
                _mentorships.any((m) => m.mentorId == mentor.id),
            onRequest: () => _requestMentorship(mentor),
          );
        },
      ),
    );
  }

  Widget _buildSuggestionHeader() {
    // On dit franchement sur quoi repose le classement. Quand le profil
    // d'orientation est vide, promettre une personnalisation serait faux.
    final text = _personalized
        ? 'Classés selon votre profil d\'orientation : intérêts, matières '
            'préférées et projet professionnel.'
        : 'Complétez votre test d\'orientation pour que ces mentors soient '
            'classés selon votre profil.';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _personalized
            ? AppColors.primarySurface
            : AppColors.secondarySurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            _personalized ? Iconsax.magic_star : Iconsax.info_circle,
            size: 20,
            color: _personalized ? AppColors.primary : AppColors.secondaryDark,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// CARTES
// ============================================================================

class _MentorshipCard extends StatelessWidget {
  final Mentorship mentorship;
  final VoidCallback onProposeSession;

  const _MentorshipCard({
    required this.mentorship,
    required this.onProposeSession,
  });

  @override
  Widget build(BuildContext context) {
    final next = mentorship.nextSession;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(
                url: mentorship.mentorAvatarUrl,
                name: mentorship.mentorName,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mentorship.mentorName ?? 'Mentor',
                        style: AppTypography.titleMedium),
                    if (mentorship.mentorSpecialty != null)
                      Text(mentorship.mentorSpecialty!,
                          style: AppTypography.bodySmall),
                  ],
                ),
              ),
              _StatusChip(mentorship: mentorship),
            ],
          ),
          if (mentorship.goal != null) ...[
            const SizedBox(height: 12),
            Text('Votre objectif', style: AppTypography.labelSmall),
            const SizedBox(height: 2),
            Text(mentorship.goal!, style: AppTypography.bodyMedium),
          ],
          if (mentorship.status == 'cancelled' &&
              mentorship.declineReason != null) ...[
            const SizedBox(height: 10),
            Text(mentorship.declineReason!,
                style: AppTypography.bodySmall
                    .copyWith(fontStyle: FontStyle.italic)),
          ],
          if (next != null) ...[
            const SizedBox(height: 12),
            _NextSessionTile(session: next),
          ],
          if (mentorship.isActive) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                icon: const Icon(Iconsax.calendar_add, size: 18),
                label: const Text('Proposer une séance'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                onPressed: onProposeSession,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NextSessionTile extends StatelessWidget {
  final MentorSession session;

  const _NextSessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final d = session.scheduledAt;
    final quand = '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')} à '
        '${d.hour.toString().padLeft(2, '0')}h'
        '${d.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.calendar_tick,
              size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$quand · ${session.channel?.label ?? 'canal à définir'} '
              '· ${session.statusLabel}',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final MentorSuggestion mentor;
  final bool alreadyRequested;
  final VoidCallback onRequest;

  const _SuggestionCard({
    required this.mentor,
    required this.alreadyRequested,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(url: mentor.avatarUrl, name: mentor.fullName),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(mentor.fullName, style: AppTypography.titleMedium),
                    if (mentor.specialty != null)
                      Text(mentor.specialty!, style: AppTypography.bodySmall),
                  ],
                ),
              ),
              if (mentor.yearsExperience != null)
                Text('${mentor.yearsExperience} ans',
                    style: AppTypography.labelSmall),
            ],
          ),
          // Les termes qui expliquent la suggestion. Un score seul ne dit rien
          // a un eleve ; « génie, électricité » lui dit tout.
          if (mentor.matchTerms.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                Text('Correspond à', style: AppTypography.labelSmall),
                ...mentor.matchTerms.take(4).map(
                      (t) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.secondarySurface,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(t,
                            style: AppTypography.labelSmall.copyWith(
                                color: AppColors.secondaryDark)),
                      ),
                    ),
              ],
            ),
          ],
          if (mentor.bio != null) ...[
            const SizedBox(height: 10),
            Text(mentor.bio!,
                style: AppTypography.bodySmall,
                maxLines: 3,
                overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _capacityLabel()),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                // On desactive AVANT l'envoi plutot que de laisser l'eleve
                // ecrire une demande que le serveur refusera.
                onPressed:
                    (alreadyRequested || mentor.isFull) ? null : onRequest,
                child: Text(alreadyRequested ? 'Demande envoyée' : 'Demander'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _capacityLabel() {
    if (alreadyRequested) {
      return Text('Vous avez déjà écrit à ce mentor',
          style: AppTypography.bodySmall);
    }
    if (mentor.isFull) {
      return Text('Complet pour le moment',
          style: AppTypography.bodySmall.copyWith(color: AppColors.error));
    }
    return Text('${mentor.slotsLeft} place(s) disponible(s)',
        style: AppTypography.bodySmall.copyWith(color: AppColors.success));
  }
}

class _StatusChip extends StatelessWidget {
  final Mentorship mentorship;

  const _StatusChip({required this.mentorship});

  @override
  Widget build(BuildContext context) {
    final color = switch (mentorship.status) {
      'active' => AppColors.success,
      'cancelled' => AppColors.error,
      'completed' => AppColors.textTertiary,
      _ => AppColors.secondaryDark,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(mentorship.statusLabel,
          style: AppTypography.labelSmall.copyWith(color: color)),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final String? name;

  const _Avatar({this.url, this.name});

  @override
  Widget build(BuildContext context) {
    final hasImage = url != null && url!.isNotEmpty;
    return CircleAvatar(
      radius: 24,
      backgroundColor: AppColors.primarySurface,
      backgroundImage: hasImage ? NetworkImage(url!) : null,
      child: hasImage
          ? null
          : Text(
              (name?.isNotEmpty == true ? name![0] : '?').toUpperCase(),
              style: AppTypography.titleMedium
                  .copyWith(color: AppColors.primary),
            ),
    );
  }
}
