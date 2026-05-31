import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/error_message.dart';
import '../../auth/presentation/auth_controller.dart';
import '../domain/vote_state.dart';
import 'vote_controller.dart';

/// Up/down vote control with the score between, for a post or comment.
///
/// Reads live state from [voteControllerProvider], falling back to the
/// resource's own [fallbackCount] / [fallbackVote] when not yet tracked.
class VoteButtons extends ConsumerWidget {
  const VoteButtons({
    super.key,
    required this.resourceId,
    required this.resourceType,
    required this.fallbackCount,
    this.fallbackVote,
    this.compact = false,
  });

  final String resourceId;
  final String resourceType; // 'post' | 'comment'
  final int fallbackCount;
  final String? fallbackVote;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final votes = ref.watch(voteControllerProvider);
    final fallback = VoteState(count: fallbackCount, currentVote: fallbackVote);
    final state = votes[resourceId] ?? fallback;
    final scheme = Theme.of(context).colorScheme;
    final size = compact ? 18.0 : 22.0;

    Color colorFor(bool active) =>
        active ? scheme.primary : scheme.onSurfaceVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _VoteIcon(
          icon: Icons.keyboard_arrow_up_rounded,
          size: size,
          color: colorFor(state.isUp),
          onTap: () => _vote(context, ref, 'up', fallback),
        ),
        Text(
          '${state.count}',
          style: TextStyle(
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w600,
            color: state.isUp
                ? scheme.primary
                : state.isDown
                ? scheme.error
                : scheme.onSurface,
          ),
        ),
        _VoteIcon(
          icon: Icons.keyboard_arrow_down_rounded,
          size: size,
          color: state.isDown ? scheme.error : scheme.onSurfaceVariant,
          onTap: () => _vote(context, ref, 'down', fallback),
        ),
      ],
    );
  }

  Future<void> _vote(
    BuildContext context,
    WidgetRef ref,
    String direction,
    VoteState fallback,
  ) async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      context.push('/signin');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(voteControllerProvider.notifier)
          .vote(
            resourceId: resourceId,
            resourceType: resourceType,
            voteType: direction,
            fallback: fallback,
          );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            messageForError(error, fallback: 'Could not register your vote.'),
          ),
        ),
      );
    }
  }
}

class _VoteIcon extends StatelessWidget {
  const _VoteIcon({
    required this.icon,
    required this.size,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final double size;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: size,
      child: Icon(icon, size: size + 6, color: color),
    );
  }
}
