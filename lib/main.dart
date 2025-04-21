import 'package:flutter/material.dart';
import 'package:flutter_ai_chat/providers/chat_provider.dart';
import 'package:flutter_ai_chat/providers/theme_provider.dart';
import 'package:flutter_ai_chat/utils/color_utils.dart';
import 'package:flutter_ai_chat/widgets/color_selector.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

void main() async {
  await dotenv.load(fileName: ".env"); // Carga las variables de entorno
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ChatProvider()),
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Chat con IA',
            theme: themeProvider.theme,
            home: const ChatScreen(),
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  bool _showColorSelector = false;

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat con Gemini'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showColorSelector ? Icons.color_lens_outlined : Icons.color_lens,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showColorSelector = !_showColorSelector;
              });
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, theme.colorScheme.surface],
            stops: const [0.2, 1.0],
          ),
        ),
        child: Column(
          children: [
            if (_showColorSelector) const ColorSelector(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 16.0,
                ),
                itemCount: chatProvider.messages.length,
                itemBuilder: (context, index) {
                  final message = chatProvider.messages[index];
                  final isUser = message.role == 'user';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment:
                          isUser
                              ? MainAxisAlignment.end
                              : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!isUser)
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.primary,
                            radius: 16,
                            child: const Icon(
                              Icons.smart_toy,
                              color: Colors.white,
                            ),
                          ),
                        if (!isUser) const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 10.0,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isUser
                                      ? theme.colorScheme.primary
                                      : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 3,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isUser ? 'Tú' : 'Gemini',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isUser
                                            ? Colors.white
                                            : theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  message.content,
                                  style: TextStyle(
                                    color:
                                        isUser ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (isUser) const SizedBox(width: 8),
                        if (isUser)
                          CircleAvatar(
                            backgroundColor: theme.colorScheme.tertiary,
                            radius: 16,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Container(
              height: 1.0,
              decoration: BoxDecoration(
                color: ColorUtils.adjustOpacity(theme.colorScheme.primary, 0.3),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 2,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: 'Escribe tu mensaje...',
                          hintStyle: TextStyle(
                            color: const Color(0xFF707070),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (value) {
                          sendMessage(chatProvider);
                        },
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white),
                        onPressed: () {
                          sendMessage(chatProvider);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(height: 16.0, color: theme.colorScheme.surface),
          ],
        ),
      ),
    );
  }

  void sendMessage(ChatProvider chatProvider) {
    final message = _textController.text.trim();

    // Guard: mensaje vacío
    if (message.isEmpty) return;

    _textController.clear();
    chatProvider.sendMessage(message);
  }
}
