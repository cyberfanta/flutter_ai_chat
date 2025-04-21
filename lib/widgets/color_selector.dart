import 'package:flutter/material.dart';
import 'package:flutter_ai_chat/l10n/l10n.dart';
import 'package:flutter_ai_chat/providers/theme_provider.dart';
import 'package:flutter_ai_chat/utils/color_utils.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

class ColorSelector extends StatelessWidget {
  const ColorSelector({super.key});

  @override
  Widget build(BuildContext context) {
    // Guard: verifica el contexto
    if (!context.mounted) return const SizedBox();

    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final l10n = context.l10n;

    // Guard: verifica si hay opciones de colores
    if (themeProvider.colorOptions.isEmpty) {
      return const SizedBox(
        height: 50,
        child: Center(child: Text("No hay opciones de colores disponibles")),
      );
    }

    return SizedBox(
      height: 128,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              l10n.customizeTheme,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ListView(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                scrollDirection: Axis.horizontal,
                children: [
                  // Opciones de colores predefinidos
                  ...List.generate(themeProvider.colorOptions.length, (index) {
                    final colorOption = themeProvider.colorOptions[index];
                    final isSelected =
                        themeProvider.selectedColorIndex == index;

                    String colorName;
                    // Traducir los nombres de los colores
                    switch (colorOption.name) {
                      case 'Dorado':
                      case 'Gold':
                        colorName = l10n.goldTheme;
                        break;
                      case 'Verde Lima':
                      case 'Lime Green':
                        colorName = l10n.limeTheme;
                        break;
                      case 'Azul Cielo':
                      case 'Sky Blue':
                        colorName = l10n.skyBlueTheme;
                        break;
                      case 'Rosa Pastel':
                      case 'Pastel Pink':
                        colorName = l10n.pinkTheme;
                        break;
                      default:
                        colorName = colorOption.name;
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          themeProvider.setColorByIndex(index);
                        },
                        child: buildItem(
                          themeProvider,
                          colorName,
                          colorOption.color,
                          theme.colorScheme.primary,
                          isSelected,
                        ),
                      ),
                    );
                  }),

                  // Opción de color personalizado
                  if (themeProvider.selectedColorIndex == -1)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: buildItem(
                        themeProvider,
                        l10n.customTheme,
                        themeProvider.selectedColor,
                        themeProvider.selectedColor,
                        true,
                      ),
                    ),

                  const SizedBox(width: 12),

                  // Botón para seleccionar un color personalizado
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    child: const ColorPickerButton(),
                  ),
                ],
              ),
            ),
          ),
          Container(
            height: 1,
            color: ColorUtils.adjustOpacity(theme.colorScheme.primary, 0.3),
          ),
        ],
      ),
    );
  }

  Column buildItem(
    ThemeProvider themeProvider,
    String text,
    Color color,
    Color textColor,
    bool isSelected,
  ) {
    return Column(
      children: [
        const SizedBox(height: 12),
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Colors.white : Colors.transparent,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color:
                    isSelected
                        ? ColorUtils.adjustOpacity(color, 0.7)
                        : Colors.black12,
                blurRadius: isSelected ? 8 : 2,
                spreadRadius: isSelected ? 2 : 0,
              ),
            ],
          ),
          child:
              isSelected
                  ? const Center(
                    child: Icon(Icons.check, color: Colors.white, size: 20),
                  )
                  : const SizedBox(),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? textColor : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class ColorPickerButton extends StatelessWidget {
  const ColorPickerButton({super.key});

  @override
  Widget build(BuildContext context) {
    // Guard: verifica el contexto
    if (!context.mounted) return const SizedBox();

    final themeProvider = Provider.of<ThemeProvider>(context);

    return FloatingActionButton(
      elevation: 0,
      onPressed: () {
        _showColorPickerDialog(context, themeProvider);
      },
      mini: true,
      child: const Icon(Icons.color_lens),
    );
  }

  void _showColorPickerDialog(
    BuildContext context,
    ThemeProvider themeProvider,
  ) {
    // Guard: verifica el contexto
    if (!context.mounted) return;

    Color pickerColor = themeProvider.selectedColor;
    final l10n = context.l10n;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(l10n.chooseCustomColor),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) {
                pickerColor = color;
              },
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false,
              displayThumbColor: true,
              labelTypes: const [],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(l10n.cancel, style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(l10n.apply, style: TextStyle(color: Colors.black)),
              onPressed: () {
                // Esto establecerá selectedColorIndex = -1 automáticamente
                themeProvider.setCustomColor(pickerColor);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
