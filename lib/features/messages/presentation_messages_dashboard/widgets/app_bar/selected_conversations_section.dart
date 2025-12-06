import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_event.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/widgets/conversation_selected_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SelectedConversationsSection extends StatelessWidget {
  const SelectedConversationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: BlocSelector<ConversationBloc, ConversationState, ConversationLoaded?>(
          selector: (state) => state is ConversationLoaded ? state : null,
          builder: (context, conversationState) {
            if (conversationState == null ||
                conversationState.selectedConversationIds.isEmpty) {
              return const SizedBox.shrink();
            }

            final selectedConversations = conversationState.conversations
                .where((c) => conversationState.selectedConversationIds.contains(c.id))
                .toList();

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: selectedConversations.map((conversation) {
                  return ConversationWidget(
                    conversation: conversation,
                    onRemove: () {
                      context.read<ConversationBloc>().add(
                        ToggleConversation(conversation.id),
                      );
                    },
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }
}
