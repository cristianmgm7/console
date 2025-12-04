import 'package:carbon_voice_console/features/voice_memos/presentation/models/voice_memo_ui_model.dart';
import 'package:equatable/equatable.dart';

sealed class VoiceMemoState extends Equatable {
  const VoiceMemoState();

  @override
  List<Object?> get props => [];
}

class VoiceMemoInitial extends VoiceMemoState {
  const VoiceMemoInitial();
}

class VoiceMemoLoading extends VoiceMemoState {
  const VoiceMemoLoading();
}

class VoiceMemoLoaded extends VoiceMemoState {
  const VoiceMemoLoaded(this.voiceMemos);

  final List<VoiceMemoUiModel> voiceMemos;

  @override
  List<Object?> get props => [voiceMemos];
}

class VoiceMemoError extends VoiceMemoState {
  const VoiceMemoError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}




