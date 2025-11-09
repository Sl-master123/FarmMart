import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  // --- Launch helpers ---
  Future<void> _launchPhone(String number) async {
    final uri = Uri(scheme: 'tel', path: number.replaceAll(' ', ''));
    if (!await launchUrl(uri)) {
      throw 'Could not call $number';
    }
  }

  Future<void> _launchEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (!await launchUrl(uri)) {
      throw 'Could not email $email';
    }
  }

  Future<void> _launchMap() async {
    const q = 'Rajarata University of Sri Lanka, Mihintale';
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(q)}',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not open map';
    }
  }

  void _copyToClipboard(
    BuildContext context,
    String value,
    String label,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label copied'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const brandGreen = Color(0xFF2E7D32);
    const brandGreenLight = Color(0xFF66BB6A);
    const leaf1 = Color(0xFFE8F5E9);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Contact Support'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [brandGreen.withOpacity(0.85), Colors.black]
                : [brandGreenLight.withOpacity(0.85), leaf1],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Header Card
              _GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _CircleLeafIcon(
                          icon: Icons.agriculture_rounded,
                          bg: Colors.white.withOpacity(0.25),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'We’re here to help 🌿',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Reach us via phone or email, or find us at Rajarata University of Sri Lanka, Mihintale.',
                      style: TextStyle(color: Colors.white, height: 1.35),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Phones
              _SectionTitle(title: 'Phone Numbers'),
              _InfoCard(
                icon: Icons.phone_rounded,
                title: '077 189 907',
                subtitle: 'Tap to call • Long press to copy',
                onTap: () => _launchPhone('077 189 907'),
                onLongPress: (ctx) =>
                    _copyToClipboard(ctx, '077189907', 'Phone number'),
                trailing: _ActionIconButton(
                  tooltip: 'Call',
                  icon: Icons.call_rounded,
                  onPressed: () => _launchPhone('077189907'),
                ),
              ),
              _InfoCard(
                icon: Icons.phone_rounded,
                title: '076 000 439',
                subtitle: 'Tap to call • Long press to copy',
                onTap: () => _launchPhone('076 000 439'),
                onLongPress: (ctx) =>
                    _copyToClipboard(ctx, '076000439', 'Phone number'),
                trailing: _ActionIconButton(
                  tooltip: 'Call',
                  icon: Icons.call_rounded,
                  onPressed: () => _launchPhone('076000439'),
                ),
              ),

              const SizedBox(height: 12),

              // Emails
              _SectionTitle(title: 'Email Addresses'),
              _InfoCard(
                icon: Icons.email_rounded,
                title: 'vikumkalhara16@gmail.com',
                subtitle: 'Tap to email • Long press to copy',
                onTap: () => _launchEmail('vikumkalhara16@gmail.com'),
                onLongPress: (ctx) =>
                    _copyToClipboard(ctx, 'vikumkalhara16@gmail.com', 'Email'),
                trailing: _ActionIconButton(
                  tooltip: 'Email',
                  icon: Icons.send_rounded,
                  onPressed: () => _launchEmail('vikumkalhara16@gmail.com'),
                ),
              ),
              _InfoCard(
                icon: Icons.email_rounded,
                title: 'mnawarathne60@gmail.com',
                subtitle: 'Tap to email • Long press to copy',
                onTap: () => _launchEmail('mnawarathne60@gmail.com'),
                onLongPress: (ctx) =>
                    _copyToClipboard(ctx, 'mnawarathne60@gmail.com', 'Email'),
                trailing: _ActionIconButton(
                  tooltip: 'Email',
                  icon: Icons.send_rounded,
                  onPressed: () => _launchEmail('mnawarathne60@gmail.com'),
                ),
              ),

              const SizedBox(height: 12),

              // Location
              _SectionTitle(title: 'Location'),
              _InfoCard(
                icon: Icons.location_on_rounded,
                title: 'Rajarata University of Sri Lanka, Mihintale',
                subtitle: 'Tap to open in Google Maps',
                onTap: _launchMap,
                trailing: _ActionIconButton(
                  tooltip: 'Open Map',
                  icon: Icons.map_rounded,
                  onPressed: _launchMap,
                ),
              ),

              const SizedBox(height: 20),

              // Footer
              Center(
                child: Opacity(
                  opacity: 0.85,
                  child: Text(
                    'FarmMart • Growing together',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white70 : Colors.green.shade900,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== UI building blocks =====

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4, top: 6),
      child: Row(
        children: [
          Icon(
            Icons.eco_rounded,
            size: 18,
            color: isDark ? Colors.greenAccent : Colors.green,
          ),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.green.shade900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final void Function(BuildContext ctx)? onLongPress;
  final Widget? trailing;

  const _InfoCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.onLongPress,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: 0,
      color: Theme.of(context).cardColor.withOpacity(0.95),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        onLongPress: () => onLongPress?.call(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.green.shade700),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
        ),
      ),
    );

    return Padding(padding: const EdgeInsets.only(bottom: 10), child: card);
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class _CircleLeafIcon extends StatelessWidget {
  final IconData icon;
  final Color bg;
  const _CircleLeafIcon({required this.icon, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            spreadRadius: 0,
            offset: Offset(0, 3),
            color: Colors.black12,
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Icon(icon, color: Colors.white, size: 26),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  const _ActionIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      style: ButtonStyle(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
