import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatMessage {
  final String role;
  final String content;

  ChatMessage({required this.role, required this.content});
}

class ChatProvider with ChangeNotifier {
  List<ChatMessage> messages = [];

  // Estado para controlar si está esperando una respuesta
  bool _isLoading = false;

  // Getter para el estado de carga
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String message) async {
    // Guard: mensaje vacío
    if (message.trim().isEmpty) {
      return;
    }

    // Añadir mensaje del usuario
    messages.add(ChatMessage(role: 'user', content: message));

    // Activar el estado de carga
    _isLoading = true;
    notifyListeners();

    // Guard: verificar si la API key existe
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      messages.add(
        ChatMessage(
          role: 'model',
          content: 'Error: No se encontró la clave API en .env',
        ),
      );
      // Desactivar el estado de carga
      _isLoading = false;
      notifyListeners();
      return;
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );

    final headers = {'Content-Type': 'application/json'};

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': message},
          ],
        },
      ],
    });

    try {
      final response = await http.post(url, headers: headers, body: body);

      // Guard: comprobar si la respuesta fue exitosa
      if (response.statusCode != 200) {
        messages.add(
          ChatMessage(
            role: 'model',
            content: 'Error: ${response.statusCode} - ${response.body}',
          ),
        );
        // Desactivar el estado de carga
        _isLoading = false;
        notifyListeners();
        return;
      }

      final data = jsonDecode(response.body);

      // Guard: verificar si candidates existe en la respuesta
      if (data['candidates'] == null || data['candidates'].isEmpty) {
        messages.add(
          ChatMessage(
            role: 'model',
            content: 'Error: No se recibió respuesta válida del modelo',
          ),
        );
        // Desactivar el estado de carga
        _isLoading = false;
        notifyListeners();
        return;
      }

      final content = data['candidates'][0]['content']['parts'][0]['text'];
      messages.add(ChatMessage(role: 'model', content: content));
    } catch (e) {
      messages.add(ChatMessage(role: 'model', content: 'Error: $e'));
    } finally {
      // Desactivar el estado de carga siempre en el finally
      _isLoading = false;
      notifyListeners();
    }
  }
}
