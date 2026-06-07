import 'package:flutter/material.dart';

/// 토스트 종류 — 디자인(글라스 알약)은 동일하고 아이콘만 달라진다.
enum GlassToastType { success, error }

/// 앱 전역 표준 토스트.
/// 어두운 글라스 알약 + 흰 원형 아이콘 + 텍스트 형태로 통일한다.
void showGlassToast(
  BuildContext context,
  String message, {
  GlassToastType type = GlassToastType.success,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      duration: const Duration(seconds: 2),
      content: _GlassToastBody(message: message, type: type),
    ),
  );
}

class _GlassToastBody extends StatelessWidget {
  const _GlassToastBody({required this.message, required this.type});

  final String message;
  final GlassToastType type;

  @override
  Widget build(BuildContext context) {
    final isError = type == GlassToastType.error;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF010512),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x26FFFFFF), width: 0.636),
        boxShadow: const [
          BoxShadow(color: Color(0x26000000), blurRadius: 4, offset: Offset(0, 4)),
          BoxShadow(color: Color(0x26000000), blurRadius: 20, offset: Offset(0, 5)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
            ),
            child: Icon(
              isError ? Icons.close_rounded : Icons.check_rounded,
              size: 15,
              color: const Color(0xFF010512),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
                fontFamily: 'Pretendard',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
