import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_state.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/components/pagination_controls.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PaginationControlsWrapper extends StatelessWidget {
  const PaginationControlsWrapper({
    required this.onLoadMore,
    required this.hasMore,
    required this.isLoading,
    super.key,
  });

  final VoidCallback onLoadMore;
  final bool hasMore;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 24,
      child: BlocSelector<MessageBloc, MessageState, MessageLoaded?>(
        selector: (state) => state is MessageLoaded ? state : null,
        builder: (context, messageState) {
          if (messageState == null) return const SizedBox.shrink();

          return PaginationControls(
            onLoadMore: onLoadMore,
            hasMore: hasMore,
            isLoading: isLoading,
          );
        },
      ),
    );
  }
}
