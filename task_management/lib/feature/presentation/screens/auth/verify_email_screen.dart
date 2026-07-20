import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/routes/app_routes.dart';
import '../../../../app/theme/app_palette.dart';
import '../../taskflow/widgets/tf_widgets.dart';

/// Verify email — redesigned to match `TaskFlow.dc.html` (05 — Add & flows).
/// Reached after registering; confirms a 6-digit code then enters the app.
class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, this.email = 'an.nguyen@acme.co'});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const int _len = 6;
  late final List<TextEditingController> _controllers =
      List.generate(_len, (_) => TextEditingController());
  late final List<FocusNode> _nodes = List.generate(_len, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    // Pre-fill to mirror the mockup state (4 · 9 · 2 · 7).
    const seed = ['4', '9', '2', '7'];
    for (var i = 0; i < seed.length; i++) {
      _controllers[i].text = seed[i];
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _nodes[3].requestFocus());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onChanged(int i, String v) {
    if (v.isNotEmpty && i < _len - 1) {
      _nodes[i + 1].requestFocus();
    } else if (v.isEmpty && i > 0) {
      _nodes[i - 1].requestFocus();
    }
    setState(() {});
  }

  void _submit() {
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 12, 26, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: Icon(Icons.arrow_back_rounded, size: 24, color: p.text2),
              ),
              const SizedBox(height: 26),
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: p.accentWeak,
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.mark_email_read_rounded,
                    size: 32, color: p.accent),
              ),
              const SizedBox(height: 24),
              Text('Verify your email',
                  style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1.15,
                      color: p.text)),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: 'We sent a 6-digit code to\n',
                  style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                      color: p.text3),
                  children: [
                    TextSpan(
                        text: widget.email,
                        style: TextStyle(
                            fontWeight: FontWeight.w800, color: p.text2)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  for (var i = 0; i < _len; i++) ...[
                    Expanded(child: _OtpBox(
                      controller: _controllers[i],
                      focusNode: _nodes[i],
                      onChanged: (v) => _onChanged(i, v),
                    )),
                    if (i < _len - 1) const SizedBox(width: 9),
                  ],
                ],
              ),
              const SizedBox(height: 22),
              TfPrimaryButton(
                label: 'Verify & continue',
                icon: Icons.check_rounded,
                onTap: _submit,
              ),
              const SizedBox(height: 20),
              Center(
                child: Text.rich(
                  TextSpan(
                    text: "Didn't get it?  ",
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: p.text3),
                    children: [
                      TextSpan(
                          text: 'Resend in 0:24',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, color: p.accent)),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: p.surface2,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: p.border),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 20, color: p.text3),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Check spam if it doesn't arrive within a minute.",
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            color: p.text3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final focused = focusNode.hasFocus;
    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: focused ? p.surface : p.surface2,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: focused ? p.accent : p.border2,
            width: focused ? 2 : 1.5,
          ),
          boxShadow: focused
              ? [BoxShadow(color: p.accentWeak, blurRadius: 0, spreadRadius: 3)]
              : null,
        ),
        alignment: Alignment.center,
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: focused ? p.accent : p.text,
          ),
          decoration: tfBareInput(counterText: ''),
        ),
      ),
    );
  }
}
