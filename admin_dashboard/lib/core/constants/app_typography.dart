import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static String get fontFamily => 'Hanken Grotesque';

  static TextStyle get heading1 => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.2);
  static TextStyle get heading2 => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3);
  static TextStyle get heading3 => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.4);
  static TextStyle get subtitle => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5);
  static TextStyle get body => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.5);
  static TextStyle get bodySmall => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5);
  static TextStyle get label => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary, letterSpacing: 0.3);
  static TextStyle get button => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 14, fontWeight: FontWeight.w600);
  static TextStyle get sidebarItem => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.sidebarText);
  static TextStyle get statValue => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.1);
  static TextStyle get statLabel => TextStyle(fontFamily: 'Hanken Grotesque', fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
}
