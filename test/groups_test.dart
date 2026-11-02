import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unio_app/config/brand.dart';
import 'package:unio_app/screens/gradebook_tab.dart';
import 'package:unio_app/services/groups_service.dart';
import 'package:unio_app/widgets/group_picker.dart';
import 'package:unio_app/widgets/portal_gate.dart';

const groups = ['ИЯ-АВБ-111', 'ИЯ-АБ-112', 'ЕН-ФББ-111'];

void main() {
  test('Search accepts partial numbers, casing, separators and keyboard layout',
      () {
    expect(searchGroups(groups, '111'), ['ЕН-ФББ-111', 'ИЯ-АВБ-111']);
    expect(searchGroups(groups, 'ия авб'), ['ИЯ-АВБ-111']);
    expect(searchGroups(groups, 'bz-fd,111'), ['ИЯ-АВБ-111']);
    expect(resolveGroup(groups, ' ия—авб 111 '), 'ИЯ-АВБ-111');
    expect(() => resolveGroup(groups, '111'),
        throwsA(isA<GroupDirectoryException>()));
    expect(() => resolveGroup(groups, 'НЕСУЩЕСТВУЕТ'),
        throwsA(isA<GroupDirectoryException>()));
  });

  testWidgets(
      'Picker selects canonical group and does not keep an edited selection valid',
      (tester) async {
    final controller = TextEditingController();
    final key = GlobalKey<GroupPickerState>();
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: Scaffold(
          body: SingleChildScrollView(
              child: GroupPicker(
                  key: key,
                  controller: controller,
                  enabled: true,
                  portal: false,
                  onChanged: () {},
                  onSubmit: () {},
                  load: () async => groups)),
        )));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'авб');
    await tester.pump();
    await tester.tap(find.text('ИЯ-АВБ-111'));
    await tester.pump();
    expect(controller.text, 'ИЯ-АВБ-111');
    expect(await key.currentState!.validate(), 'ИЯ-АВБ-111');
    await tester.enterText(find.byType(TextField), 'WRONG');
    await expectLater(
        key.currentState!.validate(), throwsA(isA<GroupDirectoryException>()));
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets(
      'Unavailable catalogue can retry, and never treats network error as unknown group',
      (tester) async {
    var available = false;
    final controller = TextEditingController(text: groups.first);
    final key = GlobalKey<GroupPickerState>();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: GroupPicker(
      key: key,
      controller: controller,
      enabled: true,
      portal: true,
      onChanged: () {},
      onSubmit: () {},
      load: () async {
        if (!available) throw Exception();
        return groups;
      },
    ))));
    await tester.pumpAndSettle();
    await expectLater(
        key.currentState!.validate(),
        throwsA(isA<GroupDirectoryException>().having(
            (e) => e.message, 'message', contains('Не удалось проверить'))));
    available = true;
    expect(await key.currentState!.validate(), groups.first);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets(
      'Guest gradebook describes grades, while requests retain their own copy',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: buildTheme(Brightness.dark),
        home: Scaffold(
            body: GradebookTab(
                isPortalMode: false, onUpgradeToPortal: (_, __) async {}))));
    await tester.pumpAndSettle();
    expect(find.text('Успеваемость'), findsOneWidget);
    expect(find.textContaining('Баллы, оценки'), findsOneWidget);
    expect(find.textContaining('список заявлений'), findsNothing);
    expect(find.text('Справки и заявления'), findsNothing);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: PortalGate(
                isPortalMode: false,
                modern: true,
                onUpgrade: (_, __) async {},
                featureName: 'Справки и заявления',
                icon: Icons.edit_document,
                builder: (_) => const SizedBox()))));
    await tester.pumpAndSettle();
    expect(find.text('Справки и заявления'), findsOneWidget);
  });
}
