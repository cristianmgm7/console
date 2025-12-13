import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace_enums.dart';
import 'package:equatable/equatable.dart';

/// Domain value object representing workspace domain referral configuration
class DomainReferral extends Equatable {
  const DomainReferral({
    required this.mode,
    required this.message,
    required this.title,
    required this.domains,
  });

  /// Factory for default (no referral) configuration
  factory DomainReferral.none() {
    return const DomainReferral(
      mode: DomainReferralMode.doNotInform,
      message: '',
      title: '',
      domains: [],
    );
  }

  /// How to handle domain referrals
  final DomainReferralMode mode;

  /// Message to display for domain referrals
  final String message;

  /// Title for domain referral notifications
  final String title;

  /// List of domains associated with this workspace
  final List<String> domains;

  @override
  List<Object?> get props => [mode, message, title, domains];
}
