import 'package:flutter/material.dart';
import '../services/locale_service.dart';

import '../config/brand.dart';

class TypeStyle {
  final String label;
  final Color color;

  const TypeStyle(this.label, this.color);
}

TypeStyle typeStyle(String? type) {
  switch (type) {
    case 'lecture':
      return TypeStyle(l10n.lecture, unioBlue);
    case 'practice':
      return TypeStyle(l10n.practice, unioSuccess);
    case 'lab':
      return TypeStyle(l10n.lab, const Color(0xFF8E4EC6));
    case 'seminar':
      return TypeStyle(l10n.seminar, const Color(0xFF00A3A3));
    case 'consultation':
      return TypeStyle(l10n.consultation, const Color(0xFF7A8699));
    case 'exam':
      return TypeStyle(l10n.exam, unioError);
    case 'credit':
      return TypeStyle(l10n.credit, unioWarning);
    default:
      return TypeStyle(l10n.uiClass, const Color(0xFF7A8699));
  }
}
