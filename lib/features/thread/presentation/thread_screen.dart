import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/widgets/site_favicon.dart';
import '../../auth/domain/app_user.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../feed/domain/post.dart';
import '../../vote/presentation/vote_buttons.dart';
import '../data/thread_repository.dart';
import '../domain/comment.dart';
import 'comment_tile.dart';
import 'thread_controller.dart';

/// Post detail with its nested comment thread and a comment composer.
class ThreadScreen extends ConsumerWidget {
  const ThreadScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(threadProvider(postId));
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Thread')),
      floatingActionButton: async.hasValue
          ? FloatingActionButton.extended(
              onPressed: () => _composeComment(context, ref, user: user),
              icon: const Icon(Icons.add_comment_outlined),
              label: const Text('Comment'),
            )
          : null,
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ThreadError(
          message: error is ApiException ? error.message : 'Failed to load thread.',
          onRetry: () => ref.invalidate(threadProvider(postId)),
        ),
        data: (thread) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(threadProvider(postId)),
          child: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              _PostHeader(post: thread.post),
              const Divider(height: 1),
              _CommentsSection(
                comments: thread.comments,
                onReply: (parent) =>
                    _composeComment(context, ref, user: user, parent: parent),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _composeComment(
    BuildContext context,
    WidgetRef ref, {
    required AppUser? user,
    Comment? parent,
  }) async {
    if (user == null) {
      context.push('/signin');
      return;
    }

    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _CommentComposer(
        replyingTo: parent?.author,
      ),
    );
    if (text == null || text.trim().isEmpty || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(threadRepositoryProvider)
          .addComment(
            postId: postId,
            text: text.trim(),
            userName: user.displayName,
            replyId: parent?.id,
          );
      ref.invalidate(threadProvider(postId));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VoteButtons(
                resourceId: post.id,
                resourceType: 'post',
                fallbackCount: post.count,
                fallbackVote: post.currentVote,
              ),
              const SizedBox(width: 12),
              SiteFavicon(domain: post.link ?? post.domain, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  post.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'by ${post.author}'
            '${post.timeAgo != null ? '  ·  ${post.timeAgo}' : ''}'
            '${post.domain.isNotEmpty ? '  ·  ${post.domain}' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (post.tldr != null && post.tldr!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                post.tldr!,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
          if (post.description != null && post.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(post.description!, style: theme.textTheme.bodyMedium),
          ],
          if (post.link != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openLink(context, post.link!),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open link'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    final messenger = ScaffoldMessenger.of(context);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }
}

class _CommentsSection extends StatelessWidget {
  const _CommentsSection({required this.comments, required this.onReply});

  final List<Comment> comments;
  final void Function(Comment parent) onReply;

  @override
  Widget build(BuildContext context) {
    if (comments.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No comments yet. Be the first!')),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${comments.length} ${comments.length == 1 ? 'comment' : 'comments'}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        for (final comment in comments)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: CommentTile(comment: comment, onReply: onReply),
          ),
      ],
    );
  }
}

class _CommentComposer extends StatefulWidget {
  const _CommentComposer({this.replyingTo});

  final String? replyingTo;

  @override
  State<_CommentComposer> createState() => _CommentComposerState();
}

class _CommentComposerState extends State<_CommentComposer> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + viewInsets),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.replyingTo == null
                ? 'Add a comment'
                : 'Reply to ${widget.replyingTo}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            minLines: 3,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Share your thoughts…',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_controller.text),
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}

class _ThreadError extends StatelessWidget {
  const _ThreadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
