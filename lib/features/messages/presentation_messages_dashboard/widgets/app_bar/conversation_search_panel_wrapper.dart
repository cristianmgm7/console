import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/components/conversation_search_panel.dart';
import 'package:flutter/material.dart';

class ConversationSearchPanelWrapper extends StatelessWidget {
  const ConversationSearchPanelWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const Positioned(
      top: 8,
      left: 320,
      child: ConversationSearchPanel(),
    );
  }
}
