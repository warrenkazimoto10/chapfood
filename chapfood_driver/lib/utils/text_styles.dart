import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class AppTextStyles {
  // Styles pour le Splash Screen
  static TextStyle splashTitle = GoogleFonts.poppins(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle splashSubtitle = GoogleFonts.poppins(
    fontSize: 16,
    color: Colors.white,
    fontWeight: FontWeight.w400,
  );

  static TextStyle splashLocation = GoogleFonts.poppins(
    fontSize: 18,
    color: Colors.white,
    fontWeight: FontWeight.w600,
  );

  // Styles pour l'onboarding
  static TextStyle onboardingTitle = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
    height: 1.2,
  );

  static TextStyle onboardingSubtitle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: const Color(0xFFFFD700),
  );

  static TextStyle onboardingDescription = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: const Color(0xFFB0B0B0),
    height: 1.5,
  );

  // Styles pour le login
  static TextStyle loginTitle = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle loginSubtitle = GoogleFonts.poppins(
    fontSize: 14,
    color: const Color(0xFFB0B0B0),
  );

  static TextStyle loginHint = GoogleFonts.poppins(
    fontSize: 14,
    color: const Color(0xFFB0B0B0),
  );

  static TextStyle loginButton = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle loginRegister = GoogleFonts.poppins(
    fontSize: 14,
    color: Colors.white,
    decoration: TextDecoration.underline,
  );

  static TextStyle loginFooter = GoogleFonts.poppins(
    fontSize: 12,
    color: const Color(0xFFB0B0B0),
    fontStyle: FontStyle.italic,
  );

  // Styles pour les services
  static TextStyle servicesTitle = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF2D2D2D),
  );

  static TextStyle servicesSubtitle = GoogleFonts.poppins(
    fontSize: 16,
    color: const Color(0xFF666666),
  );

  static TextStyle serviceCardTitle = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF2D2D2D),
  );

  static TextStyle serviceCardDescription = GoogleFonts.poppins(
    fontSize: 14,
    color: const Color(0xFF2D2D2D),
    height: 1.4,
  );

  static TextStyle serviceCardAction = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static TextStyle serviceCardStatus = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF2D2D2D),
  );

  // Styles généraux
  static TextStyle logoText = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  static TextStyle buttonText = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle inputText = GoogleFonts.poppins(
    fontSize: 16,
    color: const Color(0xFF2D2D2D),
  );

  static TextStyle inputHint = GoogleFonts.poppins(
    fontSize: 14,
    color: const Color(0xFF666666),
  );

  static TextStyle helperText = GoogleFonts.poppins(
    fontSize: 11,
    color: const Color(0xFFB0B0B0),
  );

  // Nouveaux styles pour les plats et catégories
  static TextStyle sectionTitle = GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF2D2D2D),
  );

  static TextStyle foodItemTitle = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF2D2D2D),
  );

  static TextStyle foodItemPrice = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.bold,
    color: Colors.red,
  );

  static TextStyle foodItemDescription = GoogleFonts.poppins(
    fontSize: 12,
    color: const Color(0xFF666666),
    fontWeight: FontWeight.w400,
  );

  static TextStyle categorySelected = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle categoryUnselected = GoogleFonts.poppins(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF666666),
  );

  static TextStyle welcomeMessage = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: const Color(0xFF2D2D2D),
  );

  static TextStyle heroTitle = GoogleFonts.poppins(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static TextStyle heroSubtitle = GoogleFonts.poppins(
    fontSize: 14,
    color: Colors.white70,
    fontWeight: FontWeight.w400,
  );

  // Styles pour les cartes
  static TextStyle cardTitle = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: const Color(0xFF2D2D2D),
  );

  static TextStyle cardSubtitle = GoogleFonts.poppins(
    fontSize: 14,
    color: const Color(0xFF666666),
    fontWeight: FontWeight.w400,
  );

  // Styles pour les boutons
  static TextStyle buttonPrimary = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );

  static TextStyle buttonSecondary = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: const Color(0xFF2D2D2D),
  );
}