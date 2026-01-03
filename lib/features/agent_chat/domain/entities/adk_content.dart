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

/// Part structure - can contain text, function calls, or function responses
class AdkPart extends Equatable {
  const AdkPart({
    this.text,
    this.functionCall,
    this.functionResponse,
    this.inlineData,
  });

  final String? text;
  final AdkFunctionCall? functionCall;
  final AdkFunctionResponse? functionResponse;
  final AdkInlineData? inlineData;

  @override
  List<Object?> get props => [text, functionCall, functionResponse, inlineData];
}

/// Function call structure
class AdkFunctionCall extends Equatable {
  const AdkFunctionCall({
    required this.name,
    required this.args,
  });

  final String name;
  final Map<String, dynamic> args;

  @override
  List<Object?> get props => [name, args];
}

/// Function response structure
class AdkFunctionResponse extends Equatable {
  const AdkFunctionResponse({
    required this.name,
    required this.response,
  });

  final String name;
  final Map<String, dynamic> response;

  @override
  List<Object?> get props => [name, response];
}

/// Inline data (images, etc.)
class AdkInlineData extends Equatable {
  const AdkInlineData({
    required this.mimeType,
    required this.data,
  });

  final String mimeType;
  final String data; // base64 encoded

  @override
  List<Object?> get props => [mimeType, data];
}
