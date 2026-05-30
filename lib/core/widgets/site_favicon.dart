import 'package:flutter/material.dart';

import '../config/app_config.dart';

/// Displays the favicon for a domain using Appwrite's avatars favicon endpoint,
/// falling back to a generic icon when it can't be loaded.
class SiteFavicon extends StatelessWidget {
  const SiteFavicon({super.key, required this.domain, this.size = 28});

  final String domain;
  final double size;

  String get _faviconUrl {
    final full = domain.startsWith('http') ? domain : 'https://$domain';
    final encoded = Uri.encodeQueryComponent(full);
    return '${AppConfig.appwriteEndpoint}/avatars/favicon'
        '?project=${AppConfig.appwriteProjectId}&url=$encoded';
  }

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.22;
    final fallback = _Fallback(size: size, radius: radius);

    if (domain.isEmpty) return fallback;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        _faviconUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => fallback,
        loadingBuilder: (context, child, progress) =>
            progress == null ? child : fallback,
      ),
    );
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.size, required this.radius});

  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        Icons.public,
        size: size * 0.6,
        color: scheme.onSurfaceVariant,
      ),
    );
  }
}
