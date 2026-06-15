part of 'my_page_screen.dart';

class _EditIconPainter extends CustomPainter {
  const _EditIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 16;
    final p = Paint()
      ..color = _C.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.33264 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final rect = Path()
      ..moveTo(8.0 * r, 2.0 * r)
      ..lineTo(3.332 * r, 2.0 * r)
      ..cubicTo(2.963 * r, 2.0 * r, 2.609 * r, 2.14 * r, 2.389 * r, 2.389 * r)
      ..cubicTo(
        2.139 * r,
        2.639 * r,
        1.999 * r,
        2.978 * r,
        1.999 * r,
        3.332 * r,
      )
      ..lineTo(1.999 * r, 12.66 * r)
      ..cubicTo(
        1.999 * r,
        13.014 * r,
        2.139 * r,
        13.353 * r,
        2.389 * r,
        13.602 * r,
      )
      ..cubicTo(
        2.639 * r,
        13.852 * r,
        2.978 * r,
        13.993 * r,
        3.332 * r,
        13.993 * r,
      )
      ..lineTo(12.66 * r, 13.993 * r)
      ..cubicTo(
        13.014 * r,
        13.993 * r,
        13.353 * r,
        13.852 * r,
        13.602 * r,
        13.602 * r,
      )
      ..cubicTo(
        13.852 * r,
        13.353 * r,
        13.993 * r,
        13.014 * r,
        13.993 * r,
        12.66 * r,
      )
      ..lineTo(13.993 * r, 7.996 * r);
    canvas.drawPath(rect, p);
    canvas.drawLine(
      Offset(12.244 * r, 1.749 * r),
      Offset(14.243 * r, 3.748 * r),
      p,
    );
    final pencil = Path()
      ..moveTo(12.244 * r, 1.749 * r)
      ..cubicTo(
        12.509 * r,
        1.484 * r,
        12.868 * r,
        1.335 * r,
        13.243 * r,
        1.335 * r,
      )
      ..cubicTo(
        13.618 * r,
        1.335 * r,
        13.977 * r,
        1.484 * r,
        14.243 * r,
        1.749 * r,
      )
      ..cubicTo(
        14.508 * r,
        2.014 * r,
        14.657 * r,
        2.374 * r,
        14.657 * r,
        2.748 * r,
      )
      ..cubicTo(
        14.657 * r,
        3.123 * r,
        14.508 * r,
        3.483 * r,
        14.243 * r,
        3.748 * r,
      )
      ..lineTo(8.237 * r, 9.754 * r)
      ..cubicTo(
        8.079 * r,
        9.912 * r,
        7.883 * r,
        10.028 * r,
        7.669 * r,
        10.091 * r,
      )
      ..lineTo(5.754 * r, 10.65 * r)
      ..cubicTo(
        5.697 * r,
        10.667 * r,
        5.636 * r,
        10.668 * r,
        5.578 * r,
        10.653 * r,
      )
      ..cubicTo(
        5.521 * r,
        10.638 * r,
        5.468 * r,
        10.608 * r,
        5.425 * r,
        10.566 * r,
      )
      ..cubicTo(
        5.383 * r,
        10.524 * r,
        5.353 * r,
        10.471 * r,
        5.338 * r,
        10.413 * r,
      )
      ..cubicTo(
        5.323 * r,
        10.355 * r,
        5.324 * r,
        10.295 * r,
        5.341 * r,
        10.237 * r,
      )
      ..lineTo(5.901 * r, 8.323 * r)
      ..cubicTo(5.964 * r, 8.108 * r, 6.08 * r, 7.913 * r, 6.238 * r, 7.755 * r)
      ..lineTo(12.244 * r, 1.749 * r)
      ..close();
    canvas.drawPath(pencil, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EditHeaderIconPainter extends _EditIconPainter {
  const _EditHeaderIconPainter();
}

class _CopyIconPainter extends CustomPainter {
  const _CopyIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 20;
    final p = Paint()
      ..color = _C.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.66663 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final front = Path()
      ..addRRect(
        RRect.fromLTRBR(
          6.667 * r,
          6.667 * r,
          18.333 * r,
          18.333 * r,
          Radius.circular(1.667 * r),
        ),
      );
    canvas.drawPath(front, p);
    final back = Path()
      ..moveTo(13.333 * r, 6.667 * r)
      ..lineTo(13.333 * r, 3.333 * r)
      ..cubicTo(
        13.333 * r,
        2.413 * r,
        12.583 * r,
        1.667 * r,
        11.666 * r,
        1.667 * r,
      )
      ..lineTo(3.333 * r, 1.667 * r)
      ..cubicTo(
        2.416 * r,
        1.667 * r,
        1.667 * r,
        2.413 * r,
        1.667 * r,
        3.333 * r,
      )
      ..lineTo(1.667 * r, 11.666 * r)
      ..cubicTo(
        1.667 * r,
        12.583 * r,
        2.416 * r,
        13.333 * r,
        3.333 * r,
        13.333 * r,
      )
      ..lineTo(6.667 * r, 13.333 * r);
    canvas.drawPath(back, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CalendarIconPainter extends CustomPainter {
  const _CalendarIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 16;
    final p = Paint()
      ..color = _C.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.33264 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawLine(
      Offset(5.331 * r, 1.333 * r),
      Offset(5.331 * r, 3.998 * r),
      p,
    );
    canvas.drawLine(
      Offset(10.661 * r, 1.333 * r),
      Offset(10.661 * r, 3.998 * r),
      p,
    );
    final rect = Path()
      ..addRRect(
        RRect.fromLTRBR(
          1.999 * r,
          2.666 * r,
          13.993 * r,
          14.659 * r,
          Radius.circular(1.333 * r),
        ),
      );
    canvas.drawPath(rect, p);
    canvas.drawLine(
      Offset(1.999 * r, 6.663 * r),
      Offset(13.993 * r, 6.663 * r),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ClockIconPainter extends CustomPainter {
  const _ClockIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 16;
    final p = Paint()
      ..color = _C.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.33264 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawCircle(Offset(8 * r, 8 * r), 6.663 * r, p);
    canvas.drawLine(Offset(8 * r, 3.998 * r), Offset(8 * r, 7.996 * r), p);
    canvas.drawLine(Offset(8 * r, 7.996 * r), Offset(10.661 * r, 9.329 * r), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PinIconPainter extends CustomPainter {
  const _PinIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 16;
    final p = Paint()
      ..color = _C.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.33264 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final pin = Path()
      ..moveTo(13.326 * r, 6.663 * r)
      ..cubicTo(
        13.326 * r,
        9.99 * r,
        9.635 * r,
        13.455 * r,
        8.396 * r,
        14.525 * r,
      )
      ..cubicTo(
        8.281 * r,
        14.612 * r,
        8.14 * r,
        14.659 * r,
        7.996 * r,
        14.659 * r,
      )
      ..cubicTo(
        7.851 * r,
        14.659 * r,
        7.711 * r,
        14.612 * r,
        7.595 * r,
        14.525 * r,
      )
      ..cubicTo(
        6.356 * r,
        13.455 * r,
        2.665 * r,
        9.99 * r,
        2.665 * r,
        6.663 * r,
      )
      ..cubicTo(
        2.665 * r,
        5.249 * r,
        3.227 * r,
        3.893 * r,
        4.227 * r,
        2.894 * r,
      )
      ..cubicTo(
        5.226 * r,
        1.894 * r,
        6.582 * r,
        1.333 * r,
        7.996 * r,
        1.333 * r,
      )
      ..cubicTo(
        9.41 * r,
        1.333 * r,
        10.765 * r,
        1.894 * r,
        11.765 * r,
        2.894 * r,
      )
      ..cubicTo(
        12.765 * r,
        3.893 * r,
        13.326 * r,
        5.249 * r,
        13.326 * r,
        6.663 * r,
      )
      ..close();
    canvas.drawPath(pin, p);
    canvas.drawCircle(Offset(7.996 * r, 6.663 * r), 1.999 * r, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LogoutIconPainter extends CustomPainter {
  const _LogoutIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 20;
    final p = Paint()
      ..color = _C.whiteDim
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.66663 * r
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final door = Path()
      ..moveTo(7.5 * r, 17.5 * r)
      ..lineTo(4.167 * r, 17.5 * r)
      ..cubicTo(
        3.725 * r,
        17.5 * r,
        3.301 * r,
        17.324 * r,
        2.988 * r,
        17.012 * r,
      )
      ..cubicTo(2.676 * r, 16.699 * r, 2.5 * r, 16.275 * r, 2.5 * r, 15.833 * r)
      ..lineTo(2.5 * r, 4.167 * r)
      ..cubicTo(2.5 * r, 3.725 * r, 2.676 * r, 3.301 * r, 2.988 * r, 2.988 * r)
      ..cubicTo(3.301 * r, 2.676 * r, 3.725 * r, 2.5 * r, 4.167 * r, 2.5 * r)
      ..lineTo(7.5 * r, 2.5 * r);
    canvas.drawPath(door, p);
    canvas.drawLine(
      Offset(13.333 * r, 14.166 * r),
      Offset(17.5 * r, 10 * r),
      p,
    );
    canvas.drawLine(Offset(17.5 * r, 10 * r), Offset(13.333 * r, 5.833 * r), p);
    canvas.drawLine(Offset(17.5 * r, 10 * r), Offset(7.5 * r, 10 * r), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
