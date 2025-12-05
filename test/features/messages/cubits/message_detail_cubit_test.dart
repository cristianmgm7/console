import 'package:carbon_voice_console/features/messages/presentation_messages_detail/cubit/message_detail_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

// Simple logger that does nothing - just to satisfy the dependency
class TestLogger {
  void d(dynamic message, {DateTime? time, Object? error, StackTrace? stackTrace}) {}
  void i(dynamic message, {DateTime? time, Object? error, StackTrace? stackTrace}) {}
}

// Simple bloc mock that just records events
class TestMessageDetailBloc {
  final List<dynamic> events = [];

  void add(dynamic event) {
    events.add(event);
  }

  Future<void> close() async {}
}

void main() {
  late MessageDetailCubit cubit;
  late TestMessageDetailBloc testBloc;

  setUp(() {
    testBloc = TestMessageDetailBloc();
    cubit = MessageDetailCubit(TestLogger(), testBloc);
  });

  tearDown(() {
    cubit.close();
  });

  test('initial state has no selected message', () {
    expect(cubit.state.selectedMessageId, null);
    expect(cubit.state.isVisible, false);
  });

  test('openDetail sets selected message', () {
    cubit.openDetail('msg1');

    expect(cubit.state.selectedMessageId, 'msg1');
    expect(cubit.state.isVisible, true);
  });

  test('openDetail triggers MessageDetailBloc', () {
    cubit.openDetail('msg1');

    expect(testBloc.events.length, 1);
    // Just verify that some event was added
    expect(testBloc.events.first, isNotNull);
  });

  test('closeDetail clears selected message', () {
    cubit.openDetail('msg1');
    cubit.closeDetail();

    expect(cubit.state.selectedMessageId, null);
    expect(cubit.state.isVisible, false);
  });

  test('openDetail with different message updates state', () {
    cubit.openDetail('msg1');
    cubit.openDetail('msg2');

    expect(cubit.state.selectedMessageId, 'msg2');
  });

  test('closeDetail when no message selected does nothing', () {
    cubit.closeDetail();

    expect(cubit.state.selectedMessageId, null);
    expect(cubit.state.isVisible, false);
  });
}
