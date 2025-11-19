import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/models/meal_plan.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import 'cooking_video_list_screen.dart';

class CreateCookingVideoScreen extends ConsumerStatefulWidget {
  final CookingVideo? video; // If provided, we're editing

  const CreateCookingVideoScreen({
    super.key,
    this.video,
  });

  @override
  ConsumerState<CreateCookingVideoScreen> createState() =>
      _CreateCookingVideoScreenState();
}

class _CreateCookingVideoScreenState
    extends ConsumerState<CreateCookingVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _videoUrlController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.video != null) {
      _titleController.text = widget.video!.title;
      _descriptionController.text = widget.video!.description ?? '';
      _videoUrlController.text = widget.video!.videoUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveVideo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not found');
      }

      final mealPlanRepo = ref.read(mealPlanRepositoryProvider);

      final video = CookingVideo(
        id: widget.video?.id ?? const Uuid().v4(),
        coachId: user.id,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        videoUrl: _videoUrlController.text.trim(),
        createdAt: widget.video?.createdAt ?? DateTime.now(),
      );

      if (widget.video != null) {
        await mealPlanRepo.updateCookingVideo(video);
      } else {
        await mealPlanRepo.createCookingVideo(video);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.video != null
                  ? 'Video updated successfully'
                  : 'Video created successfully',
            ),
          ),
        );
        ref.invalidate(cookingVideoListProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.video != null ? 'Edit Video' : 'Add Cooking Video',
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveVideo,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Video Title *',
                hintText: 'e.g., How to Cook Grilled Chicken',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a video title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Optional description',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _videoUrlController,
              decoration: const InputDecoration(
                labelText: 'Video URL *',
                hintText: 'YouTube link or video URL',
                border: OutlineInputBorder(),
                helperText: 'Paste a YouTube link or video URL',
                prefixIcon: Icon(Icons.video_library),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a video URL';
                }
                final uri = Uri.tryParse(value);
                if (uri == null || !uri.hasScheme) {
                  return 'Please enter a valid URL';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You can paste a YouTube link or any video URL. YouTube videos will be playable within the app.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.blue[900],
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100), // Space for FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _saveVideo,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Video'),
      ),
    );
  }
}

