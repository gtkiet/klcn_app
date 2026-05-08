// lib/core/errors/app_error_widget.dart

import 'package:flutter/material.dart';
import 'app_exception.dart';

/// Widget hiển thị lỗi từ [AppException].
///
/// - Nếu chỉ có một lỗi → hiển thị `message` dạng Text đơn.
/// - Nếu có nhiều lỗi   → hiển thị danh sách bullet.
class AppErrorWidget extends StatelessWidget {
  final AppException error;

  const AppErrorWidget({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final msgs = error.messages;

    if (msgs == null || msgs.length <= 1) {
      return _ErrorText(error.message);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: msgs.map((msg) => _ErrorText('• $msg')).toList(),
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String text;
  const _ErrorText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      // style: TextStyle(color: Theme.of(context).colorScheme.error),
      style: TextStyle(color: Colors.red),
    );
  }
}
