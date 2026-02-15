// lib/screens/chat/widgets/chat_input.dart

import 'package:flutter/material.dart';

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool isEnviando;
  final VoidCallback onEnviar;

  const ChatInput({
    Key? key,
    required this.controller,
    required this.isEnviando,
    required this.onEnviar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SafeArea(
        child: Row(
          children: [
            // Campo de texto
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  enabled: !isEnviando,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    hintStyle: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onSubmitted: (_) => onEnviar(),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Botón enviar
            Material(
              color: isEnviando ? Colors.grey[300] : const Color(0xFFC5414B),
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: isEnviando ? null : onEnviar,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  child: isEnviando
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 24,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}