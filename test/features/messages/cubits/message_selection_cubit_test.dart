import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_selection_cubit.dart';
import 'package:carbon_voice_console/features/messages/presentation_messages_dashboard/cubits/message_selection_state.dart';
import 'package:flutter_test/flutter_test.dart';

// Simple logger that does nothing - just to satisfy the dependency
class TestLogger {
  void d(dynamic message, {DateTime? time, Object? error, StackTrace? stackTrace}) {}
  void i(dynamic message, {DateTime? time, Object? error, StackTrace? stackTrace}) {}
}

void main() {
  late MessageSelectionCubit cubit;

  setUp(() {
    cubit = MessageSelectionCubit(TestLogger());
  });

  tearDown(() {
    cubit.close();
  });

  test('initial state is empty', () {
    expect(cubit.state, const MessageSelectionState());
    expect(cubit.state.selectedCount, 0);
    expect(cubit.state.hasSelection, false);
  });

  test('toggleMessage adds message to selection', () {
    cubit.toggleMessage('msg1', value: true);

    expect(cubit.state.selectedMessageIds, {'msg1'});
    expect(cubit.state.selectedCount, 1);
    expect(cubit.state.hasSelection, true);
  });

  test('toggleMessage removes message from selection', () {
    cubit.toggleMessage('msg1', value: true);
    cubit.toggleMessage('msg1', value: false);

    expect(cubit.state.selectedMessageIds, isEmpty);
  });

  test('toggleMessage without value parameter toggles current state', () {
    cubit.toggleMessage('msg1'); // Should add
    expect(cubit.state.selectedMessageIds, {'msg1'});

    cubit.toggleMessage('msg1'); // Should remove
    expect(cubit.state.selectedMessageIds, isEmpty);
  });

  test('toggleSelectAll selects all messages', () {
    final allIds = ['msg1', 'msg2', 'msg3'];
    cubit.toggleSelectAll(allIds, value: true);

    expect(cubit.state.selectedMessageIds, {'msg1', 'msg2', 'msg3'});
    expect(cubit.state.selectAll, true);
  });

  test('toggleSelectAll without value parameter toggles current state', () {
    final allIds = ['msg1', 'msg2'];
    cubit.toggleSelectAll(allIds); // Should select all
    expect(cubit.state.selectAll, true);

    cubit.toggleSelectAll(allIds); // Should clear all
    expect(cubit.state.selectAll, false);
    expect(cubit.state.selectedMessageIds, isEmpty);
  });

  test('toggleSelectAll deselects all when already selected', () {
    final allIds = ['msg1', 'msg2'];
    cubit.toggleSelectAll(allIds, value: true);
    cubit.toggleSelectAll(allIds, value: false);

    expect(cubit.state, const MessageSelectionState());
  });

  test('clearSelection resets state', () {
    cubit.toggleMessage('msg1', value: true);
    cubit.clearSelection();

    expect(cubit.state, const MessageSelectionState());
  });

  test('getSelectedMessageIds returns copy of selected ids', () {
    cubit.toggleMessage('msg1', value: true);
    cubit.toggleMessage('msg2', value: true);

    final selectedIds = cubit.getSelectedMessageIds();
    expect(selectedIds, {'msg1', 'msg2'});

    // Modifying the returned set shouldn't affect the cubit state
    selectedIds.add('msg3');
    expect(cubit.state.selectedMessageIds, {'msg1', 'msg2'});
  });

  test('manual toggle clears selectAll flag', () {
    final allIds = ['msg1', 'msg2'];
    cubit.toggleSelectAll(allIds, value: true);
    expect(cubit.state.selectAll, true);

    cubit.toggleMessage('msg3', value: true);
    expect(cubit.state.selectAll, false);
  });
}
