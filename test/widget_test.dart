import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fruit_coloring_book/main.dart';
import 'package:fruit_coloring_book/viewmodels/coloring_viewmodel.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => ColoringViewModel())],
        child: const FruitColoringApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Fruit Coloring Book'), findsWidgets);
  });
}
