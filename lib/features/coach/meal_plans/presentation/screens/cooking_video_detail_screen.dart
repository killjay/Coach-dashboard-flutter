import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../../../core/models/meal_plan.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../core/theme/app_theme.dart';
import 'create_cooking_video_screen.dart';

/// Provider for cooking video detail
final cookingVideoDetailProvider =
    FutureProvider.family<CookingVideo, String>((ref, videoId) async {
  final mealPlanRepo = ref.watch(mealPlanRepositoryProvider);
  return mealPlanRepo.getCookingVideoById(videoId);
});

class CookingVideoDetailScreen extends ConsumerStatefulWidget {
  final String videoId;

  const CookingVideoDetailScreen({
    super.key,
    required this.videoId,
  });

  @override
  ConsumerState<CookingVideoDetailScreen> createState() =>
      _CookingVideoDetailScreenState();
}

class _CookingVideoDetailScreenState
    extends ConsumerState<CookingVideoDetailScreen> {
  YoutubePlayerController? _youtubeController;

  @override
  void dispose() {
    _youtubeController?.dispose();
    super.dispose();
  }

  String? _extractYouTubeVideoId(String url) {
    final regExp = RegExp(
      r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
    );
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }

  bool _isYouTubeUrl(String url) {
    return url.contains('youtube.com') || url.contains('youtu.be');
  }

  void _initializeYouTubePlayer(String videoUrl) {
    final videoId = _extractYouTubeVideoId(videoUrl);
    if (videoId != null) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          enableCaption: true,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final videoAsync = ref.watch(
      cookingVideoDetailProvider(widget.videoId),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cooking Video'),
        actions: [
          videoAsync.when(
            data: (video) => IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit Video',
              onPressed: () {
                context
                    .push('/coach/meal-plans/videos/create', extra: video)
                    .then((_) {
                  ref.invalidate(cookingVideoDetailProvider(widget.videoId));
                });
              },
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: videoAsync.when(
        data: (video) {
          final isYouTube = _isYouTubeUrl(video.videoUrl);
          if (isYouTube && _youtubeController == null) {
            _initializeYouTubePlayer(video.videoUrl);
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Video Player Section
                if (isYouTube && _youtubeController != null)
                  Container(
                    color: Colors.black,
                    child: YoutubePlayer(
                      controller: _youtubeController!,
                      showVideoProgressIndicator: true,
                      progressIndicatorColor: AppTheme.primaryColor,
                      progressColors: ProgressBarColors(
                        playedColor: AppTheme.primaryColor,
                        handleColor: AppTheme.primaryColor,
                      ),
                    ),
                  )
                else
                  Container(
                    height: 250,
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.video_library_outlined,
                            size: 64,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isYouTube
                                ? 'YouTube video'
                                : 'Video URL provided',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              // Open in external browser/app
                            },
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open Video'),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Video Info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video.title,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (video.description != null &&
                          video.description!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          video.description!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(
                            isYouTube
                                ? Icons.youtube_searched_for
                                : Icons.video_library,
                            size: 20,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            isYouTube ? 'YouTube Video' : 'Video URL',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red[300],
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading video',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

