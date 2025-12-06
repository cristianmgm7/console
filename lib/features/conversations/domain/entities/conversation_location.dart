import 'package:equatable/equatable.dart';

/// Domain entity for location data
class ConversationLocation extends Equatable {
  const ConversationLocation({
    this.latitude,
    this.longitude,
  });

  final double? latitude;
  final double? longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}
