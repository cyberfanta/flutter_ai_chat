// Esta clase se exporta desde flutter_gen/gen_l10n/app_localizations.dart
// No necesitamos definirla aquí ya que Flutter la generará automáticamente
// basándose en los archivos ARB
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

export 'package:flutter_gen/gen_l10n/app_localizations.dart';

// Extensión para acceder fácilmente a las traducciones
extension AppLocalizationsX on BuildContext {
  // Proporciona acceso al objeto de localización generado automáticamente
  AppLocalizations get l10n => AppLocalizations.of(this);
}
