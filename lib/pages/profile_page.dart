import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/supabase_user_repository.dart';
import '../models/saved_analysis.dart';
import '../models/grant.dart';
import '../pages/register_page.dart';
import '../state/app_state.dart';
import '../ui/palette.dart';
import '../widgets/app_card.dart';
import '../widgets/back_chevron.dart';
import '../widgets/section_label.dart';
import 'login_page.dart';
import 'pending_applications_page.dart';
import 'publish_grant_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, app, child) {
        final users = app.users as SupabaseUserRepository;
        final signedIn = users.isSignedIn;

        return Scaffold(
          backgroundColor: Palette.ground,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                Row(
                  children: [
                    BackChevron(
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'PROFILE',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Palette.ink,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                const Center(
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Palette.chipPeri,
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: Palette.periText,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    signedIn
                        ? (users.nickname?.isNotEmpty == true
                        ? users.nickname!
                        : 'User')
                        : 'Guest',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Palette.ink,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Center(
                  child: Text(
                    signedIn
                        ? _roleLabel(users.role)
                        : 'Not signed in',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Palette.muted,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                if (!signedIn) ...[
                  const SectionLabel(text: 'ACCOUNT'),
                  const SizedBox(height: 10),
                  _ProfileRow(
                    icon: Icons.login_rounded,
                    label: 'Log in',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginPage(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _ProfileRow(
                    icon: Icons.person_add_outlined,
                    label: 'Create an account',
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const RegisterPage(),
                      ),
                    ),
                  ),
                ] else ...[
                  const SectionLabel(text: 'ACCOUNT'),
                  const SizedBox(height: 10),
                  _ProfileRow(
                    icon: Icons.edit_outlined,
                    label: 'Nickname',
                    value: users.nickname ?? '',
                    onTap: () => _editNickname(context, app, users),
                  ),
                  const SizedBox(height: 22),
                  const SectionLabel(text: 'ACTIVITY'),
                  const SizedBox(height: 10),
                  _ProfileRow(
                    icon: Icons.bookmark_outline_rounded,
                    label: 'Saved Analyses',
                    value: '${app.favorites.length}',
                    onTap: () => _showFavorites(context, app.favorites),
                  ),
                  if (users.role == UserRole.admin) ...[
                    const SizedBox(height: 22),
                    const SectionLabel(text: 'ADMINISTRATION'),
                    const SizedBox(height: 10),
                    _ProfileRow(
                      icon: Icons.add_business_outlined,
                      label: 'Publish Grant',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PublishGrantPage(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _ProfileRow(
                      icon: Icons.fact_check_outlined,
                      label: 'Pending Applications',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PendingApplicationsPage(),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  GestureDetector(
                    onTap: () => _logout(context, app, users),
                    child: Container(
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Palette.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Palette.border),
                      ),
                      child: const Text(
                        'Log out',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Palette.riskText,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _roleLabel(UserRole role) {
    return role == UserRole.admin ? 'Administrator' : 'User';
  }

  Future<void> _editNickname(
      BuildContext context,
      AppState app,
      SupabaseUserRepository users,
      ) async {
    final controller = TextEditingController(text: users.nickname ?? '');

    final value = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nickname'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter your nickname',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              controller.text.trim(),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (value == null || value.isEmpty) return;

    try {
      await users.setNickname(value);
      app.notifyListeners();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update nickname.'),
        ),
      );
    }
  }

  Future<void> _logout(
      BuildContext context,
      AppState app,
      SupabaseUserRepository users,
      ) async {
    await users.signOut();
    await app.init();

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You have been logged out.')),
    );
  }

  void _showFavorites(
      BuildContext context,
      List<SavedAnalysis> favorites,
      ) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: const BoxConstraints(maxHeight: 500),
        decoration: const BoxDecoration(
          color: Palette.card,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(22),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
        child: favorites.isEmpty
            ? const Center(
          child: Padding(
            padding: EdgeInsets.all(30),
            child: Text(
              'No saved analyses yet.',
              style: TextStyle(
                fontSize: 12,
                color: Palette.muted,
              ),
            ),
          ),
        )
            : ListView(
          children: [
            const Text(
              'Saved Analyses',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Palette.ink,
              ),
            ),
            const SizedBox(height: 12),
            for (final favorite in favorites)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.analytics_outlined,
                  color: Palette.primary,
                ),
                title: Text(
                  favorite.label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Palette.ink,
                  ),
                ),
                subtitle: Text(
                  favorite.savedAt.toLocal().toString().split('.').first,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Palette.muted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      radius: 14,
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            const SizedBox(width: 15),
            Icon(
              icon,
              size: 20,
              color: Palette.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Palette.ink,
                ),
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: const TextStyle(
                  fontSize: 11,
                  color: Palette.muted,
                ),
              ),
            const SizedBox(width: 5),
            const Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: Palette.faint,
            ),
            const SizedBox(width: 10),
          ],
        ),
      ),
    );
  }
}