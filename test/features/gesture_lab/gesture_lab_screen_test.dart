import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:slotly/core/app_strings.dart';
import 'package:slotly/features/gesture_lab/presentation/gesture_lab_screen.dart';

import '../../helpers/test_app.dart';

void main() {
  Future<void> pumpLab(WidgetTester tester) =>
      pumpScreen(tester, GestureLabScreen(clock: () => testNow));

  Future<void> openZone(WidgetTester tester, String title) async {
    await tester.ensureVisible(find.text(title));
    await tester.pumpAndSettle();
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
  }

  final card = find.byKey(const ValueKey('gesture-card'));

  testWidgets('tap selects and double tap toggles favorite', (tester) async {
    await pumpLab(tester);
    expect(find.text(AppStrings.gestureLabLogEmpty), findsOneWidget);

    await tester.tap(card);
    await tester.pumpAndSettle(kDoubleTapTimeout);
    expect(find.text(AppStrings.gestureCardSelected), findsOneWidget);
    expect(find.text(AppStrings.gestureLogTap), findsOneWidget);

    await tester.tap(card);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.gestureCardFavorite), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(find.text(AppStrings.gestureLogDoubleTapOn), findsOneWidget);
  });

  testWidgets('long press opens a menu whose actions are logged', (
    tester,
  ) async {
    await pumpLab(tester);

    await tester.longPress(card);
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.gestureMenuTitle), findsOneWidget);
    expect(find.text(AppStrings.gestureLogLongPress), findsOneWidget);

    await tester.tap(find.text(AppStrings.gestureMenuFavorite));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.gestureMenuTitle), findsNothing);
    expect(find.text(AppStrings.gestureCardFavorite), findsOneWidget);
  });

  testWidgets('horizontal drag shows direction and velocity', (tester) async {
    await pumpLab(tester);
    await openZone(tester, AppStrings.gestureZoneHorizontal);

    await tester.fling(
      find.byKey(const ValueKey('horizontal-drag-area')),
      const Offset(-250, 0),
      900,
    );
    await tester.pumpAndSettle();

    expect(
      find.text(AppStrings.gestureDirection(AppStrings.gestureDirectionLeft)),
      findsOneWidget,
    );
    expect(find.textContaining('Скорость:'), findsOneWidget);
    expect(
      find.textContaining(
        'Горизонтальный drag: ${AppStrings.gestureDirectionLeft}',
      ),
      findsOneWidget,
    );
  });

  testWidgets('vertical drag shows the distance', (tester) async {
    await pumpLab(tester);
    await openZone(tester, AppStrings.gestureZoneVertical);

    await tester.drag(
      find.byKey(const ValueKey('vertical-drag-area')),
      const Offset(0, 160),
    );
    await tester.pumpAndSettle();

    final logEntry = find.textContaining(
      'Вертикальный drag: ${AppStrings.gestureDirectionDown}',
    );
    expect(logEntry, findsOneWidget);
    final distance = int.parse(
      RegExp(r'на (\d+) dp')
          .firstMatch(tester.widget<Text>(logEntry).data!)!
          .group(1)!,
    );
    expect(distance, greaterThan(100));
  });

  testWidgets('pinch changes the scale and can be reset', (tester) async {
    await pumpLab(tester);
    await openZone(tester, AppStrings.gestureZoneScale);
    expect(find.text(AppStrings.gestureScale('1,0')), findsOneWidget);

    final center = tester.getCenter(find.byKey(const ValueKey('scale-area')));
    final first = await tester.startGesture(center - const Offset(20, 0));
    final second = await tester.startGesture(
      center + const Offset(20, 0),
      pointer: 2,
    );
    await tester.pump();
    for (var i = 0; i < 4; i++) {
      await first.moveBy(const Offset(-10, 0));
      await second.moveBy(const Offset(10, 0));
      await tester.pump();
    }
    await first.up();
    await second.up();
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.gestureScale('1,0')), findsNothing);
    expect(find.textContaining('Pinch: масштаб'), findsOneWidget);

    await tester.tap(find.text(AppStrings.gestureScaleReset));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.gestureScale('1,0')), findsOneWidget);
  });

  testWidgets('journal can be cleared', (tester) async {
    await pumpLab(tester);
    await tester.longPress(card);
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(200, 100));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(AppStrings.gestureLabClearLog));
    await tester.pump();
    expect(find.text(AppStrings.gestureLabLogEmpty), findsOneWidget);
  });
}
