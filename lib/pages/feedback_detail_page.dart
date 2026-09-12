import 'package:flutter/material.dart';

import '../data/feedback_repository.dart';
import '../ui/palette.dart';
import '../widgets/app_card.dart';
import '../widgets/back_chevron.dart';

class FeedbackDetailPage extends StatefulWidget {
  const FeedbackDetailPage({super.key, required this.item});

  final Map<String, dynamic> item;

  @override
  State<FeedbackDetailPage> createState() => _FeedbackDetailPageState();
}

class _FeedbackDetailPageState extends State<FeedbackDetailPage> {
  final _repository = FeedbackRepository();
  late String _status;
  late final TextEditingController _adminNoteController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _status = widget.item['status'] as String? ?? 'open';
    _adminNoteController = TextEditingController(
      text: widget.item['admin_note'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _adminNoteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      await _repository.updateStatus(
        id: widget.item['id'] as String,
        status: _status,
        adminNote: _adminNoteController.text.trim().isEmpty
            ? null
            : _adminNoteController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report updated.')),
      );
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update the report.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.item['category'] as String? ?? 'feedback';
    final subject = widget.item['subject'] as String? ?? '';
    final email = widget.item['submitter_email'] as String? ??
        'Email unavailable';
    final message = widget.item['message'] as String? ?? '';
    final createdAt = widget.item['created_at'] as String?;

    return Scaffold(
      backgroundColor: Palette.ground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          children: [
            Row(
              children: [
                BackChevron(onTap: () => Navigator.of(context).maybePop()),
                const SizedBox(width: 6),
                const Text(
                  'REPORT DETAIL',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Palette.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            AppCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subject,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Palette.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _DetailLine(
                    icon: Icons.category_outlined,
                    label: category.toUpperCase(),
                  ),
                  const SizedBox(height: 8),
                  _DetailLine(icon: Icons.email_outlined, label: email),
                  if (createdAt != null) ...[
                    const SizedBox(height: 8),
                    _DetailLine(
                      icon: Icons.schedule_outlined,
                      label: _formatDate(createdAt),
                    ),
                  ],
                  const Divider(height: 28),
                  const Text(
                    'MESSAGE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Palette.muted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Palette.body,
                    ),
                  ),
                  const SizedBox(height: 22),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
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
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _status = value);
                            }
                          },
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _adminNoteController,
                    enabled: !_saving,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Admin note',
                      hintText: 'Optional internal note',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: Palette.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save changes'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return value;
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Palette.muted),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Palette.muted),
          ),
        ),
      ],
    );
  }
}
