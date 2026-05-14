// lib/widgets/shared_widgets.dart
// ─────────────────────────────────────────────
//  SPORT PLUS — SHARED WIDGETS
//  Tất cả widget dùng chung toàn app
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// // ════════════════════════════════════════════
// //  BRAND LOGO (Nhóm không muốn dùng logo)
// // ════════════════════════════════════════════
// class SpBrandLogo extends StatelessWidget {
//   final double size;
//   final Color bgColor;
//   final BorderRadius? borderRadius;

//   const SpBrandLogo({
//     super.key,
//     this.size = 88,
//     this.bgColor = Colors.white,
//     this.borderRadius,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final br = borderRadius ?? BorderRadius.circular(size * 0.22);
//     return Container(
//       width: size,
//       height: size,
//       decoration: BoxDecoration(
//         color: bgColor,
//         borderRadius: br,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withValues(alpha: 0.10),
//             blurRadius: 18,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.sports_soccer,
//             color: AppColors.primary,
//             size: size * 0.36,
//           ),
//           const SizedBox(height: 4),
//           RichText(
//             text: TextSpan(
//               children: [
//                 TextSpan(
//                   text: 'SPORT',
//                   style: TextStyle(
//                     color: AppColors.primary,
//                     fontSize: size * 0.12,
//                     fontWeight: FontWeight.w900,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//                 TextSpan(
//                   text: 'PLUS',
//                   style: TextStyle(
//                     color: AppColors.primaryLight,
//                     fontSize: size * 0.12,
//                     fontWeight: FontWeight.w900,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ════════════════════════════════════════════
//  APP NAME TEXT  ("SportPlus" italic)
// ════════════════════════════════════════════
class SpAppNameText extends StatelessWidget {
  final double fontSize;
  final Color color;

  const SpAppNameText({
    super.key,
    this.fontSize = 32,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'Sport',
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
            ),
          ),
          TextSpan(
            text: 'Plus',
            style: TextStyle(
              color: AppColors.primaryLight,
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════
//  FIELD LABEL  (uppercase spaced label)
// ════════════════════════════════════════════
class SpFieldLabel extends StatelessWidget {
  final String text;
  const SpFieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppText.fieldLabel);
  }
}

// ════════════════════════════════════════════
//  ERROR TEXT  (with icon)
// ════════════════════════════════════════════
class SpErrorText extends StatelessWidget {
  final String text;
  const SpErrorText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 13, color: AppColors.errorRed),
          const SizedBox(width: 4),
          Flexible(child: Text(text, style: AppText.errorStyle)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════
//  TEXT FIELD — standard outlined field
// ════════════════════════════════════════════
class SpTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;

  const SpTextField({
    super.key,
    required this.controller,
    required this.hintText,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.errorText,
    this.onChanged,
    this.maxLines = 1,
    this.focusNode,
    this.nextFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.fieldBg,
            borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
            border: Border.all(
              color: errorText != null ? AppColors.errorRed : AppColors.fieldBorder,
              width: errorText != null ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            focusNode: focusNode,
            textInputAction: nextFocusNode != null
                ? TextInputAction.next
                : TextInputAction.done,
            onSubmitted: nextFocusNode != null
                ? (_) => FocusScope.of(context).requestFocus(nextFocusNode)
                : null,
            onChanged: onChanged,
            style: const TextStyle(color: AppColors.textDark, fontSize: 15),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: maxLines > 1 ? 14 : 17,
              ),
              border: InputBorder.none,
              prefixIcon: prefixIcon != null
                  ? Padding(
                      padding: const EdgeInsets.only(left: 14, right: 10),
                      child: Icon(prefixIcon, color: AppColors.textHint, size: 20),
                    )
                  : null,
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              hintText: hintText,
              hintStyle: AppText.hintText,
            ),
          ),
        ),
        if (errorText != null) SpErrorText(errorText!),
      ],
    );
  }
}

// ════════════════════════════════════════════
//  PASSWORD FIELD
// ════════════════════════════════════════════
class SpPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final String hintText;

  const SpPasswordField({
    super.key,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    this.errorText,
    this.onChanged,
    this.hintText = '••••••••••',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.fieldBg,
            borderRadius: BorderRadius.circular(AppSpacing.fieldRadius),
            border: Border.all(
              color: errorText != null ? AppColors.errorRed : AppColors.fieldBorder,
              width: errorText != null ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            onChanged: onChanged,
            style: const TextStyle(color: AppColors.textDark, fontSize: 15),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
              border: InputBorder.none,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(left: 14, right: 10),
                child: Icon(Icons.lock_outline, color: AppColors.textHint, size: 20),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
              hintText: hintText,
              hintStyle: TextStyle(
                color: AppColors.textHint,
                fontSize: 15,
                letterSpacing: obscure ? 3 : 0,
              ),
              suffixIcon: GestureDetector(
                onTap: onToggle,
                child: Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: Icon(
                    obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textHint,
                    size: 20,
                  ),
                ),
              ),
              suffixIconConstraints:
                  const BoxConstraints(minWidth: 0, minHeight: 0),
            ),
          ),
        ),
        if (errorText != null) SpErrorText(errorText!),
      ],
    );
  }
}

// ════════════════════════════════════════════
//  PRIMARY BUTTON
// ════════════════════════════════════════════
class SpPrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onTap;
  final IconData? trailingIcon;

  const SpPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.trailingIcon = Icons.arrow_forward,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: AppSpacing.btnHeight,
        decoration: BoxDecoration(
          color: (isLoading || onTap == null)
              ? AppColors.primaryLight
              : AppColors.primary,
          borderRadius: BorderRadius.circular(AppSpacing.btnRadius),
          boxShadow: AppShadow.btn,
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label, style: AppText.btnLabel),
                  if (trailingIcon != null) ...[
                    const SizedBox(width: 10),
                    Icon(trailingIcon, color: Colors.white, size: 20),
                  ],
                ],
              ),
      ),
    );
  }
}

// ════════════════════════════════════════════
//  OUTLINE BUTTON
// ════════════════════════════════════════════
class SpOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final Color borderColor;
  final Color textColor;

  const SpOutlineButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.borderColor = AppColors.divider,
    this.textColor = AppColors.textDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: AppSpacing.btnHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.btnRadius),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════
//  OR DIVIDER
// ════════════════════════════════════════════
class SpOrDivider extends StatelessWidget {
  final String label;
  const SpOrDivider({super.key, this.label = 'HOẶC TIẾP TỤC VỚI'});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
        const SizedBox(width: 14),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textMid.withValues(alpha: 0.7),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(child: Divider(color: AppColors.divider, thickness: 1)),
      ],
    );
  }
}

// ════════════════════════════════════════════
//  SOCIAL BUTTON (Google / Facebook)
// ════════════════════════════════════════════
class SpSocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  const SpSocialButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.socialBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.socialBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textDark,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SpGoogleIcon extends StatelessWidget {
  const SpGoogleIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.socialBorder),
      ),
      child: const Center(
        child: Text(
          'G',
          style: TextStyle(
            color: AppColors.googleRed,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class SpFacebookIcon extends StatelessWidget {
  const SpFacebookIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: AppColors.facebookBlue,
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Center(
        child: Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════
//  STATUS BADGE
// ════════════════════════════════════════════
class SpStatusBadge extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color bgColor;

  const SpStatusBadge({
    super.key,
    required this.label,
    required this.textColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════
//  BOTTOM NAV BAR  (shared)
// ════════════════════════════════════════════
class SpBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const SpBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.navUnselected,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), label: 'Sân'),
        BottomNavigationBarItem(icon: Icon(Icons.history_outlined), label: 'Lịch sử'),
        BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Hồ sơ'),
      ],
    );
  }
}

// ════════════════════════════════════════════
//  DASHED LINE PAINTER
// ════════════════════════════════════════════
class SpDashPainter extends CustomPainter {
  final Color color;
  SpDashPainter({this.color = AppColors.dashedLine});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    const dashW = 6.0, gapW = 4.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x + dashW, 0), paint);
      x += dashW + gapW;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}

// ════════════════════════════════════════════
//  SECTION HEADER (title + "xem tất cả")
// ════════════════════════════════════════════
class SpSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SpSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (actionLabel != null)
          GestureDetector(
            onTap: onAction,
            child: Text(
              actionLabel!,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ════════════════════════════════════════════
//  CARD WRAPPER  (white card với shadow)
// ════════════════════════════════════════════
class SpCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double? radius;

  const SpCard({
    super.key,
    required this.child,
    this.padding,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(radius ?? AppSpacing.cardRadius),
        boxShadow: AppShadow.card,
      ),
      child: child,
    );
  }
}
