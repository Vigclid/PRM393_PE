import 'package:flutter/material.dart';
import '../models/user.dart';
import '../session/user_session.dart';
import '../theme/theme_notifier.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = UserSession.instance.currentUser;
    if (user == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: scheme.surfaceContainerHighest,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: scheme.outline,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: scheme.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            color: scheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _AvatarSection(user: user),
          const SizedBox(height: 24),
          _StatsRow(user: user),
          const SizedBox(height: 24),
          _DetailsCard(user: user),
          const SizedBox(height: 24),
          _SettingsCard(),
          const SizedBox(height: 24),
          _LogoutButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Avatar + email + role
// ---------------------------------------------------------------------------
class _AvatarSection extends StatelessWidget {
  final User user;
  const _AvatarSection({required this.user});

  String get _initials {
    final parts = user.email.split('@').first.split('.');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return user.email.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: scheme.primary,
          child: Text(
            _initials,
            style: TextStyle(
              color: scheme.onPrimary,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          user.email,
          style: TextStyle(
            color: scheme.primary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        _RoleBadge(role: user.roleName),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.primary.withValues(alpha: 0.5)),
      ),
      child: Text(
        role.isEmpty ? 'User' : role,
        style: TextStyle(
          color: scheme.primary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats — coins / following / followers
// ---------------------------------------------------------------------------
class _StatsRow extends StatelessWidget {
  final User user;
  const _StatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          _StatItem(value: user.coins, label: 'Coins'),
          _VerticalDivider(),
          _StatItem(value: '${user.followCounts}', label: 'Following'),
          _VerticalDivider(),
          _StatItem(value: '${user.followerCount}', label: 'Followers'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: scheme.primary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 36,
      color: Theme.of(context).colorScheme.outline,
    );
  }
}

// ---------------------------------------------------------------------------
// Details card
// ---------------------------------------------------------------------------
class _DetailsCard extends StatelessWidget {
  final User user;
  const _DetailsCard({required this.user});

  String _formatDate(String raw) {
    if (raw.isEmpty) return '—';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}  '
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.length > 24 ? raw.substring(0, 24) : raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final divider = Divider(height: 1, thickness: 1, color: scheme.outline);
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.circle,
            iconColor: user.isActive ? Colors.greenAccent : Colors.redAccent,
            label: 'Status',
            value: user.isActive ? 'Active' : 'Inactive',
            valueColor: user.isActive ? Colors.greenAccent : Colors.redAccent,
          ),
          divider,
          _DetailRow(
            icon: Icons.cake_outlined,
            label: 'Date of Birth',
            value: user.dateOfBirth.isEmpty ? '—' : user.dateOfBirth,
          ),
          divider,
          _DetailRow(
            icon: Icons.login_rounded,
            label: 'Last Login',
            value: _formatDate(user.lastLogin),
          ),
          divider,
          _DetailRow(
            icon: Icons.calendar_today_outlined,
            label: 'Member Since',
            value: _formatDate(user.createdAt),
          ),
          divider,
          _DetailRow(
            icon: Icons.fingerprint,
            label: 'User ID',
            value: '${user.id.substring(0, 8)}…',
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    this.iconColor,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: iconColor ?? scheme.onSurfaceVariant, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? scheme.primary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Settings card — dark / light mode toggle
// ---------------------------------------------------------------------------
class _SettingsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListenableBuilder(
      listenable: ThemeNotifier.instance,
      builder: (context, _) {
        final isDark = ThemeNotifier.instance.isDark;
        return Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outline),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(
                  isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  color: scheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  isDark ? 'Dark Mode' : 'Light Mode',
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: isDark,
                  onChanged: (_) => ThemeNotifier.instance.toggle(),
                  activeThumbColor: scheme.primary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Logout button
// ---------------------------------------------------------------------------
class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => _confirmLogout(context),
      icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
      label: const Text(
        'Log Out',
        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: const BorderSide(color: Colors.redAccent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Log Out',
          style: TextStyle(
            color: scheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to log out?',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await UserSession.instance.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const Text(
              'Log Out',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }
}
