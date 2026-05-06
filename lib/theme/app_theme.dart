import 'package:flutter/material.dart';

class AppColors {
  static const navyDeep     = Color(0xFF0D1B2A);
  static const navySurface  = Color(0xFF152535);
  static const navyElevated = Color(0xFF1E3448);
  static const amber        = Color(0xFFF4A261);
  static const amberMuted   = Color(0xFF2a2010);
  static const white        = Color(0xFFF0F4F8);
  static const muted        = Color(0xFF7A94A8);
  static const inactive     = Color(0xFF4a6070);

  // Status colors
  static const pending      = Color(0xFFF4C261);
  static const verified     = Color(0xFF61B4F4);
  static const inProgress   = Color(0xFF9B8CF4);
  static const resolved     = Color(0xFF61F4A2);

  // Issue type colors
  static const pothole      = Color(0xFFF4A261);
  static const flooding     = Color(0xFF61B4F4);
  static const obstruction  = Color(0xFFF46161);
  static const roadDamage   = Color(0xFFF4844A);
  static const accident     = Color(0xFFD94F4F);
  static const signage      = Color(0xFF9B8CF4);

  static Color forType(String type) {
    switch (type) {
      case 'Pothole':         return pothole;
      case 'Flooding':        return flooding;
      case 'Obstruction':     return obstruction;
      case 'Road Damage':     return roadDamage;
      case 'Accident':        return accident;
      case 'Missing Signage': return signage;
      default:                return amber;
    }
  }

  static Color forStatus(String status) {
    switch (status) {
      case 'pending':     return pending;
      case 'verified':    return verified;
      case 'in_progress': return inProgress;
      case 'resolved':    return resolved;
      default:            return muted;
    }
  }
}
