import 'package:flutter_test/flutter_test.dart';
import 'package:coder_app/main.dart';
import 'package:provider/provider.dart';
import 'package:coder_app/providers/agent_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AgentProvider(),
        child: const CoderApp(),
      ),
    );
    expect(find.text('Coder'), findsAny);
  });
}
