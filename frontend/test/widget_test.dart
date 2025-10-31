import 'package:flutter_test/flutter_test.dart';
import 'package:changapp_client/main.dart';

void main() {
  testWidgets('App construye sin errores', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.byType(MyApp), findsOneWidget);
  });
}
