import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme.dart';
import '../providers.dart';
import '../services/waitlist_service.dart';

class WaitlistCapture extends ConsumerStatefulWidget {
  const WaitlistCapture({
    super.key,
    required this.source,
    this.compact = false,
  });

  final WaitlistSource source;

  // compact=true uses a smaller vertical rhythm for modal/footer placements.
  final bool compact;

  @override
  ConsumerState<WaitlistCapture> createState() => _WaitlistCaptureState();
}

enum _Status { idle, submitting, success, error }

class _WaitlistCaptureState extends ConsumerState<WaitlistCapture> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  _Status _status = _Status.idle;
  String? _message;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_status == _Status.submitting) return;
    setState(() {
      _status = _Status.submitting;
      _message = null;
    });

    final service = ref.read(waitlistServiceProvider);
    final result = await service.submit(
      email: _controller.text,
      source: widget.source,
    );

    if (!mounted) return;
    switch (result) {
      case WaitlistSuccess():
        setState(() {
          _status = _Status.success;
          _message = null;
        });
      case WaitlistInvalid(reason: final reason):
        setState(() {
          _status = _Status.error;
          _message = reason;
        });
      case WaitlistFailure(message: final msg):
        setState(() {
          _status = _Status.error;
          _message = msg;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_status == _Status.success) {
      return _SuccessBlock(compact: widget.compact);
    }

    final labelGap = widget.compact ? 20.0 : 28.0;
    final bodyGap = widget.compact ? 14.0 : 18.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '// WAITLIST',
          style: _tokens.monoSmall(color: _tokens.subtle),
        ),
        SizedBox(height: labelGap),
        Text(
          widget.compact ? 'Tell us you want it.' : 'Tell us\nyou want it.',
          style: _tokens.display(widget.compact ? 32 : 52),
        ),
        SizedBox(height: bodyGap),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            'The screen itself runs on your device. This is a separate signup — just your email, so we can tell you when the full screen is ready.',
            style: _tokens.body(
              widget.compact ? 14 : 15,
              color: _tokens.muted,
              height: 1.55,
            ),
          ),
        ),
        const SizedBox(height: 28),
        _EmailRow(
          controller: _controller,
          focus: _focus,
          submitting: _status == _Status.submitting,
          onSubmit: _submit,
        ),
        if (_status == _Status.error && _message != null) ...[
          const SizedBox(height: 14),
          Text(
            _message!,
            style: _tokens.monoSmall(color: const Color(0xFFF87171)),
          ),
        ],
      ],
    );
  }
}

class _EmailRow extends StatefulWidget {
  const _EmailRow({
    required this.controller,
    required this.focus,
    required this.submitting,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focus;
  final bool submitting;
  final VoidCallback onSubmit;

  @override
  State<_EmailRow> createState() => _EmailRowState();
}

class _EmailRowState extends State<_EmailRow> {
  bool _hoverBtn = false;

  @override
  Widget build(BuildContext context) {
    final btnColor = _hoverBtn ? _tokens.text : _tokens.signal;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: widget.focus,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              enabled: !widget.submitting,
              cursorColor: _tokens.signal,
              style: _tokens.body(16, color: _tokens.text),
              decoration: InputDecoration(
                hintText: 'you@domain.com',
                hintStyle: _tokens.body(16, color: _tokens.subtle),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: _underline(_tokens.hairline),
                enabledBorder: _underline(_tokens.hairline),
                focusedBorder: _underline(_tokens.signal, width: 1.4),
                disabledBorder: _underline(_tokens.hairline),
              ),
              onSubmitted: (_) => widget.onSubmit(),
            ),
          ),
          const SizedBox(width: 16),
          MouseRegion(
            cursor: widget.submitting
                ? SystemMouseCursors.basic
                : SystemMouseCursors.click,
            onEnter: (_) => setState(() => _hoverBtn = true),
            onExit: (_) => setState(() => _hoverBtn = false),
            child: GestureDetector(
              onTap: widget.submitting ? null : widget.onSubmit,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.submitting ? _tokens.subtle : btnColor,
                    width: 1,
                  ),
                ),
                child: widget.submitting
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.4,
                          color: _tokens.signal,
                        ),
                      )
                    : Text(
                        'NOTIFY ME',
                        style: _tokens.monoSmall(
                          color: btnColor,
                          weight: FontWeight.w600,
                          letterSpacing: 2.4,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  UnderlineInputBorder _underline(Color color, {double width = 1}) =>
      UnderlineInputBorder(borderSide: BorderSide(color: color, width: width));
}

class _SuccessBlock extends StatelessWidget {
  const _SuccessBlock({required this.compact});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '// WAITLIST',
          style: _tokens.monoSmall(color: _tokens.subtle),
        ),
        SizedBox(height: compact ? 20 : 28),
        Text(
          compact ? "You're on\nthe list." : "You're on\nthe list.",
          style: _tokens.display(compact ? 32 : 52),
        ),
        SizedBox(height: compact ? 14 : 18),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(
            "We'll email you when the full screen ships. Nothing else.",
            style: _tokens.body(
              compact ? 14 : 15,
              color: _tokens.muted,
              height: 1.55,
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Design tokens — mirrored from landing_page_view.dart. Kept private to this
// widget so the marketing surface stays coherent without leaking types.
// =============================================================================

class _Tokens {
  const _Tokens();

  Color get bg => BioliminalTheme.screenBackground;
  Color get hairline => const Color(0xFF17233F);
  Color get text => const Color(0xFFF8FAFC);
  Color get muted => const Color(0xFF94A3B8);
  Color get subtle => const Color(0xFF475569);
  Color get signal => BioliminalTheme.accent;

  TextStyle display(double size) => TextStyle(
        fontFamily: 'Fraunces',
        fontSize: size,
        fontWeight: FontWeight.w900,
        fontStyle: FontStyle.italic,
        color: text,
        height: 1.02,
        letterSpacing: -1.2,
      );

  TextStyle body(double size, {Color? color, double height = 1.55}) =>
      TextStyle(
        fontFamily: 'IBMPlexSans',
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color ?? text,
        height: height,
      );

  TextStyle monoSmall({
    Color? color,
    double letterSpacing = 2.6,
    FontWeight weight = FontWeight.w500,
  }) =>
      TextStyle(
        fontFamily: 'IBMPlexMono',
        fontSize: 11,
        fontWeight: weight,
        color: color ?? muted,
        letterSpacing: letterSpacing,
        height: 1.3,
      );
}

const _tokens = _Tokens();
