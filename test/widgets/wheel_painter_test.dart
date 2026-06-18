import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucky_wheel/pages/home/widgets/wheel_painter.dart';

void main() {
  group('WheelPainter', () {
    testWidgets('renders wheel with 4 options', (tester) async {
      const options = ['Pizza', 'Burger', 'Sushi', 'KFC'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: CustomPaint(
                  size: const Size(300, 300),
                  painter: WheelPainter(
                    options: options,
                    rotation: 0,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // The wheel should render without errors
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders wheel with many options', (tester) async {
      const options = [
        'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J',
        'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: CustomPaint(
                  size: const Size(300, 300),
                  painter: WheelPainter(
                    options: options,
                    rotation: 0,
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    });

    test('WheelPainter.shouldRepaint detects changes', () {
      const painter1 = WheelPainter(
        options: ['A', 'B'],
        rotation: 0.0,
      );
      const painter2 = WheelPainter(
        options: ['A', 'B'],
        rotation: 1.0,
      );
      const painter3 = WheelPainter(
        options: ['A', 'B', 'C'],
        rotation: 0.0,
      );

      expect(painter1.shouldRepaint(painter2), isTrue);
      expect(painter1.shouldRepaint(painter3), isTrue);
      expect(painter1.shouldRepaint(painter1), isFalse);
    });
  });
}
