import 'package:carbon_voice_console/core/di/injection.dart';
import 'package:carbon_voice_console/features/audio_player/presentation/bloc/audio_player_bloc.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:carbon_voice_console/features/auth/presentation/bloc/auth_event.dart'
    as auth_events;
import 'package:carbon_voice_console/features/conversations/presentation/bloc/conversation_bloc.dart';
import 'package:carbon_voice_console/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:carbon_voice_console/features/message_download/presentation/bloc/download_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_bloc.dart';
import 'package:carbon_voice_console/features/messages/presentation/bloc/message_detail_bloc.dart';
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
        BlocProvider<DownloadBloc>(
          create: (_) => getIt<DownloadBloc>(),
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
