import 'dart:async';

import 'package:flutter/material.dart';

import '../../common/l10n_extensions.dart';

/// Text button that disables itself for [cooldown] after each press,
/// showing the remaining seconds. Complements server-side rate limits.
class ResendCooldownButton extends StatefulWidget {
  const ResendCooldownButton({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.cooldown = const Duration(seconds: 60),
    this.startCoolingDown = true,
  });

  /// Returns `true` when the resend succeeded (starts a new cooldown).
  final Future<bool> Function() onPressed;
  final bool loading;
  final Duration cooldown;

  /// Start in cooldown (an email was just sent).
  final bool startCoolingDown;

  @override
  State<ResendCooldownButton> createState() => _ResendCooldownButtonState();
}

class _ResendCooldownButtonState extends State<ResendCooldownButton> {
  Timer? _timer;
  int _remaining = 0;

  @override
  void initState() {
    super.initState();
    if (widget.startCoolingDown) _start();
  }

  void _start() {
    _timer?.cancel();
    setState(() => _remaining = widget.cooldown.inSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _remaining--);
      if (_remaining <= 0) timer.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final coolingDown = _remaining > 0;
    return TextButton(
      onPressed: coolingDown || widget.loading
          ? null
          : () async {
              if (await widget.onPressed() && mounted) _start();
            },
      child: widget.loading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(
              coolingDown ? l10n.registerResendIn(_remaining) : l10n.registerResend,
            ),
    );
  }
}
