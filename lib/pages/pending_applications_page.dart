import 'package:flutter/material.dart';

import '../data/grant_admin_repository.dart';
import '../models/grant.dart';
import '../models/sector.dart';
import '../ui/palette.dart';
import '../widgets/app_card.dart';
import '../widgets/back_chevron.dart';

class PendingApplicationsPage extends StatefulWidget {
  const PendingApplicationsPage({super.key});

  @override
  State<PendingApplicationsPage> createState() =>
      _PendingApplicationsPageState();
}

class _PendingApplicationsPageState
    extends State<PendingApplicationsPage> {
  final _admin = SupabaseGrantAdminRepository();

  List<GrantApplication> _applications = [];
  bool _loading = true;
  String? _error;

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
      final applications = await _admin.pending();

      if (!mounted) return;

      setState(() {
        _applications = applications;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Unable to load pending applications.';
        _loading = false;
      });
    }
  }

  Future<void> _decide(
      GrantApplication application,
      ApplicationStatus status,
      ) async {
    try {
      await _admin.decide(
        application.id,
        status,
      );

      await _load();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == ApplicationStatus.approved
                ? 'Application approved.'
                : 'Application rejected.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update application.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.ground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
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
                    'PENDING APPLICATIONS',
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
                'Applications awaiting your review',
                style: TextStyle(
                  fontSize: 12,
                  color: Palette.muted,
                ),
              ),
              const SizedBox(height: 16),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: CircularProgressIndicator(
                      color: Palette.primary,
                    ),
                  ),
                )
              else if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _error!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Palette.riskText,
                    ),
                  ),
                )
              else if (_applications.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Text(
                        'No pending applications.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Palette.muted,
                        ),
                      ),
                    ),
                  )
                else
                  for (final application in _applications) ...[
                    _ApplicationCard(
                      application: application,
                      onReject: () => _decide(
                        application,
                        ApplicationStatus.rejected,
                      ),
                      onApprove: () => _decide(
                        application,
                        ApplicationStatus.approved,
                      ),
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

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.onReject,
    required this.onApprove,
  });

  final GrantApplication application;
  final VoidCallback onReject;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 18,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            application.projectName,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Palette.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            application.grantId,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: Palette.periText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${application.state} · ${_sectorLabel(application.sector)}',
            style: const TextStyle(
              fontSize: 11,
              color: Palette.muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'RM ${application.requestedAmountRm.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Palette.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Submitted  ${_date(application.submittedAt)}',
            style: const TextStyle(
              fontSize: 9.5,
              color: Palette.faint,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DecisionButton(
                  label: 'Reject',
                  onTap: onReject,
                  destructive: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DecisionButton(
                  label: 'Approve',
                  onTap: onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _sectorLabel(Sector value) {
    return value.label;
  }

  String _date(DateTime value) {
    return '${value.day} ${_month(value.month)} ${value.year}';
  }

  String _month(int month) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return names[month - 1];
  }
}

class _DecisionButton extends StatelessWidget {
  const _DecisionButton({
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: destructive ? Palette.riskBg : Palette.chipGreenBg,
          borderRadius: BorderRadius.circular(19),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: destructive ? Palette.riskText : Palette.green,
          ),
        ),
      ),
    );
  }
}