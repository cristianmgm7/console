import 'package:carbon_voice_console/core/di/injection.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_event.dart';
import 'package:carbon_voice_console/features/messages/presentation/components/message_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessageDetailScreen extends StatelessWidget {
  const MessageDetailScreen({required this.messageId, super.key});
  final String messageId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MessageBloc>()..add(LoadMessageDetail(messageId)),
      child: Scaffold(
        appBar: AppBar(title: const Text('Message Details')),
        body: const MessageDetailView(),
      ),
    );
  }
}
