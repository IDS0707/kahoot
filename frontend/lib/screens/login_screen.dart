import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../config.dart';
import '../services/socket_service.dart';
import '../theme/app_theme.dart';
import 'waiting_room_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _joinAsHost = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _joinGame() {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final socket = SocketService.instance;
    socket.connect(AppConfig.serverUrl);

    socket.onError = (err) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = err;
        });
      }
    };

    socket.onJoined = (data) {
      if (!mounted) return;
      socket.onJoined = null;
      socket.onError = null;
      final initialPlayers = (data['players'] as List? ?? [])
          .map((p) => Map<String, dynamic>.from(p as Map))
          .toList();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WaitingRoomScreen(
            playerName: data['name'] as String,
            isHost: data['isHost'] as bool,
            initialPlayers: initialPlayers,
          ),
        ),
      );
    };

    socket.join(_nameController.text.trim(), asHost: _joinAsHost);
  }

  void _instagramLogin() async {
    final instagramController = TextEditingController();

    final handle = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A0A3C),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: const BorderSide(color: Color(0x30FFFFFF)),
          ),
          title: const Text('Instagram Login',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18)),
          content: TextField(
            controller: instagramController,
            decoration: const InputDecoration(
              labelText: 'Instagram handle',
              hintText: 'e.g. your_username',
              labelStyle: TextStyle(color: Colors.white54),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white30),
              ),
            ),
            style: const TextStyle(color: Colors.white),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  const Text('Cancel', style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                final value = instagramController.text.trim();
                Navigator.pop(ctx, value.isEmpty ? null : value);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF405DE6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    if (handle != null && handle.isNotEmpty) {
      setState(() {
        _nameController.text = handle;
        _joinAsHost = false;
      });
      _joinGame();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Stack(
          children: [
            // ── Decorative glowing orbs ──────────────────────────────────
            Positioned(
              top: -80,
              left: -60,
              child: _GlowOrb(color: AppTheme.accent, size: 260),
            ),
            Positioned(
              bottom: -100,
              right: -80,
              child: _GlowOrb(color: AppTheme.accentNeon, size: 220),
            ),
            Positioned(
              top: 200,
              right: -40,
              child: _GlowOrb(color: const Color(0xFF3B82F6), size: 160),
            ),

            // ── Main content ─────────────────────────────────────────────
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Logo badge
                          _buildLogoBadge(),
                          const SizedBox(height: 32),

                          // Title
                          _buildTitle(),
                          const SizedBox(height: 40),

                          // Card
                          _buildCard(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoBadge() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C3AED), Color(0xFF06FFA5)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withOpacity(0.6),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: const Icon(Icons.quiz_rounded, size: 44, color: Colors.white),
    )
        .animate()
        .scale(
          begin: const Offset(0, 0),
          duration: 700.ms,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: 400.ms);
  }

  Widget _buildTitle() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Colors.white, Color(0xFFA78BFA)],
          ).createShader(bounds),
          child: const Text(
            'Present Perfect\nQuiz!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.15,
              letterSpacing: -1,
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Real-time multiplayer · Learn English grammar',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0x99FFFFFF), fontSize: 14),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 600.ms)
        .slideY(begin: 0.2, delay: 300.ms, duration: 500.ms);
  }

  Widget _buildCard() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0x20FFFFFF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Enter Nickname',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),

          // Name field
          TextFormField(
            controller: _nameController,
            style: const TextStyle(
                color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'e.g. Alice123',
              prefixIcon: Icon(Icons.person_rounded,
                  color: Color(0xFFA78BFA), size: 22),
            ),
            validator: (v) {
              if (v == null || v.trim().isEmpty) {
                return 'Please enter a nickname';
              }
              if (v.trim().length < 2) {
                return 'At least 2 characters required';
              }
              return null;
            },
            onFieldSubmitted: (_) => _joinGame(),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Checkbox(
                value: _joinAsHost,
                onChanged: (value) {
                  setState(() {
                    _joinAsHost = value ?? false;
                  });
                },
                fillColor: MaterialStateProperty.all(
                  const Color(0xFF7C3AED),
                ),
              ),
              const Expanded(
                child: Text(
                  'Join as host',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ],
          ),

          // Error
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Join Game button
          _JoinButton(
            isLoading: _isLoading,
            onPressed: _joinGame,
          ),
          const SizedBox(height: 16),
          _InstagramLoginButton(onPressed: _instagramLogin),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms, duration: 600.ms).slideY(
        begin: 0.3, delay: 500.ms, duration: 500.ms, curve: Curves.easeOut);
  }
}

// ── Join button with gradient ────────────────────────────────────────────────

class _JoinButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _JoinButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 58,
        decoration: BoxDecoration(
          gradient: isLoading
              ? const LinearGradient(
                  colors: [Color(0x887C3AED), Color(0x8806FFA5)])
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7C3AED), Color(0xFF06FFA5)],
                ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.accent.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.rocket_launch_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Join Game',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _InstagramLoginButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _InstagramLoginButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF58529), Color(0xFFDD2A7B)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
              SizedBox(width: 10),
              Text(
                'Login with Instagram',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Glow orb decorator ────────────────────────────────────────────────────────

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.08),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.15), blurRadius: 80, spreadRadius: 20),
        ],
      ),
    );
  }
}
