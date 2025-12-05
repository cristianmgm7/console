import 'package:carbon_voice_console/features/messages/presentation_send_message/cubit/message_composition_cubit.dart';
import 'package:carbon_voice_console/features/messages/presentation_send_message/cubit/message_composition_state.dart';
import 'package:flutter_test/flutter_test.dart';

// Simple logger that does nothing - just to satisfy the dependency
class TestLogger {
  void d(dynamic message, {DateTime? time, Object? error, StackTrace? stackTrace}) {}
  void i(dynamic message, {DateTime? time, Object? error, StackTrace? stackTrace}) {}
}

void main() {
  late MessageCompositionCubit cubit;

  setUp(() {
    cubit = MessageCompositionCubit(TestLogger());
  });

  tearDown(() {
    cubit.close();
  });

  test('initial state is not visible', () {
    expect(cubit.state.isVisible, false);
    expect(cubit.state.canCompose, false);
  });

  test('openNewMessage sets state correctly', () {
    cubit.openNewMessage(workspaceId: 'ws1', channelId: 'ch1');

    expect(cubit.state.isVisible, true);
    expect(cubit.state.workspaceId, 'ws1');
    expect(cubit.state.channelId, 'ch1');
    expect(cubit.state.replyToMessageId, null);
    expect(cubit.state.isReply, false);
    expect(cubit.state.canCompose, true);
  });

  test('openReply sets reply state correctly', () {
    cubit.openReply(
      workspaceId: 'ws1',
      channelId: 'ch1',
      replyToMessageId: 'msg1',
    );

    expect(cubit.state.isVisible, true);
    expect(cubit.state.workspaceId, 'ws1');
    expect(cubit.state.channelId, 'ch1');
    expect(cubit.state.replyToMessageId, 'msg1');
    expect(cubit.state.isReply, true);
    expect(cubit.state.canCompose, true);
  });

  test('cancelReply clears reply but keeps panel open', () {
    cubit.openReply(
      workspaceId: 'ws1',
      channelId: 'ch1',
      replyToMessageId: 'msg1',
    );
    cubit.cancelReply();

    expect(cubit.state.isVisible, true);
    expect(cubit.state.workspaceId, 'ws1');
    expect(cubit.state.channelId, 'ch1');
    expect(cubit.state.replyToMessageId, null);
    expect(cubit.state.isReply, false);
  });

  test('closePanel resets state', () {
    cubit.openNewMessage(workspaceId: 'ws1', channelId: 'ch1');
    cubit.closePanel();

    expect(cubit.state, const MessageCompositionState());
  });

  test('onSuccess resets state', () {
    cubit.openReply(
      workspaceId: 'ws1',
      channelId: 'ch1',
      replyToMessageId: 'msg1',
    );
    cubit.onSuccess();

    expect(cubit.state, const MessageCompositionState());
  });

  test('canCompose returns false when workspaceId is null', () {
    cubit.openNewMessage(workspaceId: 'ws1', channelId: 'ch1');
    final newState = MessageCompositionState(
      isVisible: true,
      workspaceId: null, // Missing workspace
      channelId: 'ch1',
    );

    expect(newState.canCompose, false);
  });

  test('canCompose returns false when channelId is null', () {
    cubit.openNewMessage(workspaceId: 'ws1', channelId: 'ch1');
    final newState = MessageCompositionState(
      isVisible: true,
      workspaceId: 'ws1',
      channelId: null, // Missing channel
    );

    expect(newState.canCompose, false);
  });

  test('canCompose returns true when both workspaceId and channelId are set', () {
    cubit.openNewMessage(workspaceId: 'ws1', channelId: 'ch1');

    expect(cubit.state.canCompose, true);
  });
}
