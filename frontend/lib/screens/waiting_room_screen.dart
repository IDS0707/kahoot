import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/socket_service.dart';
import '../theme/app_theme.dart';
import 'quiz_screen.dart';
import 'admin_panel_screen.dart';

class WaitingRoomScreen extends StatefulWidget {
  final String playerName;
  final bool isHost;
  final List<Map<String, dynamic>> initialPlayers;

  const WaitingRoomScreen({
    super.key,
    required this.playerName,
    required this.isHost,
    this.initialPlayers = const [],
  });

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  List<Map<String, dynamic>> _players = [];
  bool _isStarting = false;
  late bool _isHost;

  @override
  void initState() {
    super.initState();
    _isHost = widget.isHost;
    _players = List<Map<String, dynamic>>.from(widget.initialPlayers);
    _registerListeners();
  }

  void _registerListeners() {
    final socket = SocketService.instance;

    socket.onRoomUpdate = (data) {
      if (!mounted) return;
      setState(() {
        _players = List<Map<String, dynamic>>.from(
          (data['players'] as List)
              .map((p) => Map<String, dynamic>.from(p as Map)),
        );
      });
    };

    socket.onGameStarted = () {
      if (!mounted) return;
      if (_isHost) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AdminPanelScreen(playerName: widget.playerName),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                QuizScreen(playerName: widget.playerName, isHost: false),
          ),
        );
      }
    };
  }

  @override
  void dispose() {
    final socket = SocketService.instance;
    socket.onRoomUpdate = null;
    socket.onGameStarted = null;
    super.dispose();
  }

  void _startGame() {
    setState(() => _isStarting = true);
    SocketService.instance.startGame();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 380;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Stack(
          children: [
            Positioned(
                top: -60,
                right: -40,
                child: _GlowOrb(color: AppTheme.accent, size: 200)),
            Positioned(
                bottom: -80,
                left: -60,
                child: _GlowOrb(color: AppTheme.accentNeon, size: 180)),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  SizedBox(height: compact ? 10 : 16),
                  _buildStatsRow(),
                  SizedBox(height: compact ? 10 : 16),
                  Expanded(child: _buildPlayerGrid()),
                  _buildBottomArea(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 380;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          compact ? 14 : 24, compact ? 14 : 28, compact ? 14 : 24, 0),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
                horizontal: compact ? 12 : 18, vertical: compact ? 12 : 16),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0x26FFFFFF)),
            ),
            child: Row(
              children: [
                Container(
                  width: compact ? 40 : 46,
                  height: compact ? 40 : 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF3B82F6)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.groups_rounded,
                      color: Colors.white, size: compact ? 20 : 24),
                ),
                SizedBox(width: compact ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Colors.white, Color(0xFFA78BFA)],
                        ).createShader(b),
                        child: Text(
                          'Waiting Room',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: compact ? 22 : 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.6,
                          ),
                        ),
                      ),
                      Text(
                        'Welcome, ${widget.playerName}',
                        style: TextStyle(
                            color: Color(0xB3FFFFFF),
                            fontSize: compact ? 12 : 13,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                if (_isHost)
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: compact ? 9 : 11,
                        vertical: compact ? 5 : 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFFFFD700), Color(0xFFF59E0B)]),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.admin_panel_settings_rounded,
                            size: compact ? 12 : 13, color: Colors.black),
                        const SizedBox(width: 4),
                        Text('HOST',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: compact ? 9 : 10,
                                letterSpacing: 0.8)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2, duration: 500.ms);
  }

  Widget _buildStatsRow() {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 380;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 14, vertical: compact ? 10 : 12),
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x20FFFFFF)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.groups_2_rounded,
                      color: Colors.white, size: compact ? 16 : 18),
                  SizedBox(width: compact ? 6 : 8),
                  Text(
                    '${_players.length} player${_players.length != 1 ? 's' : ''}',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 12 : 14,
                        fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 14, vertical: compact ? 10 : 12),
              decoration: BoxDecoration(
                color: const Color(0x1406FFA5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x5506FFA5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.podcasts_rounded,
                      color: const Color(0xFF06FFA5), size: compact ? 16 : 18),
                  SizedBox(width: compact ? 6 : 8),
                  Text('Realtime',
                      style: TextStyle(
                          color: Color(0xFF06FFA5),
                          fontSize: compact ? 12 : 14,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildPlayerGrid() {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 380;
    final tablet = width >= 700;

    if (_players.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0x14FFFFFF),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0x20FFFFFF)),
              ),
              child: const Icon(Icons.hourglass_top_rounded,
                  color: Color(0x88FFFFFF), size: 36),
            ),
            const SizedBox(height: 20),
            const Text('Waiting for players...',
                style: TextStyle(
                    color: Color(0xAAFFFFFF),
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 20, vertical: 8),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: tablet ? 220 : (compact ? 150 : 180),
        mainAxisSpacing: compact ? 8 : 12,
        crossAxisSpacing: compact ? 8 : 12,
        childAspectRatio: compact ? 1.05 : 1.2,
      ),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _players.length,
      itemBuilder: (ctx, i) {
        final p = _players[i];
        final name = p['name'] as String;
        final isPlayerHost = p['isHost'] == true;
        final color = AppTheme.answerColors[i % 4];

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.25), color.withOpacity(0.08)],
            ),
            borderRadius: BorderRadius.circular(compact ? 16 : 22),
            border: Border.all(color: color.withOpacity(0.38)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(children: [
                CircleAvatar(
                  radius: compact ? 20 : 26,
                  backgroundColor: color.withOpacity(0.35),
                  child: Text(name[0].toUpperCase(),
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: compact ? 16 : 20)),
                ),
                if (isPlayerHost)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: compact ? 16 : 18,
                      height: compact ? 16 : 18,
                      decoration: const BoxDecoration(
                          color: Color(0xFFFFD700), shape: BoxShape.circle),
                      child: const Icon(Icons.star_rounded,
                          size: 10, color: Colors.black),
                    ),
                  ),
              ]),
              SizedBox(height: compact ? 6 : 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(name,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 12 : 13,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        )
            .animate()
            .scale(
              begin: const Offset(0.6, 0.6),
              delay: Duration(milliseconds: i * 60),
              duration: 400.ms,
              curve: Curves.elasticOut,
            )
            .fadeIn(delay: Duration(milliseconds: i * 60));
      },
    );
  }

  Widget _buildBottomArea() {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 380;

    if (_isHost) {
      return Padding(
        padding: EdgeInsets.fromLTRB(
            compact ? 14 : 24, 12, compact ? 14 : 24, compact ? 20 : 28),
        child: _GradientButton(
          label: _isStarting ? 'Starting...' : 'Start Game',
          icon: _isStarting ? null : Icons.play_arrow_rounded,
          isLoading: _isStarting,
          onPressed: (_players.isNotEmpty && !_isStarting) ? _startGame : null,
          gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF059669)]),
          glowColor: const Color(0xFF10B981),
        ),
      );
    }
    return Container(
      margin: EdgeInsets.fromLTRB(
          compact ? 14 : 24, 12, compact ? 14 : 24, compact ? 16 : 24),
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14, vertical: compact ? 10 : 12),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x20FFFFFF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
                color: Color(0xFFA78BFA), strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Text('Host game boshlashini kutyapmiz...',
              style: TextStyle(
                  color: Color(0xCCFFFFFF),
                  fontSize: compact ? 12 : 13,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Shared reusable widgets ────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isLoading;
  final VoidCallback? onPressed;
  final LinearGradient gradient;
  final Color glowColor;

  const _GradientButton({
    required this.label,
    this.icon,
    this.isLoading = false,
    this.onPressed,
    required this.gradient,
    required this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: disabled
              ? LinearGradient(colors: [
                  gradient.colors[0].withOpacity(0.4),
                  gradient.colors.last.withOpacity(0.4),
                ])
              : gradient,
          borderRadius: BorderRadius.circular(18),
          boxShadow: disabled
              ? []
              : [
                  BoxShadow(
                      color: glowColor.withOpacity(0.45),
                      blurRadius: 24,
                      offset: const Offset(0, 8)),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                    ],
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3)),
                  ],
                ),
        ),
      ),
    );
  }
}

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
        color: color.withOpacity(0.07),
        boxShadow: [
          BoxShadow(
              color: color.withOpacity(0.12), blurRadius: 80, spreadRadius: 20),
        ],
      ),
    );
  }
}
