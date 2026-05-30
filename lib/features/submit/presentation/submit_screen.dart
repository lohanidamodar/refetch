import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/submit_repository.dart';

/// Submit a new post — either a link or a "show" (text) post.
class SubmitScreen extends ConsumerStatefulWidget {
  const SubmitScreen({super.key});

  @override
  ConsumerState<SubmitScreen> createState() => _SubmitScreenState();
}

class _SubmitScreenState extends ConsumerState<SubmitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _url = TextEditingController();
  final _description = TextEditingController();

  String _type = 'link';
  bool _submitting = false;

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref
          .read(submitRepositoryProvider)
          .submit(
            title: _title.text.trim(),
            type: _type,
            url: _type == 'link' ? _url.text.trim() : null,
            description: _description.text.trim(),
          );
      messenger.showSnackBar(
        const SnackBar(content: Text('Submitted! It will appear once processed.')),
      );
      if (mounted) router.pop();
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Submit')),
      body: user == null
          ? _SignInRequired(onSignIn: () => context.push('/signin'))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'link', label: Text('Link')),
                            ButtonSegment(value: 'show', label: Text('Show')),
                          ],
                          selected: {_type},
                          onSelectionChanged: (s) =>
                              setState(() => _type = s.first),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _title,
                          decoration: const InputDecoration(labelText: 'Title'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Enter a title'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        if (_type == 'link')
                          TextFormField(
                            controller: _url,
                            keyboardType: TextInputType.url,
                            decoration: const InputDecoration(labelText: 'URL'),
                            validator: (v) {
                              if (_type != 'link') return null;
                              final value = v?.trim() ?? '';
                              final uri = Uri.tryParse(value);
                              if (value.isEmpty || uri == null || !uri.isAbsolute) {
                                return 'Enter a valid URL';
                              }
                              return null;
                            },
                          ),
                        if (_type == 'show')
                          TextFormField(
                            controller: _description,
                            minLines: 4,
                            maxLines: 8,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                            ),
                            validator: (v) {
                              if (_type != 'show') return null;
                              return (v == null || v.trim().isEmpty)
                                  ? 'Describe what you are showing'
                                  : null;
                            },
                          ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: _submitting ? null : _submit,
                          child: _submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Submit'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _SignInRequired extends StatelessWidget {
  const _SignInRequired({required this.onSignIn});

  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 48),
          const SizedBox(height: 12),
          const Text('Sign in to submit a post.'),
          const SizedBox(height: 12),
          FilledButton(onPressed: onSignIn, child: const Text('Sign in')),
        ],
      ),
    );
  }
}
