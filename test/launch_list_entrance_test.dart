import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unio_app/widgets/launch_list_entrance.dart';

Widget screen({bool ready = true, bool reduced = false, Object? contentKey}) =>
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduced),
        child: LaunchListEntrance(
          ready: ready,
          contentKey: contentKey,
          child: ListView.builder(
            itemCount: 30,
            itemBuilder: (_, index) => LaunchListItem(
              key: ValueKey(index),
              index: index,
              child: SizedBox(height: 100, child: Text('Item $index')),
            ),
          ),
        ),
      ),
    );

FadeTransition fade(WidgetTester tester, int index) =>
    tester.widget(find.descendant(
        of: find.byKey(ValueKey(index)),
        matching: find.byType(FadeTransition)));

void main() {
  testWidgets(
      'Each opening and new result staggers; ordinary rebuild and scroll do not',
      (tester) async {
    await tester.pumpWidget(screen(contentKey: 1));
    expect(fade(tester, 0).opacity.value, 0);
    await tester.pump(const Duration(milliseconds: 180));
    expect(fade(tester, 0).opacity.value,
        greaterThan(fade(tester, 2).opacity.value));
    final slide = tester.widget<SlideTransition>(find.descendant(
        of: find.byKey(const ValueKey(0)),
        matching: find.byType(SlideTransition)));
    expect(slide.position.value.dx, lessThan(0));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    for (final widget
        in tester.widgetList<FadeTransition>(find.byType(FadeTransition))) {
      expect(widget.opacity.value, 1);
    }
    await tester.drag(find.byType(ListView), const Offset(0, 1000));
    await tester.pumpAndSettle();
    await tester.pumpWidget(screen(contentKey: 1));
    expect(fade(tester, 0).opacity.value, 1);
    await tester.pumpWidget(screen(contentKey: 2));
    expect(fade(tester, 0).opacity.value, 0);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(screen(contentKey: 2));
    expect(fade(tester, 0).opacity.value, 0);
    await tester.pumpAndSettle();
  });

  testWidgets('Waits for results and respects reduced motion', (tester) async {
    await tester.pumpWidget(screen(ready: false));
    expect(fade(tester, 0).opacity.value, 1);
    await tester.pumpWidget(screen());
    expect(fade(tester, 0).opacity.value, 0);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(screen(reduced: true));
    expect(fade(tester, 0).opacity.value, 1);
    await tester.pumpWidget(screen(reduced: true, contentKey: 2));
    expect(fade(tester, 0).opacity.value, 1);
  });
}
