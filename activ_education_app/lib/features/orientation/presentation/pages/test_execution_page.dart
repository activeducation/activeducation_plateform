import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../shared/widgets/buttons/gradient_button.dart';
import '../../../../shared/widgets/feedback/app_snackbar.dart';
import '../../../../shared/widgets/feedback/state_views.dart';
import '../../domain/entities/orientation_test.dart';
import '../bloc/orientation_bloc.dart';
import '../bloc/test_session_bloc.dart';

// Widgets prives extraits en parts (meme librairie, imports partages).
part 'test_execution/view_and_progress.dart';
part 'test_execution/question_widgets.dart';
part 'test_execution/slider_question.dart';

class TestExecutionPage extends StatelessWidget {
  final OrientationTest test;

  const TestExecutionPage({super.key, required this.test});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => TestSessionBloc()..add(StartTestSession(test)),
        ),
        BlocProvider(
          create: (context) => getIt<OrientationBloc>(),
        ),
      ],
      child: const _TestExecutionView(),
    );
  }
}
