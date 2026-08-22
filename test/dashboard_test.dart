import 'package:flutter_test/flutter_test.dart';
import 'package:mirror_scorpion_v4/app/mirror_scorpion_app.dart';

void main() {
  testWidgets('renders the reference hero, bubble control, and six-card grid', (tester) async {
    await tester.pumpWidget(const MirrorScorpionApp());

    expect(find.text('ميرور سكربيون'), findsOneWidget);
    expect(find.text('حيث تُصنع البدايات'), findsOneWidget);
    expect(find.text('تفعيل الفقاعة العائمة'), findsOneWidget);
    expect(find.text('ترجمة نصية'), findsOneWidget);
    expect(find.text('حوار مترجم'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('مستندات وعدسة'), 300);
    expect(find.text('مستندات وعدسة'), findsOneWidget);
    expect(find.text('قصص وإلهام'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('ألعاب 3D'), 300);
    expect(find.text('ألعاب 3D'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('الإعدادات'), 300);
    expect(find.text('الإعدادات'), findsOneWidget);
  });
}
