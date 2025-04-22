/// Utilidad para manejar el texto Markdown
class MarkdownUtils {
  /// Elimina los caracteres de formato Markdown del texto
  /// para obtener solo el texto plano, pero preservando la estructura
  /// visual básica de elementos como listas
  static String stripMarkdown(String markdownText) {
    // Primero vamos a dividir el texto en líneas para procesarlo mejor
    List<String> lines = markdownText.split('\n');
    List<String> resultLines = [];
    
    // Procesamos cada línea individualmente para preservar su estructura
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      
      // Procesar encabezados (# Título)
      if (RegExp(r'^\s*#+\s+').hasMatch(line)) {
        // Extraer el texto del encabezado sin los #
        String headingText = line.replaceFirst(RegExp(r'^\s*#+\s+'), '');
        
        // Añadir una línea en blanco antes del encabezado si no es la primera línea
        // y si la línea anterior no está vacía
        if (i > 0 && resultLines.isNotEmpty && resultLines.last.trim().isNotEmpty) {
          resultLines.add('');
        }
        
        // Añadir el texto del encabezado
        resultLines.add(headingText);
        
        // Añadir una línea en blanco después del encabezado
        resultLines.add('');
        continue;
      }
      
      // Procesar listas con viñetas (-, *, +)
      Match? bulletMatch = RegExp(r'^(\s*)([-*+])\s+(.*)$').firstMatch(line);
      if (bulletMatch != null) {
        final indentation = bulletMatch.group(1) ?? '';
        final bullet = bulletMatch.group(2) ?? '-';
        final content = bulletMatch.group(3) ?? '';
        
        // Calcular el nivel de anidación
        final indentLevel = (indentation.length / 2).floor();
        final consistentIndent = '  ' * indentLevel;
        
        // Conservar el bullet point con su indentación
        resultLines.add('$consistentIndent$bullet $content');
        continue;
      }
      
      // Procesar listas numeradas (1., 2., etc.)
      Match? numberedMatch = RegExp(r'^(\s*)(\d+)\.\s+(.*)$').firstMatch(line);
      if (numberedMatch != null) {
        final indentation = numberedMatch.group(1) ?? '';
        final number = numberedMatch.group(2) ?? '1';
        final content = numberedMatch.group(3) ?? '';
        
        // Calcular el nivel de anidación
        final indentLevel = (indentation.length / 2).floor();
        final consistentIndent = '  ' * indentLevel;
        
        // Conservar el número y punto con su indentación
        resultLines.add('$consistentIndent$number. $content');
        continue;
      }
      
      // Procesar citas (>)
      Match? quoteMatch = RegExp(r'^(\s*)>\s+(.*)$').firstMatch(line);
      if (quoteMatch != null) {
        final indentation = quoteMatch.group(1) ?? '';
        final content = quoteMatch.group(2) ?? '';
        
        // Calcular el nivel de anidación
        final indentLevel = (indentation.length / 2).floor();
        final consistentIndent = '  ' * indentLevel;
        
        // Añadir un formato visual para las citas
        resultLines.add('$consistentIndent| $content');
        continue;
      }
      
      // Ignorar líneas horizontales (---, ***, ___)
      if (RegExp(r'^\s*[-*_]{3,}\s*$').hasMatch(line)) {
        // Si no es la primera ni la última línea, mantener una línea vacía
        if (i > 0 && i < lines.length - 1) {
          resultLines.add('');
        }
        continue;
      }
      
      // Para cualquier otra línea, procesar el formato Markdown inline
      String processedLine = line;
      
      // Eliminar negrita y cursiva
      processedLine = processedLine.replaceAllMapped(
        RegExp(r'\*\*(.*?)\*\*'), 
        (match) => match.group(1) ?? '',
      );
      processedLine = processedLine.replaceAllMapped(
        RegExp(r'__(.*?)__'),
        (match) => match.group(1) ?? '',
      );
      processedLine = processedLine.replaceAllMapped(
        RegExp(r'\*(.*?)\*'),
        (match) => match.group(1) ?? '',
      );
      processedLine = processedLine.replaceAllMapped(
        RegExp(r'_(.*?)_'),
        (match) => match.group(1) ?? '',
      );
      
      // Eliminar enlaces [texto](url)
      processedLine = processedLine.replaceAllMapped(
        RegExp(r'\[(.*?)\]\(.*?\)'),
        (match) => match.group(1) ?? '',
      );
      
      // Eliminar código en línea `código`
      processedLine = processedLine.replaceAllMapped(
        RegExp(r'`(.*?)`'),
        (match) => match.group(1) ?? '',
      );
      
      // Añadir la línea procesada
      resultLines.add(processedLine);
    }
    
    // Unir todas las líneas procesadas con saltos de línea
    String result = resultLines.join('\n');
    
    // Eliminar múltiples líneas en blanco consecutivas
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    return result.trim();
  }
}
