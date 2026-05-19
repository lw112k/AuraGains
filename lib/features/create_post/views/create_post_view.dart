import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import '../../../core/theme/app_theme.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import '../view_models/create_post_viewmodel.dart';
import '../models/create_post_model.dart';
import '../../auth/view_models/auth_viewmodel.dart';
import 'dart:io';

class CreatePostView extends StatefulWidget {
  const CreatePostView({super.key});

  @override
  State<CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<CreatePostView> {
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Fetch tags from the database immediately when the screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CreatePostViewModel>().loadSystemTags();
    });
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<CreatePostViewModel>();
    final currentUserId = context.read<AuthViewModel>().currentUser?.id ?? '';
    final customTags = viewModel.post.tags
        .where((t) => t.type == TagType.user)
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.surfaceFrame,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceFrame,
        centerTitle: true,
        elevation: 0,
        title: const Text(
          'New Post',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: viewModel.isLoading
                ? null
                : () async {
                    bool success = await viewModel.publishPost(currentUserId);

                    if (success && mounted) {
                      Navigator.pop(context);
                    } else if (viewModel.errorMessage != null && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(viewModel.errorMessage!)),
                      );
                    }
                  },
            child: viewModel.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryAccent,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Publish',
                    style: TextStyle(
                      color: AppTheme.primaryAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. THUMBNAIL (COVER) SECTION ---
            const Text(
              'Cover Thumbnail',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose a single image to represent your post.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 12),

            if (viewModel.thumbnailImage == null)
              GestureDetector(
                onTap: viewModel.pickThumbnail,
                child: Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryAccent.withOpacity(0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppTheme.primaryAccent.withOpacity(0.7),
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add Cover',
                        style: TextStyle(
                          color: AppTheme.primaryAccent.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Stack(
                children: [
                  Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryAccent,
                        width: 2,
                      ),
                      image: DecorationImage(
                        image: kIsWeb
                            ? NetworkImage(viewModel.thumbnailImage!.path)
                                  as ImageProvider
                            : FileImage(File(viewModel.thumbnailImage!.path)),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: viewModel.removeThumbnail,
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 24),

            // --- 2. MULTI-MEDIA SECTION ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Post Media',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Supported: JPG, PNG, MP4, MOV, AVI, MKV',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                OutlinedButton.icon(
                  icon: const Icon(
                    Icons.perm_media_outlined,
                    color: AppTheme.primaryAccent,
                    size: 18,
                  ),
                  label: const Text(
                    'Attach',
                    style: TextStyle(
                      color: AppTheme.primaryAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                      color: AppTheme.primaryAccent,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                  ),
                  onPressed: viewModel.pickMedia,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // --- THE MULTI-MEDIA CAROUSEL ---
            if (viewModel.post.mediaList.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: viewModel.post.mediaList.length,
                  itemBuilder: (context, index) {
                    final media = viewModel.post.mediaList[index];
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _showFullScreenPreview(context, media),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: media.type == MediaType.video
                                  ? AppTheme.primaryAccent.withOpacity(0.1)
                                  : const Color(0xFF2C2C2C),
                              border: media.type == MediaType.video
                                  ? Border.all(
                                      color: AppTheme.primaryAccent.withOpacity(
                                        0.4,
                                      ),
                                    )
                                  : null,
                              image: media.type == MediaType.picture
                                  ? DecorationImage(
                                      image: kIsWeb
                                          ? NetworkImage(media.file.path)
                                                as ImageProvider
                                          : FileImage(File(media.file.path)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: media.type == MediaType.video
                                ? const Center(
                                    child: Icon(
                                      Icons.play_circle_fill,
                                      color: AppTheme.primaryAccent,
                                      size: 44,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 16,
                          child: GestureDetector(
                            onTap: () => viewModel.removeMedia(index),
                            child: const CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.black54,
                              child: Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            if (viewModel.post.mediaList.isNotEmpty) const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 32),

            // --- 3. TEXT INPUTS ---
            TextField(
              maxLength: 30,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                hintText: 'Give your post a title...',
                hintStyle: TextStyle(
                  color: Colors.grey,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                border: InputBorder.none,
                counterStyle: TextStyle(color: Colors.grey),
              ),
              onChanged: viewModel.setTitle,
            ),
            TextField(
              style: const TextStyle(color: Colors.white, fontSize: 16),
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Share your workout, diet, or progress...',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                border: InputBorder.none,
              ),
              onChanged: viewModel.setDescription,
            ),
            const Divider(color: Colors.white24, height: 32),

            // --- 4. POST SETTINGS ---
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Post Type',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: DropdownButton<PostType>(
                dropdownColor: const Color(0xFF2C2C2C),
                value: viewModel.post.postType,
                style: const TextStyle(
                  color: AppTheme.primaryAccent,
                  fontWeight: FontWeight.w600,
                ),
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(
                    value: PostType.normal,
                    child: Text('Normal Post'),
                  ),
                  DropdownMenuItem(
                    value: PostType.askExpert,
                    child: Text('Ask Expert'),
                  ),
                ],
                onChanged: (val) => viewModel.setPostType(val!),
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Visibility',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              trailing: DropdownButton<PostVisibility>(
                dropdownColor: const Color(0xFF2C2C2C),
                value: viewModel.post.visibility,
                style: TextStyle(
                  color: viewModel.post.postType == PostType.askExpert
                      ? Colors.grey
                      : AppTheme.primaryAccent,
                  fontWeight: FontWeight.w600,
                ),
                underline: const SizedBox(),
                onChanged: viewModel.post.postType == PostType.askExpert
                    ? null
                    : (val) => viewModel.setVisibility(val!),
                items: const [
                  DropdownMenuItem(
                    value: PostVisibility.public,
                    child: Text('Public'),
                  ),
                  DropdownMenuItem(
                    value: PostVisibility.friends,
                    child: Text('Friends'),
                  ),
                  DropdownMenuItem(
                    value: PostVisibility.private,
                    child: Text('Private'),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 32),

            // --- 5. SYSTEM TAGS (PILL BOXES) ---
            const Text(
              'Select Tags (Minimum 1)',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            viewModel.isTagsLoading
                ? const Text(
                    "Loading available categories...",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  )
                : viewModel.availableSystemTags.isEmpty
                ? const Text(
                    "No system categories found.",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: viewModel.availableSystemTags.map((tag) {
                      final isSelected = viewModel.post.tags.any(
                        (t) => t.name == tag.name,
                      );
                      return FilterChip(
                        label: Text(
                          '#${tag.name}',
                          style: TextStyle(
                            color: isSelected
                                ? Colors.black
                                : AppTheme.primaryAccent,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: AppTheme.primaryAccent,
                        backgroundColor: const Color(0xFF2C2C2C),
                        checkmarkColor: Colors.black,
                        side: BorderSide(
                          color: isSelected
                              ? AppTheme.primaryAccent
                              : Colors.white24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        onSelected: (bool selected) {
                          viewModel.toggleTag(tag);
                        },
                      );
                    }).toList(),
                  ),
            const SizedBox(height: 24),

            // --- 6. CUSTOM USER TAGS ---
            const Text(
              'Custom Tags',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            if (customTags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: customTags.map((tag) {
                  return Chip(
                    backgroundColor: AppTheme.primaryAccent.withOpacity(0.2),
                    label: Text(
                      '#${tag.name}',
                      style: const TextStyle(
                        color: AppTheme.primaryAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    deleteIcon: const Icon(
                      Icons.cancel,
                      color: AppTheme.primaryAccent,
                      size: 18,
                    ),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    onDeleted: () => viewModel.toggleTag(tag),
                  );
                }).toList(),
              ),
            if (customTags.isNotEmpty) const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _tagController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Add a custom tag and press Enter',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(
                      Icons.add_circle,
                      color: AppTheme.primaryAccent,
                    ),
                    onPressed: () {
                      viewModel.addCustomTag(_tagController.text);
                      _tagController.clear();
                    },
                  ),
                ),
                onSubmitted: (value) {
                  viewModel.addCustomTag(value);
                  _tagController.clear();
                },
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- FULL SCREEN MEDIA PREVIEW ---
  void _showFullScreenPreview(BuildContext context, SelectedMedia media) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
              child: InteractiveViewer(
                child: media.type == MediaType.picture
                    ? (kIsWeb
                          ? Image.network(media.file.path)
                          : Image.file(File(media.file.path)))
                    : VideoPreviewWidget(file: media.file),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.cancel, color: Colors.white, size: 36),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- STANDALONE VIDEO PREVIEW WIDGET ---
class VideoPreviewWidget extends StatefulWidget {
  final XFile file;
  const VideoPreviewWidget({super.key, required this.file});

  @override
  State<VideoPreviewWidget> createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.file.path),
      );
    } else {
      _controller = VideoPlayerController.file(File(widget.file.path));
    }

    _controller
        .initialize()
        .then((_) {
          setState(() {
            _isInitialized = true;
          });
          _controller.setLooping(true);
          _controller.play();
        })
        .catchError((error) {
          debugPrint("Video initialization error: $error");
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryAccent),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying
              ? _controller.pause()
              : _controller.play();
        });
      },
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(_controller),
            if (!_controller.value.isPlaying)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 48,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
