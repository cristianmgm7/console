import 'package:carbon_voice_console/core/theme/app_borders.dart';
import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/core/theme/app_text_style.dart';
import 'package:carbon_voice_console/core/widgets/widgets.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace.dart';
import 'package:carbon_voice_console/features/workspaces/domain/entities/workspace_enums.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_bloc.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_event.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/bloc/workspace_state.dart';
import 'package:carbon_voice_console/features/workspaces/presentation/utils/workspace_ui_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Enhanced workspace selector with categorization and images
class WorkspaceSelector extends StatelessWidget {
  const WorkspaceSelector({
    required this.currentUserId,
    required this.workspaceState,
    this.width = 200,
    super.key,
  });

  final String currentUserId;
  final WorkspaceLoaded workspaceState;
  final double width;

  @override
  Widget build(BuildContext context) {
    if (workspaceState.workspaces.isEmpty) {
      return const SizedBox.shrink();
    }

    final displayItems = WorkspaceUIHelper.getDisplayItems(
      workspaceState.workspaces,
      currentUserId,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Workspace',
          style: AppTextStyle.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: width,
          child: _buildDropdown(
            context,
            workspaceState,
            displayItems,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
    BuildContext context,
    WorkspaceLoaded state,
    List<WorkspaceDisplayItem> displayItems,
  ) {
    final selectedWorkspace = state.selectedWorkspace;

    return PopupMenuButton<String>(
      color: AppColors.surface,
      borderRadius: AppBorders.card,
      tooltip: 'Select workspace',
      offset: const Offset(0, 45),
      child: AppContainer(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        backgroundColor: AppColors.surface,
        border: Border.all(color: AppColors.border),
        child: Row(
          children: [
            // Workspace image
            if (selectedWorkspace?.imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  selectedWorkspace!.imageUrl!,
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildDefaultWorkspaceIcon(selectedWorkspace.type),
                ),
              )
            else
              _buildDefaultWorkspaceIcon(selectedWorkspace?.type ?? WorkspaceType.unknown),

            const SizedBox(width: 8),

            // Workspace name
            Expanded(
              child: Text(
                selectedWorkspace?.name ?? 'Select workspace',
                style: AppTextStyle.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(width: 4),

            // Dropdown icon
            const Icon(
              Icons.arrow_drop_down,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
      itemBuilder: (context) {
        return displayItems.map((item) {
          return switch (item) {
            WorkspaceHeaderItem(:final label) => PopupMenuItem<String>(
                enabled: false,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  label,
                  style: AppTextStyle.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            WorkspaceItem(:final workspace) => PopupMenuItem<String>(
                value: workspace.id,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: _buildWorkspaceMenuItem(workspace),
              ),
          };
        }).toList();
      },
      onSelected: (String workspaceId) {
        context.read<WorkspaceBloc>().add(SelectWorkspace(workspaceId));
      },
    );
  }

  Widget _buildWorkspaceMenuItem(Workspace workspace) {
    final roleBadge = WorkspaceUIHelper.getRoleBadge(workspace, currentUserId);

    return Row(
      children: [
        // Workspace image
        if (workspace.imageUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.network(
              workspace.imageUrl!,
              width: 24,
              height: 24,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildDefaultWorkspaceIcon(workspace.type),
            ),
          )
        else
          _buildDefaultWorkspaceIcon(workspace.type),

        const SizedBox(width: 12),

        // Workspace name
        Expanded(
          child: Text(
            workspace.name,
            style: AppTextStyle.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Role badge
        if (roleBadge != null) ...[
          const SizedBox(width: 8),
          AppContainer(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            child: Text(
              roleBadge,
              style: AppTextStyle.bodySmall.copyWith(
                color: AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDefaultWorkspaceIcon(WorkspaceType type) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Center(
        child: Text(
          WorkspaceUIHelper.getWorkspaceIcon(type),
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
