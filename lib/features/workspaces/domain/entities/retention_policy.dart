import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace_enums.dart';
import 'package:equatable/equatable.dart';

/// Domain value object representing workspace retention policy configuration
class RetentionPolicy extends Equatable {
  const RetentionPolicy({
    required this.isEnabled,
    required this.retentionDays,
    required this.retentionDaysAsyncMeeting,
    required this.whoCanChangeConversationRetention,
    required this.whoCanMarkMessagesAsPreserved,
  });

  /// Whether retention is enabled for this workspace
  final bool isEnabled;

  /// Number of days to retain standard messages
  final int retentionDays;

  /// Number of days to retain async meeting messages
  final int retentionDaysAsyncMeeting;

  /// User roles that can change conversation retention settings
  final List<WorkspaceUserRole> whoCanChangeConversationRetention;

  /// User roles that can mark messages as preserved
  final List<WorkspaceUserRole> whoCanMarkMessagesAsPreserved;

  /// Factory for disabled retention policy
  factory RetentionPolicy.disabled() {
    return const RetentionPolicy(
      isEnabled: false,
      retentionDays: 0,
      retentionDaysAsyncMeeting: 0,
      whoCanChangeConversationRetention: [],
      whoCanMarkMessagesAsPreserved: [],
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        retentionDays,
        retentionDaysAsyncMeeting,
        whoCanChangeConversationRetention,
        whoCanMarkMessagesAsPreserved,
      ];
}
