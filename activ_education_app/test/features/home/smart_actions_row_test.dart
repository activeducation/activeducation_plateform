import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:activ_education_app/features/home/presentation/widgets/smart_actions_row.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    );

void main() {
  testWidgets('affiche les deux accès rapides', (tester) async {
    await tester.pumpWidget(_wrap(SmartActionsRow(
      onRecommendations: () {},
      onTutor: () {},
    )));

    expect(find.text('Mes recommandations'), findsOneWidget);
    expect(find.text('Mon tuteur'), findsOneWidget);
  });

  // NB : on invoque `onTap` directement plutôt que `tester.tap()`. Un vrai tap
  // déclenche le splash Material 3, dont le shader (`ink_sparkle.frag`) ne se
  // décode pas dans cet environnement de test — un InkWell nu échoue de la même
  // façon. On vérifie donc le câblage des callbacks, pas le rendu du splash.
  testWidgets('chaque tuile est câblée sur son propre callback', (tester) async {
    var recommendations = 0;
    var tutor = 0;

    await tester.pumpWidget(_wrap(SmartActionsRow(
      onRecommendations: () => recommendations++,
      onTutor: () => tutor++,
    )));

    final inkWells = tester
        .widgetList<InkWell>(find.byType(InkWell))
        .where((w) => w.onTap != null)
        .toList();
    expect(inkWells.length, 2);

    inkWells[0].onTap!();
    expect(recommendations, 1);
    expect(tutor, 0);

    inkWells[1].onTap!();
    expect(tutor, 1);
    expect(recommendations, 1);
  });
}
