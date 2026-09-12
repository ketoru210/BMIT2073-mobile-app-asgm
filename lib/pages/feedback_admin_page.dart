import 'package:flutter/material.dart';

import '../data/feedback_repository.dart';
import '../ui/palette.dart';
import '../widgets/app_card.dart';
import '../widgets/back_chevron.dart';
import 'feedback_detail_page.dart';

class FeedbackAdminPage extends StatefulWidget {
  const FeedbackAdminPage({super.key});

  @override
  State<FeedbackAdminPage> createState() => _FeedbackAdminPageState();
}

class _FeedbackAdminPageState extends State<FeedbackAdminPage> {
  final _repository = FeedbackRepository();
  List<Map<String, dynamic>> _feedback = [];
  bool _loading = true;
  String? _error;
  String _statusFilter = 'all';
  String _categoryFilter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final feedback = await _repository.getAll();
      if (!mounted) return;
      setState(() {
        _feedback = feedback;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Unable to load feedback reports.';
      });
    }
  }

  List<Map<String, dynamic>> get _filteredFeedback {
    return _feedback.where((item) {
      final status = item['status'] as String? ?? 'open';
      final category = item['category'] as String? ?? 'feedback';
      return (_statusFilter == 'all' || status == _statusFilter) &&
          (_categoryFilter == 'all' || category == _categoryFilter);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.ground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
            children: [
              Row(
                children: [
                  BackChevron(onTap: () => Navigator.of(context).maybePop()),
                  const SizedBox(width: 6),
                  const Text(
                    'FEEDBACK REPORTS',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Palette.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const Text(
                'Review feedback and reported issues from users.',
                style: TextStyle(fontSize: 12, color: Palette.muted),
              ),
              const SizedBox(height: 16),
              if (!_loading && _error == null && _feedback.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _statusFilter,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(value: 'open', child: Text('Open')),
                          DropdownMenuItem(
                            value: 'in_progress',
                            child: Text('In progress'),
                          ),
                          DropdownMenuItem(
                            value: 'resolved',
                            child: Text('Resolved'),
                          ),
                          DropdownMenuItem(
                            value: 'closed',
                            child: Text('Closed'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _statusFilter = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _categoryFilter,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All')),
                          DropdownMenuItem(
                            value: 'feedback',
                            child: Text('Feedback'),
                          ),
                          DropdownMenuItem(value: 'bug', child: Text('Bug')),
                          DropdownMenuItem(
                            value: 'report',
                            child: Text('Report'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _categoryFilter = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(color: Palette.primary),
                  ),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Palette.riskText),
                  ),
                )
              else if (_feedback.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No feedback reports yet.',
                      style: TextStyle(color: Palette.muted),
                    ),
                  ),
                )
              else if (_filteredFeedback.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No reports match these filters.',
                      style: TextStyle(color: Palette.muted),
                    ),
                  ),
                )
              else
                for (final item in _filteredFeedback) ...[
                  _FeedbackCard(
                    item: item,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => FeedbackDetailPage(item: item),
                        ),
                      );
                      if (mounted) await _load();
                    },
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.item, required this.onTap});

  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final category = item['category'] as String? ?? 'feedback';
    final email = item['submitter_email'] as String? ?? 'Email unavailable';
    final subject = item['subject'] as String? ?? '';
    final status = item['status'] as String? ?? 'open';
    final createdAt = item['created_at'] as String?;

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subject,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Palette.ink,
                  ),
                ),
              ),
              Text(
                category.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Palette.periText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.email_outlined,
                size: 15,
                color: Palette.muted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  email,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Palette.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  _statusLabel(status),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Palette.periText,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right, color: Palette.muted),
            ],
          ),
          if (createdAt != null) ...[
            const SizedBox(height: 10),
            Text(
              _formatDate(createdAt),
              style: const TextStyle(fontSize: 11, color: Palette.muted),
            ),
          ],
        ],
      ),
    );
  }

  static String _statusLabel(String status) {
    return switch (status) {
      'in_progress' => 'IN PROGRESS',
      _ => status.toUpperCase(),
    };
  }

  static String _formatDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return value;
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
