import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../data/models/mentorship_model.dart';

/// Demande de mentorat. Retourne `true` si elle est partie.
///
/// L'objectif est obligatoire et vient en premier : c'est sur lui que le mentor
/// decide, et une demande sans but explicite ne recoit pas de reponse. Les
/// programmes de mentorat qui fonctionnent commencent tous par la.
Future<bool?> showMentorshipRequestSheet(
  BuildContext context,
  MentorSuggestion mentor,
) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _RequestSheet(mentor: mentor),
  );
}

class _RequestSheet extends StatefulWidget {
  final MentorSuggestion mentor;

  const _RequestSheet({required this.mentor});

  @override
  State<_RequestSheet> createState() => _RequestSheetState();
}

class _RequestSheetState extends State<_RequestSheet> {
  final _formKey = GlobalKey<FormState>();
  final _goalCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  SessionChannel _channel = SessionChannel.whatsapp;
  bool _sending = false;

  @override
  void dispose() {
    _goalCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await getIt<Dio>(instanceName: 'apiClient').post(
        ApiEndpoints.requestMentor(widget.mentor.id),
        data: {
          'goal': _goalCtrl.text.trim(),
          if (_messageCtrl.text.trim().isNotEmpty)
            'message': _messageCtrl.text.trim(),
          'preferred_channel': _channel.value,
        },
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      AppSnackbar.success(
        context,
        'Demande envoyée. Le mentor recevra un email et vous répondra ici.',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      AppSnackbar.error(context, _reason(e) ?? "L'envoi a échoué.");
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        // Sans cela le clavier recouvre le champ en cours de saisie.
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Demander un mentorat', style: AppTypography.headlineSmall),
            const SizedBox(height: 4),
            Text('à ${widget.mentor.fullName}', style: AppTypography.bodySmall),
            const SizedBox(height: 20),
            TextFormField(
              controller: _goalCtrl,
              maxLines: 3,
              maxLength: 500,
              decoration: const InputDecoration(
                labelText: 'Votre objectif *',
                hintText: 'Ce que vous attendez de cet accompagnement',
                alignLabelWithHint: true,
              ),
              validator: (v) => (v == null || v.trim().length < 10)
                  ? 'Décrivez votre objectif en quelques mots (10 caractères min.)'
                  : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _messageCtrl,
              maxLines: 3,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Message (facultatif)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            Text('Comment préférez-vous échanger ?',
                style: AppTypography.labelMedium),
            const SizedBox(height: 8),
            _ChannelPicker(
              selected: _channel,
              onChanged: (c) => setState(() => _channel = c),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _sending ? null : _send,
                child: _sending
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Envoyer la demande'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Proposition de seance. Retourne le corps a envoyer, ou `null` si annule.
Future<Map<String, dynamic>?> showSessionProposalSheet(
  BuildContext context,
  Mentorship mentorship,
) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _SessionSheet(mentorship: mentorship),
  );
}

class _SessionSheet extends StatefulWidget {
  final Mentorship mentorship;

  const _SessionSheet({required this.mentorship});

  @override
  State<_SessionSheet> createState() => _SessionSheetState();
}

class _SessionSheetState extends State<_SessionSheet> {
  final _topicCtrl = TextEditingController();
  DateTime? _when;
  int _duration = 45;
  late SessionChannel _channel =
      widget.mentorship.preferredChannel ?? SessionChannel.whatsapp;

  @override
  void dispose() {
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
      initialDate: now.add(const Duration(days: 1)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 17, minute: 0),
    );
    if (time == null) return;
    setState(() => _when = DateTime(
        date.year, date.month, date.day, time.hour, time.minute));
  }

  @override
  Widget build(BuildContext context) {
    final d = _when;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Proposer une séance', style: AppTypography.headlineSmall),
          const SizedBox(height: 4),
          Text('avec ${widget.mentorship.mentorName ?? 'votre mentor'}',
              style: AppTypography.bodySmall),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            icon: const Icon(Icons.event, size: 18),
            label: Text(d == null
                ? 'Choisir la date et l\'heure'
                : '${d.day.toString().padLeft(2, '0')}/'
                    '${d.month.toString().padLeft(2, '0')}/${d.year} à '
                    '${d.hour.toString().padLeft(2, '0')}h'
                    '${d.minute.toString().padLeft(2, '0')}'),
            onPressed: _pickDateTime,
          ),
          const SizedBox(height: 14),
          Text('Durée', style: AppTypography.labelMedium),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [30, 45, 60, 90]
                .map((m) => ChoiceChip(
                      label: Text('$m min'),
                      selected: _duration == m,
                      onSelected: (_) => setState(() => _duration = m),
                    ))
                .toList(),
          ),
          const SizedBox(height: 14),
          Text('Canal', style: AppTypography.labelMedium),
          const SizedBox(height: 6),
          _ChannelPicker(
            selected: _channel,
            onChanged: (c) => setState(() => _channel = c),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _topicCtrl,
            maxLength: 200,
            decoration: const InputDecoration(
              labelText: 'Sujet de la séance (facultatif)',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              // Tant qu'aucune date n'est choisie, il n'y a rien a proposer.
              onPressed: d == null
                  ? null
                  : () => Navigator.pop(context, {
                        'scheduled_at': d.toUtc().toIso8601String(),
                        'duration_min': _duration,
                        'channel': _channel.value,
                        if (_topicCtrl.text.trim().isNotEmpty)
                          'topic': _topicCtrl.text.trim(),
                      }),
              child: const Text('Proposer'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Selection du canal d'echange.
class _ChannelPicker extends StatelessWidget {
  final SessionChannel selected;
  final ValueChanged<SessionChannel> onChanged;

  const _ChannelPicker({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: SessionChannel.values
          .map((c) => ChoiceChip(
                label: Text(c.label),
                selected: selected == c,
                selectedColor: AppColors.primarySurface,
                onSelected: (_) => onChanged(c),
              ))
          .toList(),
    );
  }
}
