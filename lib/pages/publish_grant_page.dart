import 'package:flutter/material.dart';

import '../data/gdp_repository.dart';
import '../data/grant_admin_repository.dart';
import '../models/grant.dart';
import '../models/sector.dart';
import '../ui/palette.dart';
import '../widgets/back_chevron.dart';
import '../widgets/dropdown_card.dart';
import '../widgets/section_label.dart';
import '../widgets/toggle_switch.dart';

class PublishGrantPage extends StatefulWidget {
  const PublishGrantPage({super.key});

  @override
  State<PublishGrantPage> createState() => _PublishGrantPageState();
}

class _PublishGrantPageState extends State<PublishGrantPage> {
  final _nameController = TextEditingController();
  final _agencyController = TextEditingController();
  final _amountController = TextEditingController();
  final _sourceController = TextEditingController();
  final _criteriaController = TextEditingController();
  final _descriptionController = TextEditingController();

  final _admin = SupabaseGrantAdminRepository();

  String? _state;
  Sector? _sector;
  DateTime? _deadline;
  bool _isOpen = true;
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _agencyController.dispose();
    _amountController.dispose();
    _sourceController.dispose();
    _criteriaController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final name = _nameController.text.trim();
    final agency = _agencyController.text.trim();
    final sourceUrl = _sourceController.text.trim();
    final criteria = _criteriaController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty ||
        agency.isEmpty ||
        _deadline == null ||
        sourceUrl.isEmpty ||
        criteria.isEmpty ||
        description.isEmpty) {
      _showError('Please complete all required fields.');
      return;
    }

    final amountText = _amountController.text.trim();
    final amount = amountText.isEmpty ? null : int.tryParse(amountText);

    if (amountText.isNotEmpty && amount == null) {
      _showError('Maximum amount must be a valid number.');
      return;
    }

    setState(() => _loading = true);

    try {
      final grant = Grant(
        id: 'grant-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        agency: agency,
        state: _state,
        sector: _sector,
        maxAmountRm: amount,
        deadline: _deadline!,
        sourceUrl: sourceUrl,
        criteriaNote: criteria,
        description: description,
        publishedBy: '',
        publishedAt: DateTime.now(),
        isOpen: _isOpen,
      );

      await _admin.publish(grant);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grant published successfully.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        _showError('Unable to publish grant. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.ground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          children: [
            Row(
              children: [
                BackChevron(
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const SizedBox(width: 6),
                const Text(
                  'PUBLISH GRANT',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Palette.ink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            const SectionLabel(text: 'GRANT INFORMATION'),
            const SizedBox(height: 16),
            _field(
              label: 'Name',
              controller: _nameController,
              hint: 'Grant name',
            ),
            _field(
              label: 'Agency',
              controller: _agencyController,
              hint: 'Agency name',
            ),
            _dropdown(
              label: 'State',
              child: DropdownCard<String?>(
                value: _state,
                options: [
                  null,
                  ...GdpRepository.canonicalStates,
                ],
                labelBuilder: (state) => state ?? 'Nationwide',
                onChanged: (value) {
                  setState(() => _state = value);
                },
              ),
            ),
            _dropdown(
              label: 'Sector',
              child: DropdownCard<Sector?>(
                value: _sector,
                options: [
                  null,
                  ...Sector.values,
                ],
                labelBuilder: (sector) => sector?.label ?? 'Any sector',
                onChanged: (value) {
                  setState(() => _sector = value);
                },
              ),
            ),
            _field(
              label: 'Maximum amount (RM)',
              controller: _amountController,
              hint: 'Optional',
              keyboardType: TextInputType.number,
            ),
            _dateField(),
            _field(
              label: 'Source URL',
              controller: _sourceController,
              hint: 'https://...',
              keyboardType: TextInputType.url,
            ),
            _field(
              label: 'Criteria',
              controller: _criteriaController,
              hint: 'Eligibility conditions...',
              maxLines: 3,
            ),
            _field(
              label: 'Description',
              controller: _descriptionController,
              hint: 'Grant description...',
              maxLines: 4,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Open for applications',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Palette.ink,
                    ),
                  ),
                ),
                ToggleSwitch(
                  value: _isOpen,
                  onChanged: (value) {
                    setState(() => _isOpen = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: _loading ? null : _publish,
              child: Container(
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: Palette.gradHero,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [Palette.heroShadow],
                ),
                child: Text(
                  _loading ? 'Publishing...' : 'Publish',
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Palette.muted,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontSize: 13,
                color: Palette.faint,
              ),
              filled: true,
              fillColor: Palette.card,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Palette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Palette.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Palette.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String label,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Palette.muted,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _dateField() {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deadline',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Palette.muted,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
                initialDate: _deadline ?? DateTime.now(),
              );

              if (picked != null) {
                setState(() => _deadline = picked);
              }
            },
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Palette.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Palette.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _deadline == null
                          ? 'Select date'
                          : '${_deadline!.day.toString().padLeft(2, '0')}/'
                          '${_deadline!.month.toString().padLeft(2, '0')}/'
                          '${_deadline!.year}',
                      style: TextStyle(
                        fontSize: 13,
                        color: _deadline == null
                            ? Palette.faint
                            : Palette.ink,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Palette.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}