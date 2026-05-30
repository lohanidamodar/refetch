import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/site_favicon.dart';
import '../../vote/presentation/vote_buttons.dart';
import '../domain/post.dart';

/// A single feed row: vote control, title, source/meta line, and comment count.
class PostCard extends ConsumerWidget {
  const PostCard({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: () => context.push('/thread/${post.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VoteButtons(
              resourceId: post.id,
              resourceType: 'post',
              fallbackCount: post.count,
              fallbackVote: post.currentVote,
            ),
            const SizedBox(width: 10),
            SiteFavicon(domain: post.link ?? post.domain),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    post.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _MetaLine(post: post),
                ],
              ),
            ),
            if (post.link != null) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Open link',
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.open_in_new, size: 18, color: scheme.onSurfaceVariant),
                onPressed: () => _openLink(context, post.link!),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openLink(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    final messenger = ScaffoldMessenger.of(context);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    final parts = <String>[
      if (post.domain.isNotEmpty) post.domain,
      if (post.timeAgo != null) post.timeAgo!,
      if (post.readingTime != null && post.readingTime! > 0)
        '${post.readingTime} min read',
    ];

    return Row(
      children: [
        Expanded(
          child: Text(
            parts.join('  ·  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
        const SizedBox(width: 8),
        Icon(Icons.mode_comment_outlined, size: 14, color: style?.color),
        const SizedBox(width: 4),
        Text('${post.countComments}', style: style),
      ],
    );
  }
}
