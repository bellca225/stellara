import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'glass.dart';

/// 요즘 앱 스타일의 휠(스크롤) 날짜 피커를 글라스 바텀시트로 띄운다.
/// 반환: 선택한 DateTime (취소 시 null).
Future<DateTime?> showGlassDatePicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  // 초기값을 허용 범위 안으로 보정 (CupertinoDatePicker assertion 방지)
  DateTime initial = initialDate;
  if (initial.isBefore(firstDate)) initial = firstDate;
  if (initial.isAfter(lastDate)) initial = lastDate;

  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _DatePickerSheet(
      initial: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

/// 요즘 앱 스타일의 휠(스크롤) 시간 피커를 글라스 바텀시트로 띄운다.
/// 반환: 선택한 TimeOfDay (취소 시 null).
Future<TimeOfDay?> showGlassTimePicker(
  BuildContext context, {
  required TimeOfDay initialTime,
}) {
  final now = DateTime.now();
  final initial = DateTime(
    now.year,
    now.month,
    now.day,
    initialTime.hour,
    initialTime.minute,
  );
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _TimePickerSheet(initial: initial),
  );
}

class _DatePickerSheet extends StatefulWidget {
  const _DatePickerSheet({
    required this.initial,
    required this.firstDate,
    required this.lastDate,
  });

  final DateTime initial;
  final DateTime firstDate;
  final DateTime lastDate;

  @override
  State<_DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<_DatePickerSheet> {
  late DateTime _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return _PickerScaffold(
      title: '생년월일 선택',
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: () => Navigator.of(context).pop(_value),
      child: _wheelTheme(
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          initialDateTime: widget.initial,
          minimumDate: widget.firstDate,
          maximumDate: widget.lastDate,
          dateOrder: DatePickerDateOrder.ymd,
          onDateTimeChanged: (d) => _value = d,
        ),
      ),
    );
  }
}

class _TimePickerSheet extends StatefulWidget {
  const _TimePickerSheet({required this.initial});

  final DateTime initial;

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late DateTime _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return _PickerScaffold(
      title: '출생 시간 선택',
      onCancel: () => Navigator.of(context).pop(),
      onConfirm: () => Navigator.of(context)
          .pop(TimeOfDay(hour: _value.hour, minute: _value.minute)),
      child: _wheelTheme(
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.time,
          initialDateTime: widget.initial,
          use24hFormat: false,
          onDateTimeChanged: (d) => _value = d,
        ),
      ),
    );
  }
}

/// 휠 피커 텍스트를 다크 글라스 배경에 맞게 흰색으로.
Widget _wheelTheme({required Widget child}) {
  return CupertinoTheme(
    data: const CupertinoThemeData(
      brightness: Brightness.dark,
      textTheme: CupertinoTextThemeData(
        dateTimePickerTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontFamily: 'Pretendard',
        ),
      ),
    ),
    child: SizedBox(height: 216, child: child),
  );
}

/// 글라스 바텀시트 공통 골격 (핸들 + 타이틀 + 휠 + 취소/확인).
class _PickerScaffold extends StatelessWidget {
  const _PickerScaffold({
    required this.title,
    required this.child,
    required this.onCancel,
    required this.onConfirm,
  });

  final String title;
  final Widget child;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F1E38), Color(0xFF0A1326)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0x1FFFFFFF), width: 0.8),
          boxShadow: kGlassShadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            // grab handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0x33FFFFFF),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                fontFamily: 'Pretendard',
              ),
            ),
            const SizedBox(height: 8),
            child,
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: GlassButton(
                      label: '취소',
                      isPrimary: false,
                      height: 52,
                      fontSize: 16,
                      onTap: onCancel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassButton(
                      label: '확인',
                      isPrimary: true,
                      height: 52,
                      fontSize: 16,
                      onTap: onConfirm,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
