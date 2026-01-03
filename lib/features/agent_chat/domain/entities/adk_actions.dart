import 'package:carbon_voice_console/features/agent_chat/domain/entities/adk_auth.dart';
import 'package:equatable/equatable.dart';

/// Actions that can be attached to events
class AdkActions extends Equatable {
  const AdkActions({
    this.stateDelta,
    this.artifactDelta,
    this.transferToAgent,
    this.requestedAuthConfigs,
    this.requestedToolConfirmations,
  });

  final Map<String, dynamic>? stateDelta;
  final Map<String, dynamic>? artifactDelta;
  final String? transferToAgent;
  final Map<String, RequestedAuthConfig>? requestedAuthConfigs;
  final Map<String, dynamic>? requestedToolConfirmations;

  @override
  List<Object?> get props => [
        stateDelta,
        artifactDelta,
        transferToAgent,
        requestedAuthConfigs,
        requestedToolConfirmations,
      ];
}
