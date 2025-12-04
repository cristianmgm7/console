import 'package:carbon_voice_console/core/di/injection.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_detail/bloc/message_detail_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_table/components/message_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessageDetailScreen extends StatelessWidget {
  const MessageDetailScreen({required this.messageId, super.key});
  final String messageId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<MessageDetailBloc>()..add(LoadMessageDetail(messageId)),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Message Details',
            style: AppTextStyle.titleLarge.copyWith(color: AppColors.textPrimary),
          ),
        ),
        body: const MessageDetailView(),
      ),
    );
  }
}
