import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace_enums.dart';

/// Helper class for organizing workspaces in the UI
class WorkspaceUIHelper {
  /// Groups workspaces by category for the current user
  static Map<WorkspaceCategory, List<Workspace>> groupByCategory(
    List<Workspace> workspaces,
    String currentUserId,
  ) {
    final grouped = <WorkspaceCategory, List<Workspace>>{};

    for (final workspace in workspaces) {
      final category = workspace.getCategory(currentUserId);

      // Skip hidden workspaces
      if (category == WorkspaceCategory.hidden) continue;

      grouped.putIfAbsent(category, () => []).add(workspace);
    }

    return grouped;
  }

  /// Returns workspaces in display order with category headers
  static List<WorkspaceDisplayItem> getDisplayItems(
    List<Workspace> workspaces,
    String currentUserId,
  ) {
    final grouped = groupByCategory(workspaces, currentUserId);
    final items = <WorkspaceDisplayItem>[];

    // Define category order
    const categoryOrder = [
      WorkspaceCategory.personal,
      WorkspaceCategory.standardMember,
      WorkspaceCategory.standardGuest,
      WorkspaceCategory.webcontact,
    ];

    for (final category in categoryOrder) {
      final categoryWorkspaces = grouped[category];
      if (categoryWorkspaces == null || categoryWorkspaces.isEmpty) continue;

      // Add category header
      items.add(WorkspaceDisplayItem.header(
        label: _getCategoryLabel(category),
        category: category,
      ));

      // Add workspaces in this category (sorted by name)
      final sorted = List<Workspace>.from(categoryWorkspaces)
        ..sort((a, b) => a.name.compareTo(b.name));

      for (final workspace in sorted) {
        items.add(WorkspaceDisplayItem.workspace(workspace));
      }
    }

    return items;
  }

  /// Gets display label for category
  static String _getCategoryLabel(WorkspaceCategory category) {
    return switch (category) {
      WorkspaceCategory.personal => 'Personal',
      WorkspaceCategory.standardMember => 'Workspaces',
      WorkspaceCategory.standardGuest => 'Guest Workspaces',
      WorkspaceCategory.webcontact => 'Web Contact',
      WorkspaceCategory.hidden => 'Hidden',
      WorkspaceCategory.unknown => 'Other',
    };
  }

  /// Gets icon for workspace type
  static String getWorkspaceIcon(WorkspaceType type) {
    return switch (type) {
      WorkspaceType.personal => '👤',
      WorkspaceType.standard => '🏢',
      WorkspaceType.workspace => '🏢',
      WorkspaceType.webcontact => '🌐',
      WorkspaceType.personallink => '🔗',
      WorkspaceType.unknown => '❓',
    };
  }

  /// Gets user role badge text
  static String? getRoleBadge(Workspace workspace, String currentUserId) {
    final role = workspace.getCurrentUserRole(currentUserId);
    return switch (role) {
      WorkspaceUserRole.admin => 'Admin',
      WorkspaceUserRole.owner => 'Owner',
      WorkspaceUserRole.guest => 'Guest',
      WorkspaceUserRole.member => null, // Don't show badge for members
      _ => null,
    };
  }
}

/// Represents an item in the workspace display list (header or workspace)
sealed class WorkspaceDisplayItem {
  const WorkspaceDisplayItem();

  factory WorkspaceDisplayItem.header({
    required String label,
    required WorkspaceCategory category,
  }) = WorkspaceHeaderItem;

  factory WorkspaceDisplayItem.workspace(Workspace workspace) = WorkspaceItem;
}

/// Category header item
class WorkspaceHeaderItem extends WorkspaceDisplayItem {
  const WorkspaceHeaderItem({
    required this.label,
    required this.category,
  });

  final String label;
  final WorkspaceCategory category;
}

/// Workspace item
class WorkspaceItem extends WorkspaceDisplayItem {
  const WorkspaceItem(this.workspace);

  final Workspace workspace;
}
