import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/features/chess_club_screen.dart';

void main() {
  testWidgets('ChessClubScreen يبني الشاشة', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: ChessClubScreen()),
    );
    expect(find.byType(ChessClubScreen), findsOneWidget);
  });
}
