import 'dart:math' as math;

import '../domain/gesture_point.dart';
import '../domain/gesture_template.dart';

const finishSymbol = 'S';

final symbolTemplates = <GestureTemplate>[
  GestureTemplate(label: '0', strokes: [_arc(50, 50, 28, 45, 270, 630)]),
  GestureTemplate(label: '1', strokes: [_line(50, 5, 50, 95)]),
  GestureTemplate(
    label: '1',
    strokes: [
      [..._line(32, 24, 50, 5), ..._line(50, 5, 50, 95)],
    ],
  ),
  GestureTemplate(
    label: '2',
    strokes: [
      [
        ..._arc(50, 30, 25, 25, 180, 390),
        ..._line(72, 42, 25, 95),
        ..._line(25, 95, 78, 95),
      ],
    ],
  ),
  GestureTemplate(
    label: '3',
    strokes: [
      [..._arc(50, 28, 23, 22, 200, 450), ..._arc(50, 72, 26, 23, 270, 520)],
    ],
  ),
  GestureTemplate(
    label: '4',
    strokes: [
      [..._line(62, 5, 20, 65), ..._line(20, 65, 82, 65)],
      _line(62, 30, 62, 95),
    ],
  ),
  GestureTemplate(
    label: '4',
    strokes: [
      [..._line(28, 5, 24, 60), ..._line(24, 60, 82, 60)],
      _line(66, 25, 66, 95),
    ],
  ),
  GestureTemplate(
    label: '5',
    strokes: [
      [
        ..._line(80, 5, 28, 5),
        ..._line(28, 5, 26, 46),
        ..._arc(50, 68, 28, 26, 210, 495),
      ],
    ],
  ),
  GestureTemplate(
    label: '6',
    strokes: [
      [..._arc(70, 62, 42, 54, 255, 180), ..._arc(52, 72, 24, 23, 180, -180)],
    ],
  ),
  GestureTemplate(
    label: '7',
    strokes: [
      [..._line(20, 5, 80, 5), ..._line(80, 5, 40, 95)],
    ],
  ),
  GestureTemplate(
    label: '8',
    strokes: [
      [..._arc(50, 27, 20, 22, 90, -270), ..._arc(50, 72, 25, 23, 270, 630)],
    ],
  ),
  GestureTemplate(
    label: '9',
    strokes: [
      [..._arc(48, 30, 24, 25, 0, -360), ..._line(72, 30, 66, 95)],
    ],
  ),
  GestureTemplate(
    label: finishSymbol,
    strokes: [
      [..._arc(50, 28, 25, 23, -30, -270), ..._arc(50, 73, 25, 22, -90, 150)],
    ],
  ),
];

GestureStroke _line(double x1, double y1, double x2, double y2) {
  const steps = 12;
  return [
    for (var i = 0; i <= steps; i++)
      GesturePoint(x1 + (x2 - x1) * i / steps, y1 + (y2 - y1) * i / steps),
  ];
}

GestureStroke _arc(
  double cx,
  double cy,
  double rx,
  double ry,
  double fromDegrees,
  double toDegrees,
) {
  final steps = math.max(8, ((toDegrees - fromDegrees).abs() / 10).round());
  return [
    for (var i = 0; i <= steps; i++)
      _pointOnEllipse(
        cx,
        cy,
        rx,
        ry,
        fromDegrees + (toDegrees - fromDegrees) * i / steps,
      ),
  ];
}

GesturePoint _pointOnEllipse(
  double cx,
  double cy,
  double rx,
  double ry,
  double degrees,
) {
  final radians = degrees * math.pi / 180;
  return GesturePoint(cx + rx * math.cos(radians), cy + ry * math.sin(radians));
}
