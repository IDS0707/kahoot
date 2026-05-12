import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/extensions/context_ext.dart';
import '../../../core/utils/haptics.dart';
import '../../../core/utils/nickname_validator.dart';
import '../../../shared/widgets/app_background.dart';
import '../../../shared/widgets/aurora_title.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/glow_button.dart';
import '../../../shared/widgets/premium_text_field.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_durations.dart';
import '../../../theme/app_gradients.dart';
import '../../../theme/app_shadows.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';
import '../../game/data/models/session.dart';
import '../../lobby/presentation/waiting_room_screen.dart';
import '../application/auth_controller.dart';
import 'widgets/animated_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  bool _joinAsHost = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _join() {
    if (!_formKey.currentState!.validate()) return;
    Haptics.medium();
    ref.read(authControllerProvider.notifier).join(
          nickname: _nameCtrl.text,
          asHost: _joinAsHost,
        );
  }

  void _onJoined(PlayerSession session) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: AppDurations.slow,
        pageBuilder: (_, __, ___) => WaitingRoomScreen(session: session),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(
              CurvedAnimation(parent: anim, curve: AppCurves.standard),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen to join lifecycle.
    ref.listen(authControllerProvider, (prev, next) {
      next.whenOrNull(
        data: (session) {
          if (session != null) _onJoined(session);
        },
        error: (err, _) => Haptics.error(),
      );
    });

    final asyncJoin = ref.watch(authControllerProvider);
    final isLoading = asyncJoin.isLoading;
    final error = asyncJoin.hasError ? asyncJoin.error.toString() : null;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: context.responsive(regular: 28, compact: 20),
                vertical: AppSpacing.xxxl,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _Hero(),
                      const Gap(AppSpacing.xxl),
                      _AuthCard(
                        nameCtrl: _nameCtrl,
                        joinAsHost: _joinAsHost,
                        onHostChanged: (v) => setState(() => _joinAsHost = v),
                        onSubmit: _join,
                        isLoading: isLoading,
                        errorMessage: error,
                      ),
                      const Gap(AppSpacing.lg),
                      _Footer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Hero (logo + title) ──────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AnimatedLogo()
            .animate()
            .scale(
              begin: const Offset(0, 0),
              duration: 700.ms,
              curve: AppCurves.spring,
            )
            .fadeIn(duration: 400.ms),
        const Gap(AppSpacing.xl),
        const AuroraTitle('Present Perfect')
            .animate()
            .fadeIn(delay: 200.ms, duration: 500.ms)
            .slideY(begin: 0.25, duration: 500.ms, curve: AppCurves.standard),
        const Gap(AppSpacing.xs),
        Text(
          'Realtime multiplayer · Learn English grammar',
          textAlign: TextAlign.center,
          style: AppTypography.body(color: AppColors.textTertiary),
        ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
      ],
    );
  }
}

// ── Auth card ────────────────────────────────────────────────────────────────

class _AuthCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final bool joinAsHost;
  final ValueChanged<bool> onHostChanged;
  final VoidCallback onSubmit;
  final bool isLoading;
  final String? errorMessage;

  const _AuthCard({
    required this.nameCtrl,
    required this.joinAsHost,
    required this.onHostChanged,
    required this.onSubmit,
    required this.isLoading,
    required this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      strong: true,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('NICKNAME', style: AppTypography.label()),
          const Gap(AppSpacing.sm),
          PremiumTextField(
            controller: nameCtrl,
            hint: 'e.g. Alice123',
            prefixIcon: Icons.person_rounded,
            textCapitalization: TextCapitalization.words,
            validator: NicknameValidator.validate,
            onSubmitted: (_) => onSubmit(),
          ),
          const Gap(AppSpacing.md),
          _HostToggle(value: joinAsHost, onChanged: onHostChanged),
          if (errorMessage != null) ...[
            const Gap(AppSpacing.md),
            _ErrorBanner(message: errorMessage!),
          ],
          const Gap(AppSpacing.xl),
          GlowButton(
            label: isLoading ? 'Joining…' : 'Enter Game',
            icon: isLoading ? null : Icons.rocket_launch_rounded,
            onPressed: isLoading ? null : onSubmit,
            isLoading: isLoading,
          ),
          const Gap(AppSpacing.md),
          _SocialButton(
            label: 'Continue with Instagram',
            icon: Icons.camera_alt_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFF58529), Color(0xFFDD2A7B)],
            ),
            onPressed: () => _showInstagramDialog(context, nameCtrl, onSubmit),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 500.ms, duration: 500.ms)
        .slideY(begin: 0.25, delay: 500.ms, duration: 500.ms);
  }

  Future<void> _showInstagramDialog(
    BuildContext context,
    TextEditingController nameCtrl,
    VoidCallback onSubmit,
  ) async {
    final ctrl = TextEditingController();
    final handle = await showGeneralDialog<String?>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Instagram',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: AppDurations.medium,
      pageBuilder: (_, __, ___) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: GlassCard(
            strong: true,
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Instagram Login', style: AppTypography.h2()),
                const Gap(AppSpacing.sm),
                Text(
                  'We use your handle as your in-game name.',
                  style: AppTypography.body(),
                ),
                const Gap(AppSpacing.lg),
                PremiumTextField(
                  controller: ctrl,
                  hint: 'your_username',
                  prefixIcon: Icons.alternate_email_rounded,
                ),
                const Gap(AppSpacing.lg),
                GlowButton(
                  label: 'Continue',
                  variant: GlowButtonVariant.custom,
                  customGradient: const LinearGradient(
                    colors: [Color(0xFFF58529), Color(0xFFDD2A7B)],
                  ),
                  customGlow: const Color(0xFFDD2A7B),
                  onPressed: () => Navigator.of(context).pop(ctrl.text.trim()),
                ),
              ],
            ),
          ),
        ),
      ),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(
            CurvedAnimation(parent: anim, curve: AppCurves.spring),
          ),
          child: child,
        ),
      ),
    );

    if (handle != null && handle.isNotEmpty) {
      nameCtrl.text = handle;
      onSubmit();
    }
  }
}

// ── Host toggle (custom switch — way nicer than default Checkbox) ────────────

class _HostToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _HostToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.selection();
        onChanged(!value);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        decoration: BoxDecoration(
          color: value
              ? AppColors.gold.withValues(alpha: 0.14)
              : AppColors.glassFill,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: value
                ? AppColors.gold.withValues(alpha: 0.55)
                : AppColors.glassBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.admin_panel_settings_rounded,
              color: value ? AppColors.gold : AppColors.textTertiary,
              size: 20,
            ),
            const Gap(AppSpacing.sm),
            Expanded(
              child: Text(
                'Join as host',
                style: AppTypography.body(
                  color: value ? Colors.white : AppColors.textSecondary,
                  weight: FontWeight.w600,
                ),
              ),
            ),
            _Switch(value: value),
          ],
        ),
      ),
    );
  }
}

class _Switch extends StatelessWidget {
  final bool value;
  const _Switch({required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.fast,
      width: 38,
      height: 22,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        gradient: value ? AppGradients.gold : null,
        color: value ? null : Colors.white12,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: AnimatedAlign(
        duration: AppDurations.fast,
        curve: AppCurves.standard,
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: value
                ? [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.55),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }
}

// ── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.danger, size: 18),
          const Gap(AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption(color: AppColors.danger),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).shake(hz: 5, duration: 350.ms);
  }
}

// ── Social button (smaller variant for secondary auth options) ──────────────

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Gradient gradient;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Haptics.light();
        onPressed();
      },
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const Gap(AppSpacing.sm),
              Text(label, style: AppTypography.button()),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Footer ───────────────────────────────────────────────────────────────────

class _Footer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Text(
      'v2.0 · Premium build',
      style: AppTypography.caption(color: AppColors.textTertiary),
    ).animate().fadeIn(delay: 800.ms);
  }
}
