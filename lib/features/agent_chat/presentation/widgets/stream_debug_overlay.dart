import 'package:flutter/material.dart';

/// Debug overlay to visualize streaming events in real-time.
///
/// Shows events as they arrive from the SSE stream, helping verify
/// that streaming is working correctly.
class StreamDebugOverlay extends StatefulWidget {
  const StreamDebugOverlay({
    required this.child,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final bool enabled;

  @override
  State<StreamDebugOverlay> createState() => _StreamDebugOverlayState();

  /// Access from anywhere in the widget tree to log events
  static void logEvent(BuildContext context, String event) {
    final state = context.findAncestorStateOfType<_StreamDebugOverlayState>();
    state?._addEvent(event);
  }
}

class _StreamDebugOverlayState extends State<StreamDebugOverlay> {
  final List<_EventLog> _events = [];
  final ScrollController _scrollController = ScrollController();
  bool _isExpanded = false;

  void _addEvent(String event) {
    if (!widget.enabled) return;

    setState(() {
      _events.add(_EventLog(
        event: event,
        timestamp: DateTime.now(),
      ));

      // Keep only last 50 events
      if (_events.length > 50) {
        _events.removeAt(0);
      }
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _isExpanded) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return Stack(
      children: [
        // Main content
        widget.child,

        // Debug overlay
        Positioned(
          right: 16,
          top: 80,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            color: Colors.black87,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isExpanded ? 350 : 200,
              height: _isExpanded ? 400 : 40,
              child: Column(
                children: [
                  // Header
                  InkWell(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.stream,
                            color: Colors.greenAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Stream Events (${_events.length})',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_events.isNotEmpty && !_isExpanded)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.greenAccent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${_events.length}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Icon(
                            _isExpanded
                                ? Icons.keyboard_arrow_down
                                : Icons.keyboard_arrow_up,
                            color: Colors.white70,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Event list
                  if (_isExpanded) ...[
                    const Divider(height: 1, color: Colors.white24),
                    Expanded(
                      child: _events.isEmpty
                          ? const Center(
                              child: Text(
                                'No events yet...\nSend a message to see streaming!',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(8),
                              itemCount: _events.length,
                              itemBuilder: (context, index) {
                                final event = _events[index];
                                return _EventTile(event: event);
                              },
                            ),
                    ),
                    const Divider(height: 1, color: Colors.white24),
                    // Clear button
                    InkWell(
                      onTap: () => setState(() => _events.clear()),
                      child: Container(
                        height: 32,
                        alignment: Alignment.center,
                        child: const Text(
                          'Clear',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EventLog {
  final String event;
  final DateTime timestamp;

  _EventLog({required this.event, required this.timestamp});
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final _EventLog event;

  @override
  Widget build(BuildContext context) {
    // Parse event type from string
    final (icon, color) = _getEventStyle(event.event);

    final timeStr = '${event.timestamp.hour.toString().padLeft(2, '0')}:'
        '${event.timestamp.minute.toString().padLeft(2, '0')}:'
        '${event.timestamp.second.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.event,
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _getEventStyle(String event) {
    final lower = event.toLowerCase();

    if (lower.contains('chat') || lower.contains('text')) {
      return (Icons.message, Colors.blueAccent);
    }
    if (lower.contains('function call') || lower.contains('calling')) {
      return (Icons.build, Colors.purpleAccent);
    }
    if (lower.contains('function response') || lower.contains('completed')) {
      return (Icons.check_circle, Colors.greenAccent);
    }
    if (lower.contains('auth')) {
      return (Icons.lock, Colors.amberAccent);
    }
    if (lower.contains('error')) {
      return (Icons.error, Colors.redAccent);
    }
    if (lower.contains('stream')) {
      return (Icons.stream, Colors.cyanAccent);
    }

    return (Icons.circle, Colors.white70);
  }
}

