import 'dart:async';

import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

class AppAlerts {
  static bool _tokenDialogVisible = false;

  static void showTokenExhaustedDialog() {
    if (_tokenDialogVisible) {
      return;
    }

    final context = appNavigatorKey.currentContext;
    if (context == null) {
      return;
    }

    _tokenDialogVisible = true;
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('토큰 사용량 안내'),
            content: const Text(
              'Prokerala 토큰을 모두 사용했거나 호출 한도에 도달했습니다. '
              '잠시 후 다시 시도하거나 Prokerala 대시보드에서 사용량을 확인해 주세요.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          );
        },
      ).whenComplete(() => _tokenDialogVisible = false),
    );
  }
}
