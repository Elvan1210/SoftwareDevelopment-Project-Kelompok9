import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mypskd/config/theme.dart';

class AvatarWidget extends StatelessWidget {
  final String? photoUrl;
  final String initial;
  final bool isGroup;
  final double size;
  final Color? bgColor;
  final Color? textColor;

  const AvatarWidget({
    Key? key,
    this.photoUrl,
    required this.initial,
    this.isGroup = false,
    this.size = 56,
    this.bgColor,
    this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isGroup) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E7FF), // Sangat bersih, Light Indigo
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(size * 0.42),
            topRight: Radius.circular(size * 0.14),
            bottomLeft: Radius.circular(size * 0.42),
            bottomRight: Radius.circular(size * 0.14),
          ),
          border: Border.all(color: AppTheme.textLight, width: 2),
        ),
        alignment: Alignment.center,
        child: Icon(LucideIcons.users, color: const Color(0xFF3730A3), size: size * 0.5),
      );
    }

    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.primaryContainer,
          borderRadius: BorderRadius.circular(size * 0.28),
          border: Border.all(color: AppTheme.textLight, width: 2),
          image: DecorationImage(
            image: NetworkImage(photoUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor ?? AppTheme.primaryContainer,
        borderRadius: BorderRadius.circular(size * 0.28),
        border: Border.all(color: AppTheme.textLight, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: GoogleFonts.inter(
          color: textColor ?? const Color(0xFF244F3D),
          fontWeight: FontWeight.w800,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}
