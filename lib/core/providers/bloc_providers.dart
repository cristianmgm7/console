import 'package:carbon_voice_console/core/di/injection.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_event.dart'
    as auth_events;
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/bloc/message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_selection_cubit.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/screens/dashboard_screen.dart';
import 'package:carbon_voice_console/features/preview/presentation/cubit/preview_composer_cubit.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_detail/bloc/message_detail_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_detail/cubit/message_detail_cubit.dart';
import 'package:carbon_voice_console/features/messages/presentation_send_message/bloc/send_message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation_send_message/cubit/message_composition_cubit.dart';
import 'package:carbon_voice_console/features/users/presentation/cubit/user_profile_cubit.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/bloc/voice_memo_bloc.dart';
import 'package:carbon_voice_console/features/voice_memos/presentation/voice_memos_screen.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_bloc.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_event.dart'
    as ws_events;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class BlocProviders {
  static Widget generalBlocs({required Widget child}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<UserProfileCubit>(
          create: (_) => getIt<UserProfileCubit>(),
        ),
        BlocProvider<AuthBloc>(
          create: (_) => getIt<AuthBloc>()..add(const auth_events.AppStarted()),
        ),
        BlocProvider<AudioPlayerBloc>(
          create: (_) => getIt<AudioPlayerBloc>(),
        ),
      ],
      child: child,
    );
  }

  static Widget blocProvidersDashboard() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WorkspaceBloc>(
          create: (_) => getIt<WorkspaceBloc>()..add(const ws_events.LoadWorkspaces()),
        ),
        BlocProvider<ConversationBloc>(
          create: (_) => getIt<ConversationBloc>(),
        ),
        BlocProvider<MessageBloc>(
          create: (_) => getIt<MessageBloc>(),
        ),
        BlocProvider<MessageDetailBloc>(
          create: (_) => getIt<MessageDetailBloc>(),
        ),
        BlocProvider<SendMessageBloc>(
          create: (_) => getIt<SendMessageBloc>(),
        ),
        BlocProvider<DownloadBloc>(
          create: (_) => getIt<DownloadBloc>(),
        ),
        // Cubits for UI state
        BlocProvider<MessageSelectionCubit>(
          create: (_) => getIt<MessageSelectionCubit>(),
        ),
        BlocProvider<MessageCompositionCubit>(
          create: (_) => getIt<MessageCompositionCubit>(),
        ),
        BlocProvider<MessageDetailCubit>(
          create: (_) => getIt<MessageDetailCubit>(),
        ),
        // NEW: Preview composer cubit
        BlocProvider<PreviewComposerCubit>(
          create: (_) => getIt<PreviewComposerCubit>(),
        ),
      ],
      child: const DashboardScreen(),
    );
  }

  static Widget blocProvidersVoiceMemos() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<VoiceMemoBloc>(
          create: (_) => getIt<VoiceMemoBloc>(),
        ),
        BlocProvider<DownloadBloc>(
          create: (_) => getIt<DownloadBloc>(),
        ),
      ],
      child: const VoiceMemosScreen(),
    );
  }
}
