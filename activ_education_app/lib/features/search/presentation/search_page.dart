import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';

import '../../../core/constants/constants.dart';
import '../../../core/di/injection_container.dart';

/// Page de recherche unifiée : écoles, métiers et cours.
/// Recherche en direct (debounce) via GET /search?q=.
class SearchPage extends StatefulWidget {
  final String? initialQuery;
  const SearchPage({super.key, this.initialQuery});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  Map<String, dynamic>? _results;
  String _lastQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _controller.text = widget.initialQuery!;
      _search(widget.initialQuery!);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() { _results = null; _loading = false; });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value.trim()));
  }

  Future<void> _search(String query) async {
    _lastQuery = query;
    try {
      final dio = getIt<Dio>(instanceName: 'apiClient');
      final res = await dio.get(ApiEndpoints.search, queryParameters: {'q': query});
      if (!mounted || query != _lastQuery) return;
      setState(() { _results = Map<String, dynamic>.from(res.data); _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _results = null; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Container(
          height: 44,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: TextField(
            controller: _controller,
            autofocus: true,
            onChanged: _onChanged,
            style: AppTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: 'École, métier, cours...',
              hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textTertiary),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _results = null);
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_results == null) {
      return _buildHint();
    }

    final schools = (_results!['schools'] as List?) ?? [];
    final careers = (_results!['careers'] as List?) ?? [];
    final courses = (_results!['courses'] as List?) ?? [];
    final total = schools.length + careers.length + courses.length;

    if (total == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.search_normal, size: 44, color: AppColors.textTertiary),
            const SizedBox(height: 14),
            Text('Aucun résultat pour « $_lastQuery »',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (careers.isNotEmpty) _section('Métiers & filières', Iconsax.briefcase, careers),
        if (schools.isNotEmpty) _section('Écoles', Iconsax.building, schools),
        if (courses.isNotEmpty) _section('Cours', Iconsax.book, courses),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHint() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Iconsax.search_normal_1, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 16),
            Text('Recherchez une école, un métier ou un cours',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, List items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(width: 6),
            Text('(${items.length})', style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary)),
          ]),
        ),
        ...items.map((e) => _resultTile(e as Map<String, dynamic>)),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _resultTile(Map<String, dynamic> r) {
    final image = r['image'] as String?;
    return InkWell(
      onTap: () {
        final route = r['route'] as String?;
        if (route != null && route.isNotEmpty) context.push(route);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              borderRadius: BorderRadius.circular(10),
              image: (image != null && image.isNotEmpty)
                  ? DecorationImage(image: NetworkImage(image), fit: BoxFit.cover)
                  : null,
            ),
            child: (image == null || image.isEmpty)
                ? Icon(_iconFor(r['type']), size: 20, color: AppColors.textTertiary)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['title'] ?? '', style: AppTypography.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(r['subtitle'] ?? '', style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
        ]),
      ),
    );
  }

  IconData _iconFor(String? type) {
    switch (type) {
      case 'school': return Iconsax.building;
      case 'career': return Iconsax.briefcase;
      case 'course': return Iconsax.book;
      default: return Iconsax.search_normal;
    }
  }
}
