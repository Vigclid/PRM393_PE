import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api/api_client.dart';
import '../api/post_api.dart';
import '../models/post.dart';
import '../theme/app_theme.dart';

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  final TextEditingController _composerController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedPostImage;
  bool _loading = true;
  bool _posting = false;
  String? _error;
  List<Post> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  @override
  void dispose() {
    _composerController.dispose();
    super.dispose();
  }

  Future<void> _pickPostImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null || !mounted) return;
    setState(() => _selectedPostImage = File(file.path));
  }

  Future<void> _loadFeed() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final posts = await PostApi.fetchFeed();
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load feed.';
        _loading = false;
      });
    }
  }

  Future<void> _createPost() async {
    final content = _composerController.text.trim();
    if ((content.isEmpty && _selectedPostImage == null) || _posting) return;
    setState(() => _posting = true);
    try {
      final created = await PostApi.createPost(
        content,
        imageFile: _selectedPostImage,
      );
      if (!mounted) return;
      _composerController.clear();
      FocusScope.of(context).unfocus();
      setState(() {
        _selectedPostImage = null;
        _posts = [created, ..._posts];
      });
    } on ApiException catch (e) {
      _showMessage(e.message, isError: true);
    } on NetworkException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (_) {
      _showMessage('Failed to create post.', isError: true);
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _react(String postId, String type) async {
    try {
      final updated = await PostApi.react(postId: postId, type: type);
      if (!mounted) return;
      _replacePost(updated);
    } on ApiException catch (e) {
      _showMessage(e.message, isError: true);
    } on NetworkException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (_) {
      _showMessage('Failed to update reaction.', isError: true);
    }
  }

  void _replacePost(Post updated) {
    final index = _posts.indexWhere((p) => p.id == updated.id);
    if (index < 0) return;
    setState(() => _posts = [..._posts]..[index] = updated);
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Community',
          style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _ComposerCard(
            controller: _composerController,
            imageFile: _selectedPostImage,
            posting: _posting,
            onPickImage: _pickPostImage,
            onRemoveImage: () => setState(() => _selectedPostImage = null),
            onPost: _createPost,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gold),
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.gold, size: 48),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.goldMuted)),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loadFeed,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (_posts.isEmpty) {
      return const Center(
        child: Text(
          'No posts yet. Share the first one!',
          style: TextStyle(color: AppColors.goldMuted),
        ),
      );
    }
    return RefreshIndicator(
      color: AppColors.gold,
      onRefresh: _loadFeed,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        itemCount: _posts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _PostCard(
          post: _posts[index],
          onReact: (type) => _react(_posts[index].id, type),
          onCommentPressed: () async {
            final updated = await showModalBottomSheet<Post>(
              context: context,
              isScrollControlled: true,
              backgroundColor: AppColors.surface,
              builder: (_) => _CommentSheet(post: _posts[index]),
            );
            if (updated != null) _replacePost(updated);
          },
        ),
      ),
    );
  }
}

class _ComposerCard extends StatelessWidget {
  final TextEditingController controller;
  final File? imageFile;
  final bool posting;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;
  final VoidCallback onPost;

  const _ComposerCard({
    required this.controller,
    required this.imageFile,
    required this.posting,
    required this.onPickImage,
    required this.onRemoveImage,
    required this.onPost,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          TextField(
            controller: controller,
            maxLines: 4,
            minLines: 2,
            style: const TextStyle(color: AppColors.gold),
            decoration: const InputDecoration(
              hintText: 'What are you thinking?',
              hintStyle: TextStyle(color: AppColors.goldMuted),
            ),
          ),
          if (imageFile != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  Image.file(
                    imageFile!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: InkWell(
                      onTap: onRemoveImage,
                      child: const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: onPickImage,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Photo'),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: posting ? null : onPost,
                icon: posting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onGold,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: const Text('Post'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final Post post;
  final ValueChanged<String> onReact;
  final VoidCallback onCommentPressed;

  const _PostCard({
    required this.post,
    required this.onReact,
    required this.onCommentPressed,
  });

  static const Map<String, String> _emoji = {
    'like': '👍',
    'love': '❤️',
    'haha': '😂',
    'wow': '😮',
    'sad': '😢',
    'angry': '😡',
  };

  @override
  Widget build(BuildContext context) {
    final selected = post.reactions.myReaction;
    final myReactionIcon = selected == null ? '👍' : (_emoji[selected] ?? '👍');
    final myReactionLabel = selected == null
        ? 'Like'
        : _titleReaction(selected);

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.gold.withValues(alpha: 0.2),
                  child: Text(
                    _initials(post.author.displayName),
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.author.displayName,
                        style: const TextStyle(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _timeAgo(post.createdAt),
                        style: const TextStyle(
                          color: AppColors.goldMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (post.content.isNotEmpty)
              Text(
                post.content,
                style: const TextStyle(color: AppColors.gold, height: 1.4),
              ),
            if (post.imageUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  post.imageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 120,
                    color: AppColors.background,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.goldMuted,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '${post.reactions.total} reactions',
                  style: const TextStyle(
                    color: AppColors.goldMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  '${_countComments(post.comments)} comments',
                  style: const TextStyle(
                    color: AppColors.goldMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.border, height: 18),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onLongPressStart: (details) =>
                        _showReactionMenu(context, details.globalPosition),
                    child: OutlinedButton.icon(
                      onPressed: () => onReact(selected ?? 'like'),
                      icon: Text(myReactionIcon),
                      label: Text(myReactionLabel),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: selected == null
                              ? AppColors.border
                              : AppColors.gold,
                        ),
                        foregroundColor: selected == null
                            ? AppColors.goldMuted
                            : AppColors.gold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onCommentPressed,
                    icon: const Icon(Icons.comment_outlined, size: 18),
                    label: const Text('Comments'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      foregroundColor: AppColors.goldMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showReactionMenu(BuildContext context, Offset position) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final selected = await showMenu<String>(
      context: context,
      color: AppColors.surface,
      position: RelativeRect.fromRect(
        Rect.fromCircle(center: position, radius: 4),
        Offset.zero & overlay.size,
      ),
      items: _emoji.entries
          .map(
            (entry) => PopupMenuItem<String>(
              value: entry.key,
              child: Text('${entry.value} ${_titleReaction(entry.key)}'),
            ),
          )
          .toList(),
    );
    if (selected != null) onReact(selected);
  }

  static int _countComments(List<PostComment> comments) {
    var total = 0;
    for (final c in comments) {
      total += 1 + c.replies.length;
    }
    return total;
  }

  static String _titleReaction(String value) =>
      value[0].toUpperCase() + value.substring(1);

  static String _initials(String text) {
    final parts = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

class _CommentSheet extends StatefulWidget {
  final Post post;
  const _CommentSheet({required this.post});

  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  static const Map<String, String> _emoji = {
    'like': '👍',
    'love': '❤️',
    'haha': '😂',
    'wow': '😮',
    'sad': '😢',
    'angry': '😡',
  };

  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _submitting = false;
  PostComment? _replyTarget;
  File? _commentImage;
  late Post _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickCommentImage() async {
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null || !mounted) return;
    setState(() => _commentImage = File(file.path));
  }

  Future<void> _send() async {
    final content = _controller.text.trim();
    if ((content.isEmpty && _commentImage == null) || _submitting) return;
    setState(() => _submitting = true);
    try {
      final updated = _replyTarget == null
          ? await PostApi.comment(
              postId: _post.id,
              content: content,
              imageFile: _commentImage,
            )
          : await PostApi.reply(
              postId: _post.id,
              commentId: _replyTarget!.id,
              content: content,
              imageFile: _commentImage,
            );
      if (!mounted) return;
      setState(() {
        _post = updated;
        _replyTarget = null;
        _commentImage = null;
        _controller.clear();
      });
    } on ApiException catch (e) {
      _toast(e.message, true);
    } on NetworkException catch (e) {
      _toast(e.message, true);
    } catch (_) {
      _toast('Failed to submit comment.', true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _reactComment(PostComment comment, String type) async {
    try {
      final updated = await PostApi.reactComment(
        postId: _post.id,
        commentId: comment.id,
        type: type,
      );
      if (!mounted) return;
      setState(() => _post = updated);
    } on ApiException catch (e) {
      _toast(e.message, true);
    } on NetworkException catch (e) {
      _toast(e.message, true);
    } catch (_) {
      _toast('Failed to update reaction.', true);
    }
  }

  Future<void> _showCommentReactionMenu(
    PostComment comment,
    Offset position,
  ) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final selected = await showMenu<String>(
      context: context,
      color: AppColors.surface,
      position: RelativeRect.fromRect(
        Rect.fromCircle(center: position, radius: 4),
        Offset.zero & overlay.size,
      ),
      items: _emoji.entries
          .map(
            (entry) => PopupMenuItem<String>(
              value: entry.key,
              child: Text('${entry.value} ${_titleReaction(entry.key)}'),
            ),
          )
          .toList(),
    );
    if (selected != null) _reactComment(comment, selected);
  }

  void _toast(String text, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context, _post),
                      icon: const Icon(Icons.close, color: AppColors.goldMuted),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  children: [
                    for (final c in _post.comments) ...[
                      _CommentTile(
                        comment: c,
                        onReply: () => setState(() => _replyTarget = c),
                        onReact: () =>
                            _reactComment(c, c.reactions.myReaction ?? 'like'),
                        onLongReact: (position) =>
                            _showCommentReactionMenu(c, position),
                      ),
                      for (final reply in c.replies)
                        Padding(
                          padding: const EdgeInsets.only(left: 22, top: 8),
                          child: _CommentTile(
                            comment: reply,
                            onReact: () => _reactComment(
                              reply,
                              reply.reactions.myReaction ?? 'like',
                            ),
                            onLongReact: (position) =>
                                _showCommentReactionMenu(reply, position),
                          ),
                        ),
                      const SizedBox(height: 10),
                    ],
                    if (_post.comments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text(
                          'No comments yet.',
                          style: TextStyle(color: AppColors.goldMuted),
                        ),
                      ),
                  ],
                ),
              ),
              if (_replyTarget != null)
                Container(
                  width: double.infinity,
                  color: AppColors.background,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Replying to ${_replyTarget!.author.displayName}',
                          style: const TextStyle(
                            color: AppColors.goldMuted,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _replyTarget = null),
                        icon: const Icon(Icons.close, size: 18),
                      ),
                    ],
                  ),
                ),
              if (_commentImage != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _commentImage!,
                          height: 90,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 6,
                        right: 6,
                        child: InkWell(
                          onTap: () => setState(() => _commentImage = null),
                          child: const CircleAvatar(
                            radius: 13,
                            backgroundColor: Colors.black54,
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _pickCommentImage,
                      icon: const Icon(
                        Icons.image_outlined,
                        color: AppColors.goldMuted,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        style: const TextStyle(color: AppColors.gold),
                        decoration: InputDecoration(
                          hintText: _replyTarget == null
                              ? 'Write a comment...'
                              : 'Write a reply...',
                          hintStyle: const TextStyle(
                            color: AppColors.goldMuted,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _submitting ? null : _send,
                      child: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.onGold,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final PostComment comment;
  final VoidCallback? onReply;
  final VoidCallback onReact;
  final ValueChanged<Offset> onLongReact;

  const _CommentTile({
    required this.comment,
    this.onReply,
    required this.onReact,
    required this.onLongReact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                comment.author.displayName,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                _PostCard._timeAgo(comment.createdAt),
                style: const TextStyle(
                  color: AppColors.goldMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (comment.content.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              comment.content,
              style: const TextStyle(color: AppColors.gold),
            ),
          ],
          if (comment.imageUrl.isNotEmpty) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                comment.imageUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 80,
                  color: AppColors.surface,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: AppColors.goldMuted,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              GestureDetector(
                onLongPressStart: (details) =>
                    onLongReact(details.globalPosition),
                child: TextButton.icon(
                  onPressed: onReact,
                  icon: Text(
                    comment.reactions.myReaction == null
                        ? '👍'
                        : _reactionIcon(comment.reactions.myReaction!),
                  ),
                  label: Text(
                    comment.reactions.myReaction == null
                        ? 'Like'
                        : _titleReaction(comment.reactions.myReaction!),
                  ),
                ),
              ),
              Text(
                '${comment.reactions.total}',
                style: const TextStyle(color: AppColors.goldMuted),
              ),
              const Spacer(),
              if (onReply != null)
                TextButton(onPressed: onReply, child: const Text('Reply')),
            ],
          ),
        ],
      ),
    );
  }

  static String _reactionIcon(String reaction) {
    return switch (reaction) {
      'love' => '❤️',
      'haha' => '😂',
      'wow' => '😮',
      'sad' => '😢',
      'angry' => '😡',
      _ => '👍',
    };
  }
}

String _titleReaction(String value) =>
    value[0].toUpperCase() + value.substring(1);
