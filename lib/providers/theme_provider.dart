import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Colores predefinidos
  static const Color dorado = Color(0xFFD4AF37);
  static const Color verdeLimaPastel = Color(0xFFBEEF9E);
  static const Color azulCielo = Color(0xFF89CFF0);
  static const Color rosaPastel = Color(0xFFFFB6C1);

  // Opciones de colores con nombres
  // Los nombres se mostrarán traducidos por ColorSelector
  final List<ColorOption> colorOptions = [
    ColorOption('Gold', dorado),
    ColorOption('Lime Green', verdeLimaPastel),
    ColorOption('Sky Blue', azulCielo),
    ColorOption('Pastel Pink', rosaPastel),
  ];

  // Color actual seleccionado (predeterminado: verde lima)
  late Color _selectedColor;
  int _selectedColorIndex = 1; // Por defecto Verde Lima Pastel (índice 1)

  // Obtener el tema actual
  ThemeData get theme => _createTheme(_selectedColor);

  // Obtener el color seleccionado
  Color get selectedColor => _selectedColor;

  // Obtener el índice del color seleccionado
  int get selectedColorIndex => _selectedColorIndex;

  // Constructor
  ThemeProvider() {
    _selectedColor = verdeLimaPastel; // Default: Verde Lima Pastel
    _loadSavedColor();
  }

  // Cargar color guardado
  Future<void> _loadSavedColor() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final colorIndex =
          prefs.getInt('selectedColorIndex') ?? 1; // Default: Verde Lima Pastel

      if (colorIndex == -1) {
        // Color personalizado guardado
        final int? colorValue = prefs.getInt('customColorValue');
        // Guard: Si no hay valor de color personalizado, mantener el predeterminado
        if (colorValue == null) {
          _selectedColorIndex = 1;
          _selectedColor = verdeLimaPastel;
          return;
        }

        _selectedColorIndex = -1;
        _selectedColor = Color(colorValue);
        return;
      }

      // Guard: Si el índice está fuera de rango, usar el predeterminado
      if (colorIndex < 0 || colorIndex >= colorOptions.length) {
        _selectedColorIndex = 1;
        _selectedColor = verdeLimaPastel;
        return;
      }

      _selectedColorIndex = colorIndex;
      _selectedColor = colorOptions[colorIndex].color;
    } catch (e) {
      // En caso de error, usar el color predeterminado
      _selectedColorIndex = 1;
      _selectedColor = verdeLimaPastel;
    } finally {
      notifyListeners();
    }
  }

  // Guardar color seleccionado
  Future<void> _saveColor(int index, [Color? customColor]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('selectedColorIndex', index);

      // Si es un color personalizado, guardar su valor
      if (index == -1 && customColor != null) {
        await prefs.setInt('customColorValue', customColor.toARGB32());
      }
    } catch (e) {
      // Ignorar errores al guardar, pero podríamos registrarlos
      debugPrint('Error al guardar preferencias de color: $e');
    }
  }

  // Cambiar el color del tema
  void setColorByIndex(int index) {
    // Guard: índice fuera de rango
    if (index < 0 || index >= colorOptions.length) return;

    _selectedColorIndex = index;
    _selectedColor = colorOptions[index].color;
    _saveColor(index);
    notifyListeners();
  }

  // Actualizar a un color personalizado
  void setCustomColor(Color color) {
    // Guard: color inválido o transparente
    if (color.toARGB32() == 0 || color.a == 0) return;

    _selectedColorIndex = -1; // Indica que es un color personalizado
    _selectedColor = color;
    _saveColor(-1, color); // Guardar el color personalizado
    notifyListeners();
  }

  // Crear tema basado en el color seleccionado
  ThemeData _createTheme(Color baseColor) {
    // Valores específicos para cada tema
    Color surfaceColor;

    if (baseColor == dorado) {
      // El tema dorado tiene un color superficie específico
      surfaceColor = const Color(0xFFFFF8E1);
    } else if (baseColor == verdeLimaPastel) {
      // Para el verde, usamos un verde muy claro como superficie
      surfaceColor = const Color(0xFFF1FFE8);
    } else if (baseColor == azulCielo) {
      // Para el azul, usamos un azul muy claro como superficie
      surfaceColor = const Color(0xFFE6F5FF);
    } else if (baseColor == rosaPastel) {
      // Para el rosa, usamos un rosa muy claro como superficie
      surfaceColor = const Color(0xFFFFF0F5);
    } else {
      // Para colores personalizados, generamos una versión muy clara
      final hsl = HSLColor.fromColor(baseColor);
      surfaceColor = hsl.withLightness(0.95).withSaturation(0.85).toColor();
    }

    return ThemeData(
      primaryColor: baseColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: baseColor,
        primary: baseColor,
        secondary: _getLighterColor(baseColor),
        tertiary: _getDarkerColor(baseColor),
        surface: surfaceColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: baseColor,
        foregroundColor: _getContrastColor(baseColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: baseColor,
          foregroundColor: _getContrastColor(baseColor),
        ),
      ),
      iconTheme: IconThemeData(color: baseColor),
    );
  }

  // Funciones auxiliares para generar colores derivados
  Color _getLighterColor(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    return hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();
  }

  Color _getDarkerColor(Color baseColor) {
    final hsl = HSLColor.fromColor(baseColor);
    return hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
  }

  Color _getContrastColor(Color color) {
    return ThemeData.estimateBrightnessForColor(color) == Brightness.dark
        ? Colors.white
        : Colors.black87;
  }
}

// Clase para representar una opción de color
class ColorOption {
  final String name;
  final Color color;

  ColorOption(this.name, this.color);
}
