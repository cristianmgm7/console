import 'package:equatable/equatable.dart';

/// Content structure matching ADK's Content type
class AdkContent extends Equatable {
  const AdkContent({
    required this.role,
    required this.parts,
  });

  final String role;
  final List<AdkPart> parts;

  @override
  List<Object?> get props => [role, parts];
}

/// Polymorphic Part structure - can contain text, function calls, or function responses
sealed class AdkPart extends Equatable {
  const AdkPart();
}

/// Text part
class AdkTextPart extends AdkPart {
  const AdkTextPart({required this.text});

  final String text;

  /// Check if this text part contains A2UI payload
  bool get containsA2Ui => text.contains('---a2ui_JSON---');

  @override
  List<Object?> get props => [text];
}

/// Function call part
class AdkFunctionCallPart extends AdkPart {
  const AdkFunctionCallPart({
    required this.name,
    required this.args,
    this.id,
  });

  final String name;
  final Map<String, dynamic> args;
  final String? id;

  @override
  List<Object?> get props => [name, args, id];
}

/// Function response part
class AdkFunctionResponsePart extends AdkPart {
  const AdkFunctionResponsePart({
    required this.name,
    required this.response,
  });

  final String name;
  final Map<String, dynamic> response;

  @override
  List<Object?> get props => [name, response];
}

/// Inline data part (images, etc.)
class AdkInlineDataPart extends AdkPart {
  const AdkInlineDataPart({
    required this.mimeType,
    required this.data,
  });

  final String mimeType;
  final String data; // base64 encoded

  @override
  List<Object?> get props => [mimeType, data];
}

/// Unknown/Fallback part
class AdkUnknownPart extends AdkPart {
  const AdkUnknownPart();

  @override
  List<Object?> get props => [];
}

// Legacy type aliases for backward compatibility if needed, 
// or validation helper objects can be added here if the rest of the app 
// relied on the old classes independently. 
// For now, removing the standalone AdkFunctionCall/Response classes 
// since they are now Parts.
