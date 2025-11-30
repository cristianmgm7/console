import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:flutter/material.dart';

/// Example usage for voice memos:
/// ```dart
/// AppTable(
///   columns: const [
///     AppTableColumn(title: 'Name', width: FixedColumnWidth(150)),
///     AppTableColumn(title: 'Duration', width: FixedColumnWidth(80)),
///     AppTableColumn(title: 'Date', width: FixedColumnWidth(120)),
///     AppTableColumn(title: 'Actions', width: FixedColumnWidth(100)),
///   ],
///   rows: voiceMemos.map((memo) => AppTableRow(
///     cells: [
///       Text(memo.name),
///       Text(memo.duration),
///       Text(memo.createdAt),
///       IconButton(icon: Icon(Icons.play_arrow), onPressed: () {}),
///     ],
///   )).toList(),
/// )
/// ```

/// A reusable table widget with sticky header support
class AppTable extends StatefulWidget {
  const AppTable({
    required this.columns,
    required this.rows,
    this.selectAll,
    this.onSelectAllChanged,
    this.stickyHeader = true,
    super.key,
  });

  /// Column definitions
  final List<AppTableColumn> columns;

  /// Row data
  final List<AppTableRow> rows;

  /// Whether all rows are selected
  final bool? selectAll;

  /// Callback when select all checkbox is changed
  final ValueChanged<bool>? onSelectAllChanged;

  /// Whether header should be sticky (default: true)
  final bool stickyHeader;

  @override
  State<AppTable> createState() => _AppTableState();
}

class _AppTableState extends State<AppTable> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stickyHeader) {
      return _buildStickyHeaderTable();
    } else {
      return _buildRegularTable();
    }
  }

  Widget _buildStickyHeaderTable() {
    return Stack(
      children: [
        // Scrollable content with top padding for header
        Padding(
          padding: EdgeInsets.only(top: _calculateHeaderHeight()),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Table(
              columnWidths: _buildColumnWidths(),
              children: widget.rows.map((row) => row.build(context)).toList(),
            ),
          ),
        ),

        // Sticky header
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: ColoredBox(
            color: AppColors.surface,
            child: Table(
              columnWidths: _buildColumnWidths(),
              children: [_buildHeaderRow()],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegularTable() {
    return SingleChildScrollView(
      controller: _scrollController,
      child: Table(
        columnWidths: _buildColumnWidths(),
        children: [_buildHeaderRow(), ...widget.rows.map((row) => row.build(context))],
      ),
    );
  }

  TableRow _buildHeaderRow() {
    final headerCells = <Widget>[];

    // Add select all checkbox if needed
    if (widget.selectAll != null) {
      headerCells.add(
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: AppCheckbox(
              value: widget.selectAll ?? false,
              onChanged: widget.onSelectAllChanged,
            ),
          ),
        ),
      );
    }

    // Add column headers
    for (final column in widget.columns) {
      headerCells.add(
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Text(
              column.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }

    return TableRow(children: headerCells);
  }

  Map<int, TableColumnWidth> _buildColumnWidths() {
    final widths = <int, TableColumnWidth>{};

    // Add checkbox column width if needed
    var columnIndex = 0;
    if (widget.selectAll != null) {
      widths[columnIndex] = const FixedColumnWidth(48);
      columnIndex++;
    }

    // Add column widths
    for (final column in widget.columns) {
      widths[columnIndex] = column.width;
      columnIndex++;
    }

    return widths;
  }

  double _calculateHeaderHeight() {
    // Calculate header height based on content
    // This is approximate - could be made more precise
    return 56;
  }
}

/// Defines a table column
class AppTableColumn {
  const AppTableColumn({
    required this.title,
    required this.width,
  });

  final String title;
  final TableColumnWidth width;
}

/// Defines a table row with cells
class AppTableRow {
  const AppTableRow({
    required this.cells,
    this.selected = false,
    this.onSelectChanged,
  });

  final bool selected;
  final ValueChanged<bool?>? onSelectChanged;
  final List<Widget> cells;

  TableRow build(BuildContext context) {
    final rowCells = <Widget>[];

    // Add selection checkbox if callback provided
    if (onSelectChanged != null) {
      rowCells.add(
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: AppCheckbox(
              value: selected,
              onChanged: onSelectChanged,
            ),
          ),
        ),
      );
    }

    // Add data cells
    for (final cell in cells) {
      rowCells.add(
        TableCell(
          verticalAlignment: TableCellVerticalAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: cell,
          ),
        ),
      );
    }

    return TableRow(children: rowCells);
  }
}
