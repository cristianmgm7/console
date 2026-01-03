import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_voice_console/core/api/generated/lib/api.dart';

void main() {
  group('ADK DTO Verification', () {
    test('ContentPartsInner (REGENERATED) keeps functionCall with ID', () {
      final rawPartJson = <String, dynamic>{
        'functionCall': {
          'id': 'call_123',
          'name': 'testFunction',
          'args': {'key': 'value'}
        }
      };

      final partInfo = ContentPartsInner.fromJson(rawPartJson);

      expect(partInfo?.functionCall, isNotNull);
      expect(partInfo?.functionCall?.id, equals('call_123'));
      expect(partInfo?.functionCall?.name, equals('testFunction'));
      print('Part Info: $partInfo'); 
    });

    test('ContentPartsInner (REGENERATED) keeps functionResponse', () {
      final rawPartJson = <String, dynamic>{
        'functionResponse': {
          'name': 'testFunction',
          'response': {'status': 'ok'}
        }
      };

      final partInfo = ContentPartsInner.fromJson(rawPartJson);

      expect(partInfo?.functionResponse, isNotNull);
      expect(partInfo?.functionResponse?.name, equals('testFunction'));
      print('Part Info: $partInfo'); 
    });
  });
}
