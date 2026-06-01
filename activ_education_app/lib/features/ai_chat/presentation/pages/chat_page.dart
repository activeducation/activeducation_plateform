import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/auth/token_storage.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/buttons/gradient_button.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../features/orientation/domain/entities/test_result.dart';
import '../../data/datasources/chat_local_datasource.dart';
import '../../data/datasources/chat_remote_datasource.dart';
import '../../data/repositories/chat_repository_impl.dart';
import '../../domain/entities/chat_message.dart';
import '../bloc/chat_bloc.dart';

// ---------------------------------------------------------------------------
// Arguments de navigation
// ---------------------------------------------------------------------------

// Widgets prives extraits en parts (meme librairie, imports partages).
part 'chat/auth_required_screen.dart';
part 'chat/chat_view.dart';
part 'chat/message_widgets.dart';

class ChatPageArgs {
  final TestResult? orientationResult;

  const ChatPageArgs({this.orientationResult});

  Map<String, dynamic>? toContextMap() {
    final r = orientationResult;
    if (r == null) return null;

    final interp = r.interpretation;
    return {
      if (interp?.profileCode != null) 'profile_code': interp!.profileCode,
      if (r.dominantTraits.isNotEmpty) 'dominant_traits': r.dominantTraits,
      if (interp?.profileSummary.isNotEmpty == true)
        'profile_summary': interp!.profileSummary,
      if (interp?.strengths.isNotEmpty == true)
        'strengths': interp!.strengths,
      if (r.recommendations.isNotEmpty)
        'recommendations': r.recommendations
            .take(5)
            .map((c) => {'name': c.name, 'sector': c.sector})
            .toList(),
      if (interp?.recommendedSectors.isNotEmpty == true)
        'recommended_sectors': interp!.recommendedSectors,
    };
  }
}

// ---------------------------------------------------------------------------
// Page principale
// ---------------------------------------------------------------------------

class ChatPage extends StatefulWidget {
  final ChatPageArgs args;

  const ChatPage({super.key, required this.args});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool _isChecking = true;
  bool _isAuthenticated = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final tokenStorage = getIt<TokenStorage>();
    final hasTokens = await tokenStorage.hasValidTokens();
    if (hasTokens) {
      _userId = await tokenStorage.getUserId();
    }
    if (mounted) {
      setState(() {
        _isAuthenticated = hasTokens;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    if (!_isAuthenticated) {
      return _AuthRequiredScreen();
    }

    final localStorage = ChatLocalDataSource(getIt<SharedPreferences>());

    return BlocProvider(
      create: (_) => ChatBloc(
        ChatRepositoryImpl(
          ChatRemoteDataSourceImpl(getIt<Dio>(instanceName: 'apiClient')),
        ),
        localStorage,
        orientationContext: widget.args.toContextMap(),
      )..add(LoadChatHistory(_userId ?? 'anonymous')),
      child: _ChatView(hasContext: widget.args.orientationResult != null),
    );
  }
}

