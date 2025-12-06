import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_icons.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_event.dart';
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConversationSearchButton extends StatelessWidget {
  const ConversationSearchButton({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ConversationBloc, ConversationState, ConversationLoaded?>(
      selector: (state) => state is ConversationLoaded ? state : null,
      builder: (context, conversationState) {
        if (conversationState == null || conversationState.conversations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 22),
          child: AppIconButton(
            icon: AppIcons.search,
            onPressed: () {
              context.read<ConversationBloc>().add(const OpenConversationSearch());
            },
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.primary,
            tooltip: 'Search conversations',
          ),
        );
      },
    );
  }
}
