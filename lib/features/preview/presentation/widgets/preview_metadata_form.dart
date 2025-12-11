import 'package:carbon_voice_console/core/theme/app_colors.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_bloc.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_event.dart';
import 'package:carbon_voice_console/features/preview/presentation/bloc/preview_composer_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Form for entering preview metadata
class PreviewMetadataForm extends StatefulWidget {
  const PreviewMetadataForm({super.key});

  @override
  State<PreviewMetadataForm> createState() => _PreviewMetadataFormState();
}

class _PreviewMetadataFormState extends State<PreviewMetadataForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _coverImageUrlController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _coverImageUrlController = TextEditingController();

    // Initialize with BLoC state values
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = context.read<PreviewComposerBloc>().state;
      if (state is PreviewComposerLoaded) {
        _titleController.text = state.currentMetadata.title;
        _descriptionController.text = state.currentMetadata.description;
        _coverImageUrlController.text = state.currentMetadata.coverImageUrl ?? '';
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _coverImageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreviewComposerBloc, PreviewComposerState>(
      builder: (context, state) {
        if (state is! PreviewComposerLoaded) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title field
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Preview Title *',
                hintText: 'Enter a catchy title for your preview',
                errorText: state.titleError,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              maxLength: PreviewComposerBloc.maxTitleLength,
              onChanged: (value) {
                context.read<PreviewComposerBloc>().add(
                  PreviewTitleUpdated(value),
                );
              },
            ),
            const SizedBox(height: 16),

            // Description field
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Short Description *',
                hintText:
                    'Brief description (max ${PreviewComposerBloc.maxDescriptionLength} characters)',
                errorText: state.descriptionError,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              maxLines: 3,
              maxLength: PreviewComposerBloc.maxDescriptionLength,
              onChanged: (value) {
                context.read<PreviewComposerBloc>().add(
                  PreviewDescriptionUpdated(value),
                );
              },
            ),
            const SizedBox(height: 16),

            // Cover image URL field
            TextField(
              controller: _coverImageUrlController,
              decoration: InputDecoration(
                labelText: 'Cover Image URL (optional)',
                hintText: 'https://example.com/image.jpg',
                errorText: state.coverImageUrlError,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                helperText: 'Leave empty to use conversation cover image',
              ),
              onChanged: (value) {
                context.read<PreviewComposerBloc>().add(
                  PreviewCoverImageUpdated(value.isEmpty ? null : value),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
