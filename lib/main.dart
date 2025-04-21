import 'dart:async'; // Para usar Timer

import 'package:flutter/material.dart';
import 'package:flutter_ai_chat/l10n/l10n.dart';
import 'package:flutter_ai_chat/providers/chat_provider.dart';
import 'package:flutter_ai_chat/providers/theme_provider.dart';
import 'package:flutter_ai_chat/utils/color_utils.dart';
import 'package:flutter_ai_chat/widgets/color_selector.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
            title: 'AI Chat',
            // Título estático para evitar error en el build inicial
            theme: themeProvider.theme,
            home: const ChatScreen(),
            // Configuración para internacionalización
            localizationsDelegates: [
              AppLocalizations.delegate, // Delegado generado automáticamente
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // Inglés
              Locale('es'), // Español
            ],
            // Usar el idioma del sistema, una vez cargadas las traducciones, actualizar el título dinámicamente
            onGenerateTitle: (context) => context.l10n.appTitle,
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

  // Controlador de desplazamiento para el ListView
  final ScrollController _scrollController = ScrollController();

  // Variable para controlar si se muestra el botón de navegación
  bool _showNavigationButton = false;

  // Lista de claves para acceder a los mensajes directamente
  final List<GlobalKey> _messageKeys = [];

  // Índice actual de navegación entre mensajes
  int _currentMessageIndex = -1;

  // Para animar el mensaje seleccionado
  int _highlightedMessageIndex = -1;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    // Monitorear el scroll para mostrar/ocultar el botón flotante
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _textController.dispose();
    _highlightTimer?.cancel();
    super.dispose();
  }

  // Escuchar el scroll para mostrar/ocultar el botón
  void _scrollListener() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;
      setState(() {
        // Mostrar botón si no estamos en la parte inferior
        _showNavigationButton = currentScroll < maxScroll - 50;
      });
    }
  }

  // Funcion mejorado para ir al final de la conversación
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      // Actualizar el índice de navegación al último mensaje
      if (_messageKeys.isNotEmpty) {
        setState(() {
          _currentMessageIndex = _messageKeys.length - 1;
          // También resaltamos el último mensaje para indicar la posición actual
          _highlightMessage(_currentMessageIndex);
        });
      }

      // Desplazarse al final
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);
    final theme = Theme.of(context);
    final l10n = context.l10n;

    // Actualizar la lista de claves si cambia el número de mensajes
    if (_messageKeys.length != chatProvider.messages.length) {
      // Guardar el índice actual antes de actualizar las claves
      final wasAtEnd =
          _currentMessageIndex == _messageKeys.length - 1 ||
          _currentMessageIndex == -1;

      // Actualizar las claves
      _messageKeys.clear();
      for (int i = 0; i < chatProvider.messages.length; i++) {
        _messageKeys.add(GlobalKey());
      }

      // Mantener el índice al final si estaba al final o es el primer mensaje
      if (wasAtEnd && chatProvider.messages.isNotEmpty) {
        _currentMessageIndex = chatProvider.messages.length - 1;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.chatScreenTitle,
          style: TextStyle(color: Colors.white),
        ),
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
      // Botones flotantes para navegación - solo se muestran si hay mensajes
      floatingActionButton:
          chatProvider.messages.isNotEmpty
              ? Padding(
                padding: const EdgeInsets.only(bottom: 80, right: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Botones de navegación entre mensajes (solo visibles si no estamos al final)
                    if (_showNavigationButton) ...[
                      // Botón para navegar hacia arriba (mensaje anterior)
                      FloatingActionButton(
                        heroTag: "previousButton",
                        mini: true,
                        backgroundColor: ColorUtils.adjustOpacity(
                          theme.colorScheme.primary,
                          0.85,
                        ),
                        elevation: 4,
                        onPressed: () => _navigateToPreviousMessage(),
                        child: const Icon(
                          Icons.arrow_upward,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Botón para navegar hacia abajo (mensaje siguiente)
                      FloatingActionButton(
                        heroTag: "nextButton",
                        mini: true,
                        backgroundColor: ColorUtils.adjustOpacity(
                          theme.colorScheme.primary,
                          0.85,
                        ),
                        elevation: 4,
                        onPressed: () => _navigateToNextMessage(),
                        child: const Icon(
                          Icons.arrow_downward,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Botón para ir al final (visible cuando hay mensajes y no estamos al final)
                    if (_showNavigationButton)
                      FloatingActionButton(
                        heroTag: "bottomButton",
                        backgroundColor: ColorUtils.adjustOpacity(
                          theme.colorScheme.primary,
                          0.9,
                        ),
                        elevation: 4,
                        onPressed: _scrollToBottom,
                        child: const Icon(
                          Icons.keyboard_double_arrow_down,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                  ],
                ),
              )
              : null,
      // No usar la ubicación estándar para tener más control con el padding
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
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
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 16.0,
                ),
                itemCount:
                    chatProvider.messages.length +
                    (chatProvider.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  // Si es el último elemento y estamos cargando, mostrar indicador
                  if (chatProvider.isLoading &&
                      index == chatProvider.messages.length) {
                    return _buildLoadingIndicator(theme);
                  }

                  final message = chatProvider.messages[index];
                  final isUser = message.role == 'user';

                  // Usar clave global para este mensaje
                  return Padding(
                    key:
                        index < _messageKeys.length
                            ? _messageKeys[index]
                            : null,
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color:
                            _highlightedMessageIndex == index
                                ? ColorUtils.adjustOpacity(
                                  theme.colorScheme.primary,
                                  0.2,
                                )
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            _highlightedMessageIndex == index
                                ? Border.all(
                                  color: ColorUtils.adjustOpacity(
                                    theme.colorScheme.primary,
                                    0.5,
                                  ),
                                  width: 2,
                                )
                                : null,
                      ),
                      padding: const EdgeInsets.all(4),
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
                                    isUser ? l10n.userLabel : l10n.botLabel,
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
                                          isUser
                                              ? Colors.white
                                              : Colors.black87,
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
                      color: ColorUtils.adjustOpacity(Colors.black, 0.05),
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
                          hintText: l10n.messageHint,
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

  // Función para navegar al siguiente mensaje (pregunta o respuesta)
  void _navigateToNextMessage() {
    if (_messageKeys.isEmpty) return;

    // Determinar el índice siguiente
    int nextIndex;

    // Si no tenemos índice actual o estamos al final, ir al principio
    if (_currentMessageIndex == -1 ||
        _currentMessageIndex >= _messageKeys.length - 1) {
      nextIndex = 0;
    } else {
      // Avanzar al siguiente mensaje
      nextIndex = _currentMessageIndex + 1;
    }

    // Actualizar el índice actual y resaltar el mensaje
    setState(() {
      _currentMessageIndex = nextIndex;
      _highlightMessage(_currentMessageIndex);
    });

    // Función directo y forzado para desplazarse al mensaje
    _forceScrollToCurrentMessage();
  }

  // Función para navegar al mensaje anterior (pregunta o respuesta)
  void _navigateToPreviousMessage() {
    if (_messageKeys.isEmpty) return;

    // Determinar el índice anterior
    int prevIndex;

    // Si no tenemos índice actual o estamos al inicio, ir al final
    if (_currentMessageIndex <= 0 || _currentMessageIndex == -1) {
      prevIndex = _messageKeys.length - 1;
    } else {
      // Retroceder al mensaje anterior
      prevIndex = _currentMessageIndex - 1;
    }

    // Actualizar el índice actual y resaltar el mensaje
    setState(() {
      _currentMessageIndex = prevIndex;
      _highlightMessage(_currentMessageIndex);
    });

    // Función directo y forzado para desplazarse al mensaje
    _forceScrollToCurrentMessage();
  }

  // Función para forzar el desplazamiento al mensaje actual
  void _forceScrollToCurrentMessage() {
    if (_messageKeys.isEmpty ||
        _currentMessageIndex < 0 ||
        _currentMessageIndex >= _messageKeys.length) {
      return;
    }

    // Usar un esquema de reintento con escalamiento de tiempo
    void attemptToScroll([int attempt = 0]) {
      if (attempt >= 5 || !mounted) return; // Máximo 5 intentos

      final key = _messageKeys[_currentMessageIndex];
      final context = key.currentContext;

      if (context != null) {
        // Intento exitoso, desplazarse al mensaje
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.2, // Posicionarlo cerca de la parte superior
        );
      } else {
        // Falló, reintentar con retraso incremental
        int delay = 50 * (attempt + 1); // 50ms, 100ms, 150ms, 200ms, 250ms

        Future.delayed(Duration(milliseconds: delay), () {
          attemptToScroll(attempt + 1);
        });

        // Mientras intentamos obtener el contexto, hacer scroll aproximado basado en índice
        if (attempt == 1 && _scrollController.hasClients) {
          try {
            // Calcular posición aproximada basada en el índice y tamaño estimado
            final viewportHeight = _scrollController.position.viewportDimension;
            final itemEstimatedHeight =
                viewportHeight / 4; // Estimación de altura aproximada
            final approximatePosition =
                _currentMessageIndex * itemEstimatedHeight;

            // Limitar a los límites válidos del scroll
            final safePosition = approximatePosition.clamp(
              0.0,
              _scrollController.position.maxScrollExtent,
            );

            // Desplazarse a esa posición aproximada
            _scrollController.animateTo(
              safePosition,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          } catch (e) {
            debugPrint('Error en scroll aproximado: $e');
          }
        }
      }
    }

    // Iniciar la secuencia de intentos
    attemptToScroll();
  }

  // Función para resaltar temporalmente un mensaje
  void _highlightMessage(int index) {
    // Cancelar cualquier timer existente
    _highlightTimer?.cancel();

    // Establecer el índice a resaltar
    setState(() {
      _highlightedMessageIndex = index;
    });

    // Programar la eliminación del resaltado después de 2 segundos (tiempo aumentado)
    _highlightTimer = Timer(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _highlightedMessageIndex = -1;
        });
      }
    });
  }

  void sendMessage(ChatProvider chatProvider) {
    final message = _textController.text.trim();

    // Guard: mensaje vacío
    if (message.isEmpty) return;

    _textController.clear();
    chatProvider.sendMessage(message);

    // Después de enviar un mensaje, el índice debe actualizarse
    // después de un breve retraso para que el nuevo mensaje esté en la lista
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_messageKeys.isNotEmpty) {
        setState(() {
          _currentMessageIndex = _messageKeys.length - 1;
        });
      }
      // Desplazarse al final de la conversación
      _scrollToBottom();
    });
  }

  // Widget para mostrar el indicador de carga
  Widget _buildLoadingIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            radius: 16,
            child: const Icon(Icons.smart_toy, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
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
                    context.l10n.botLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: theme.colorScheme.primary,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Texto "Pensando" traducido
                      Text(
                        context.l10n.thinkingLabel,
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                      // Puntos suspensivos animados
                      const TypingIndicator(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentIndex = 0;
  final List<String> _dots = ["", ".", "..", "..."];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..addListener(() {
      if (_controller.status == AnimationStatus.completed) {
        _controller.reset();
        setState(() {
          _currentIndex = (_currentIndex + 1) % _dots.length;
        });
        _controller.forward();
      }
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      child: Text(
        _dots[_currentIndex],
        style: const TextStyle(
          color: Colors.black54,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
