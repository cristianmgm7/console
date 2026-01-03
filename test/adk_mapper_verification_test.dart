import 'package:flutter_test/flutter_test.dart';
import 'package:carbon_voice_console/core/api/generated/lib/api.dart';

void main() {
  group('ADK DTO Verification', () {
    test('ContentPartsInner (REGENERATED) keeps functionCall', () {
      final rawPartJson = <String, dynamic>{
        'functionCall': {
          'name': 'testFunction',
          'args': {'key': 'value'}
        }
      };

      final partInfo = ContentPartsInner.fromJson(rawPartJson);

      expect(partInfo?.functionCall, isNotNull);
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
