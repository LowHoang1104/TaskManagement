import 'package:flutter/material.dart';
import '../../../../app/theme/app_palette.dart';

/// Reusable building blocks for the TaskFlow redesign, ported from the
/// component vocabulary in `TaskFlow.dc.html` (soft cards, pill tags,
/// segmented filter pills, avatar stacks, progress bars, the accent button
/// and the bottom navigation bar).

// ─────────────────────────────────────────────────────────────────────────────
// Card + icon badge
// ─────────────────────────────────────────────────────────────────────────────

/// Rounded surface card with a hairline border (the default container in the
/// design). Radius 18, 1px border.
class TfCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? color;
  final Border? border;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadow;

  const TfCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
    this.color,
    this.border,
    this.onTap,
    this.shadow,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? p.surface,
        borderRadius: BorderRadius.circular(radius),
        border: border ?? Border.all(color: p.border),
        boxShadow: shadow,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      child: content,
    );
  }
}

/// The TaskFlow logo tile — accent-filled rounded square with the `task_alt`
/// glyph, used on the onboarding screens and headers.
class TfLogoTile extends StatelessWidget {
  final double size;
  final double radius;
  final double iconSize;
  final bool glow;
  const TfLogoTile({
    super.key,
    this.size = 52,
    this.radius = 15,
    this.iconSize = 28,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: p.accent,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: glow
            ? [
                BoxShadow(
                    color: p.accent.withValues(alpha: 0.5),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                    spreadRadius: -8)
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Icon(Icons.task_alt, size: iconSize, color: p.onAccent),
    );
  }
}

/// Rounded-square tinted icon container (e.g. project glyphs, notification
/// glyphs, form leading icons).
class TfIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double radius;
  final double? iconSize;
  final Color? background;

  const TfIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 34,
    this.radius = 10,
    this.iconSize,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? p.tint(color, 0.14),
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: color, size: iconSize ?? size * 0.55),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tags & pills
// ─────────────────────────────────────────────────────────────────────────────

/// Soft tag — colored text over a tinted background (priority / status / label
/// chips). If [color] is null it renders as the neutral "Normal/Low" tag.
class TfTag extends StatelessWidget {
  final String text;
  final Color? color;
  final double fontSize;

  const TfTag({super.key, required this.text, this.color, this.fontSize = 9});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = color ?? p.text2;
    final bg = color == null ? p.surface3 : p.tint(color!, 0.14);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: c,
          height: 1.1,
        ),
      ),
    );
  }
}

/// Segmented / filter pill (radius 999). Selected = accent fill, unselected =
/// surface-2 with a border. [tone] recolors the selected/looked state (e.g.
/// the red "Overdue" pill).
class TfPill extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? tone;
  final VoidCallback? onTap;

  const TfPill({
    super.key,
    required this.label,
    this.selected = false,
    this.tone,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final accent = tone ?? p.accent;
    final Color bg;
    final Color fg;
    final Border? border;
    if (selected) {
      bg = accent;
      fg = p.onAccent;
      border = null;
    } else if (tone != null) {
      bg = p.tint(tone!, 0.12);
      fg = tone!;
      border = null;
    } else {
      bg = p.surface2;
      fg = p.text2;
      border = Border.all(color: p.border);
    }
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: border,
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg),
        ),
      ),
    );
  }
}

/// Uppercase section label ("TODAY", "NEW", "EARLIER", "STATUS").
class TfSectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;
  const TfSectionLabel(this.text, {super.key, this.padding = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: padding,
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          color: p.text3,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatars
// ─────────────────────────────────────────────────────────────────────────────

/// Circular initials avatar.
class TfAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  final double size;
  final Color? borderColor;
  final Color? textColor;

  const TfAvatar({
    super.key,
    required this.initials,
    required this.color,
    this.size = 24,
    this.borderColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: borderColor != null ? Border.all(color: borderColor!, width: 2) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w800,
          color: textColor ?? Colors.white,
        ),
      ),
    );
  }
}

/// A person rendered as (initials, color).
class TfMember {
  final String initials;
  final Color color;
  const TfMember(this.initials, this.color);
}

/// Overlapping avatar stack with an optional "+N" bubble.
class TfAvatarStack extends StatelessWidget {
  final List<TfMember> members;
  final int overflow;
  final double size;

  const TfAvatarStack({
    super.key,
    required this.members,
    this.overflow = 0,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final step = size * 0.66; // horizontal advance between avatars
    final total = members.length + (overflow > 0 ? 1 : 0);
    if (total == 0) return const SizedBox.shrink();
    final width = size + (total - 1) * step;
    final children = <Widget>[
      for (var i = 0; i < members.length; i++)
        Positioned(
          left: i * step,
          child: TfAvatar(
            initials: members[i].initials,
            color: members[i].color,
            size: size,
            borderColor: p.surface,
          ),
        ),
      if (overflow > 0)
        Positioned(
          left: members.length * step,
          child: TfAvatar(
            initials: '+$overflow',
            color: p.surface3,
            size: size,
            borderColor: p.surface,
            textColor: p.text2,
          ),
        ),
    ];
    return SizedBox(width: width, height: size, child: Stack(children: children));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress + status dot
// ─────────────────────────────────────────────────────────────────────────────

/// Rounded progress track with a colored fill.
class TfProgressBar extends StatelessWidget {
  final double value; // 0..1
  final Color? color;
  final double height;

  const TfProgressBar({super.key, required this.value, this.color, this.height = 8});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: Stack(
        children: [
          Container(height: height, color: p.surface3),
          FractionallySizedBox(
            widthFactor: value.clamp(0, 1),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: color ?? p.accent,
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small rounded status square (used before column / list group titles).
class TfStatusDot extends StatelessWidget {
  final Color color;
  final double size;
  const TfStatusDot({super.key, required this.color, this.size = 9});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.35),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Buttons
// ─────────────────────────────────────────────────────────────────────────────

/// The accent CTA used across the design (Sign in, Create task, Send invite…).
/// Filled accent with a soft accent-colored drop shadow.
class TfPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool loading;
  final EdgeInsetsGeometry padding;

  const TfPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
    this.loading = false,
    this.padding = const EdgeInsets.symmetric(vertical: 15),
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(
          color: p.accent,
          borderRadius: BorderRadius.circular(13),
          boxShadow: [
            BoxShadow(
              color: p.accent.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 12),
              spreadRadius: -10,
            ),
          ],
        ),
        child: loading
            ? SizedBox(
                height: 20,
                width: 20,
                child: Center(
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.4, color: p.onAccent),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: p.onAccent),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: p.onAccent,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inputs
// ─────────────────────────────────────────────────────────────────────────────

/// [InputDecoration] for a [TextField] that lives inside one of the custom
/// bordered containers in this file.
///
/// The global `inputDecorationTheme` supplies `enabledBorder`/`focusedBorder`/
/// error borders plus a fill. `InputDecoration.border` is only the *fallback*,
/// so setting `border: InputBorder.none` alone does NOT suppress them — the
/// theme still paints a second rounded box (and fill) inside ours. This strips
/// every one of them so the surrounding container is the only visible box.
InputDecoration tfBareInput({
  String? hint,
  TextStyle? hintStyle,
  EdgeInsetsGeometry contentPadding = EdgeInsets.zero,
  String? counterText,
}) {
  return InputDecoration(
    isDense: true,
    filled: false,
    contentPadding: contentPadding,
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    hintText: hint,
    hintStyle: hintStyle,
    counterText: counterText,
  );
}

/// Read-only sibling of [TfLabeledField]: same bordered box with the inner
/// uppercase label, but wrapping arbitrary content (e.g. a workspace picker).
/// Keeps non-input rows visually consistent with the text fields.
class TfLabeledBox extends StatelessWidget {
  final String label;
  final Widget child;
  final VoidCallback? onTap;

  const TfLabeledBox({
    super.key,
    required this.label,
    required this.child,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: p.border2, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.7,
                color: p.text3,
              ),
            ),
            const SizedBox(height: 4),
            child,
          ],
        ),
      ),
    );
  }
}

/// Bordered input box with an inner uppercase label and optional leading icon,
/// matching the form fields in the design. Shows the accent focus ring when
/// active (mirrors the `box-shadow: 0 0 0 3px accent-weak` treatment).
class TfLabeledField extends StatefulWidget {
  final String label;
  final TextEditingController? controller;
  final IconData? icon;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final bool autofocus;
  final int maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const TfLabeledField({
    super.key,
    required this.label,
    this.controller,
    this.icon,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  State<TfLabeledField> createState() => _TfLabeledFieldState();
}

class _TfLabeledFieldState extends State<TfLabeledField> {
  late final FocusNode _node = FocusNode()..addListener(() => setState(() {}));
  late bool _obscured = widget.obscure;

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final focused = _node.hasFocus;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: focused ? p.accent : p.border2,
          width: 1.5,
        ),
        boxShadow: focused
            ? [BoxShadow(color: p.accentWeak, blurRadius: 0, spreadRadius: 3)]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.label.toUpperCase(),
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: focused ? p.accent : p.text3,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: widget.maxLines > 1
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 18, color: p.text3),
                const SizedBox(width: 9),
              ],
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _node,
                  autofocus: widget.autofocus,
                  obscureText: _obscured,
                  keyboardType: widget.keyboardType,
                  onChanged: widget.onChanged,
                  onSubmitted: widget.onSubmitted,
                  // obscureText requires a single line.
                  maxLines: widget.obscure ? 1 : widget.maxLines,
                  minLines: widget.obscure ? null : widget.minLines,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: p.text,
                  ),
                  decoration: tfBareInput(
                    hint: widget.hint,
                    hintStyle:
                        TextStyle(color: p.text3, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              if (widget.obscure)
                GestureDetector(
                  onTap: () => setState(() => _obscured = !_obscured),
                  child: Icon(
                    _obscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    size: 18,
                    color: p.text3,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom navigation
// ─────────────────────────────────────────────────────────────────────────────

class TfNavItem {
  final IconData icon;
  final String label;
  const TfNavItem(this.icon, this.label);
}

/// The 4-tab bottom navigation from the design (active tab shows an accent
/// pill behind the icon and an accent label).
class TfBottomNav extends StatelessWidget {
  final List<TfNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const TfBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(top: BorderSide(color: p.border)),
      ),
      padding: EdgeInsets.only(
        top: 8,
        bottom: 8 + MediaQuery.of(context).padding.bottom,
        left: 6,
        right: 6,
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 3),
                      decoration: BoxDecoration(
                        color: i == currentIndex ? p.accentWeak : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Icon(
                        items[i].icon,
                        size: 22,
                        color: i == currentIndex ? p.accent : p.text3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[i].label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: i == currentIndex ? p.accent : p.text3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
