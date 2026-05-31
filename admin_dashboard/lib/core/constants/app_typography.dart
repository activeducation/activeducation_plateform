import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static String get fontFamily => GoogleFonts.getFont('Hanken Grotesque').fontFamily!;

  static TextStyle get heading1 => GoogleFonts.getFont('Hanken Grotesque', fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.2);
  static TextStyle get heading2 => GoogleFonts.getFont('Hanken Grotesque', fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3);
  static TextStyle get heading3 => GoogleFonts.getFont('Hanken Grotesque', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4);
  static TextStyle get subtitle => GoogleFonts.getFont('Hanken Grotesque', fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5);
  static TextStyle get body => GoogleFonts.getFont('Hanken Grotesque', fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.5);
  static TextStyle get bodySmall => GoogleFonts.getFont('Hanken Grotesque', fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5);
  static TextStyle get label => GoogleFonts.getFont('Hanken Grotesque', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary, letterSpacing: 0.3);
  static TextStyle get button => GoogleFonts.getFont('Hanken Grotesque', fontSize: 14, fontWeight: FontWeight.w600);
  static TextStyle get sidebarItem => GoogleFonts.getFont('Hanken Grotesque', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.sidebarText);
  static TextStyle get statValue => GoogleFonts.getFont('Hanken Grotesque', fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.1);
  static TextStyle get statLabel => GoogleFonts.getFont('Hanken Grotesque', fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
}
