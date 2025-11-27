import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/models/progress.dart';
import '../../../../../core/providers/repository_providers.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../features/auth/presentation/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Provider for progress photos
final clientProgressPhotosProvider = FutureProvider<List<ProgressPhoto>>((ref) async {
  final progressRepo = ref.watch(progressRepositoryProvider);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return [];
  }

  return progressRepo.getProgressPhotos(clientId: user.id);
});

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;
  String _uploadStatus = ''; // Temporary progress tracking text

  Future<void> _uploadPhoto() async {
    debugPrint('📸 [ProgressPhoto] ========== UPLOAD STARTED ==========');
    debugPrint('📸 [ProgressPhoto] Platform: Web (kIsWeb check)');
    debugPrint('📸 [ProgressPhoto] ImagePicker instance created: ${_imagePicker.hashCode}');
    
    try {
      // 1. Pick the image (Works seamlessly on Web & Mobile)
      setState(() {
        _uploadStatus = 'Step 1/4: Opening image picker...';
        _isUploading = true;
      });
      debugPrint('📸 [ProgressPhoto] Step 1: Opening image picker...');
      debugPrint('📸 [ProgressPhoto] Calling _imagePicker.pickImage()...');
      
      final XFile? pickedFile;
      try {
        pickedFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        debugPrint('📸 [ProgressPhoto] Image picker returned: ${pickedFile != null ? "File selected" : "Cancelled"}');
      } catch (e, stackTrace) {
        debugPrint('❌ [ProgressPhoto] ERROR in image picker: $e');
        debugPrint('❌ [ProgressPhoto] Stack trace: $stackTrace');
        rethrow;
      }

      if (pickedFile == null) {
        setState(() {
          _uploadStatus = 'Cancelled';
          _isUploading = false;
        });
        debugPrint('📸 [ProgressPhoto] No image selected');
        return;
      }

      setState(() {
        _uploadStatus = 'Step 2/4: Reading image (${pickedFile.name})...';
      });
      debugPrint('📸 [ProgressPhoto] Step 2: Image selected: ${pickedFile.name}');
      debugPrint('📸 [ProgressPhoto] File path: ${pickedFile.path}');

      // 2. Read bytes (Works seamlessly on Web & Mobile)
      // On web: this reads the browser Blob. On mobile: reads the filesystem.
      debugPrint('📸 [ProgressPhoto] Step 2: Reading image as bytes...');
      debugPrint('📸 [ProgressPhoto] Calling pickedFile.readAsBytes()...');
      
      final Uint8List bytes;
      try {
        bytes = await pickedFile.readAsBytes();
        debugPrint('📸 [ProgressPhoto] readAsBytes() completed successfully');
      } catch (e, stackTrace) {
        debugPrint('❌ [ProgressPhoto] ERROR reading bytes: $e');
        debugPrint('❌ [ProgressPhoto] Stack trace: $stackTrace');
        rethrow;
      }

      if (bytes.isEmpty) {
        throw Exception('File is empty');
      }
      
      setState(() {
        _uploadStatus = 'Step 3/4: Uploading ${(bytes.length / 1024).toStringAsFixed(1)} KB...';
      });
      debugPrint('✅ [ProgressPhoto] Step 3: Successfully got ${bytes.length} bytes');

      final user = ref.read(currentUserProvider);
      if (user == null) {
        throw Exception('User not found');
      }
      
      debugPrint('📸 [ProgressPhoto] User ID: ${user.id}');
      final progressRepo = ref.read(progressRepositoryProvider);
      debugPrint('📸 [ProgressPhoto] Progress repository obtained: ${progressRepo.runtimeType}');
      
      // 3. Upload
      setState(() {
        _uploadStatus = 'Step 4/4: Saving to Firebase...';
      });
      debugPrint('📸 [ProgressPhoto] Step 4: Uploading to Firebase Storage...');
      debugPrint('📸 [ProgressPhoto] Calling progressRepo.uploadProgressPhoto()...');
      
      try {
        await progressRepo.uploadProgressPhoto(
          clientId: user.id,
          imageBytes: bytes,
        );
        debugPrint('✅ [ProgressPhoto] Repository upload completed successfully');
      } catch (e, stackTrace) {
        debugPrint('❌ [ProgressPhoto] ERROR in repository upload: $e');
        debugPrint('❌ [ProgressPhoto] Error type: ${e.runtimeType}');
        debugPrint('❌ [ProgressPhoto] Stack trace: $stackTrace');
        rethrow;
      }
      
      setState(() {
        _uploadStatus = '✅ Upload complete!';
      });
      debugPrint('✅ [ProgressPhoto] Upload completed successfully!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Progress photo uploaded successfully!'),
          ),
        );
        ref.invalidate(clientProgressPhotosProvider);
        
        // Clear status after a delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _uploadStatus = '';
            });
          }
        });
      }
    } catch (e, stackTrace) {
      final errorMessage = e.toString();
      final errorType = e.runtimeType.toString();
      
      setState(() {
        _uploadStatus = '❌ Error: $errorMessage';
      });
      
      debugPrint('❌ [ProgressPhoto] ========== ERROR CAUGHT ==========');
      debugPrint('❌ [ProgressPhoto] Error type: $errorType');
      debugPrint('❌ [ProgressPhoto] Error message: $errorMessage');
      debugPrint('❌ [ProgressPhoto] Full error object: $e');
      debugPrint('❌ [ProgressPhoto] Stack trace:');
      debugPrint('$stackTrace');
      debugPrint('❌ [ProgressPhoto] ===================================');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading photo: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Upload Error Details'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Type: $errorType'),
                          const SizedBox(height: 8),
                          Text('Message: $errorMessage'),
                          const SizedBox(height: 8),
                          const Text('Stack Trace:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            stackTrace.toString(),
                            style: const TextStyle(fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
        
        // Clear error status after a delay
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _uploadStatus = '';
            });
          }
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(clientProgressPhotosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Photos'),
        actions: [
          if (_isUploading)
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
              icon: const Icon(Icons.add_a_photo),
              tooltip: 'Upload Photo',
              onPressed: _uploadPhoto,
            ),
        ],
      ),
      body: Column(
        children: [
          // Temporary progress tracking text
          if (_uploadStatus.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: _uploadStatus.contains('❌')
                  ? Colors.red.shade50
                  : _uploadStatus.contains('✅')
                      ? Colors.green.shade50
                      : Colors.blue.shade50,
              child: Row(
                children: [
                  if (_isUploading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else if (_uploadStatus.contains('✅'))
                    const Icon(Icons.check_circle, color: Colors.green, size: 20)
                  else if (_uploadStatus.contains('❌'))
                    const Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _uploadStatus,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _uploadStatus.contains('❌')
                                ? Colors.red.shade900
                                : _uploadStatus.contains('✅')
                                    ? Colors.green.shade900
                                    : Colors.blue.shade900,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          // Main content
          Expanded(
            child: photosAsync.when(
              data: (photos) {
                if (photos.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No progress photos yet',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload photos to track your progress',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[500],
                              ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _uploadPhoto,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Upload Photo'),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(clientProgressPhotosProvider);
                  },
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: photos.length,
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      return _ProgressPhotoCard(photo: photo);
                    },
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
                      'Error loading photos',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _uploadPhoto,
        icon: _isUploading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.add_a_photo),
        label: Text(_isUploading ? 'Uploading...' : 'Upload Photo'),
      ),
    );
  }
}

class _ProgressPhotoCard extends StatelessWidget {
  final ProgressPhoto photo;

  const _ProgressPhotoCard({required this.photo});

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                Center(
                  child: CachedNetworkImage(
                    imageUrl: photo.imageUrl,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) => const Icon(
                      Icons.error,
                      color: Colors.red,
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 20,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: CachedNetworkImage(
                  imageUrl: photo.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.error, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                _formatDate(photo.takenAt),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
