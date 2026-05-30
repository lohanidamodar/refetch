import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/presentation/auth_controller.dart';
import '../data/feed_repository.dart';
import 'feed_list.dart';

/// Home screen: the four feed tabs (Top / New / Show / Mines) plus actions for
/// submitting and the account.
class FeedScreen extends ConsumerWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return DefaultTabController(
      length: FeedTab.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'refetch',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          actions: [
            IconButton(
              tooltip: 'Submit',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => context.push('/submit'),
            ),
            IconButton(
              tooltip: user == null ? 'Sign in' : 'Account',
              icon: Icon(user == null ? Icons.login : Icons.account_circle),
              onPressed: () => context.push(user == null ? '/signin' : '/profile'),
            ),
          ],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              for (final tab in FeedTab.values) Tab(text: tab.label),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final tab in FeedTab.values) FeedList(tab: tab),
          ],
        ),
      ),
    );
  }
}
