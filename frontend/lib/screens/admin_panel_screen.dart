import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/socket_service.dart';
import '../theme/app_theme.dart';
import 'leaderboard_screen.dart';
import 'login_screen.dart';

/// Host-only admin panel shown during the active game.
/// Displays: current question info, live player list with answer status,
/// live leaderboard, and controls (skip question / end game / reset).
class AdminPanelScreen extends StatefulWidget {
  final String playerName;

  const AdminPanelScreen({super.key, required this.playerName});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  // ── Game state ─────────────────────────────────────────────────────────────
  String _gamePhase = 'playing'; // 'playing' | 'result' | 'over'
  int _questionIndex = 0;
  int _totalQuestions = 0;
  String _currentQuestion = '';
  List<String> _options = [];
  int _timeLimit = 15;
  int _secondsLeft = 15;
  int _correctIndex = -1;
  String _explanation = '';
  Timer? _timer;

  // ── Players / leaderboard ─────────────────────────────────────────────────
  List<Map<String, dynamic>> _players = [];
  List<Map<String, dynamic>> _leaderboard = [];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _registerListeners();
  }

  void _registerListeners() {
    final s = SocketService.instance;
    s.onRoomUpdate = (data) {
      if (!mounted) return;
      setState(() {
        _players = List<Map<String, dynamic>>.from(
          (data['players'] as List)
              .map((p) => Map<String, dynamic>.from(p as Map)),
        );
      });
    };

    // New question
    s.onNewQuestion = (data) {
      if (!mounted) return;
      _timer?.cancel();
      setState(() {
        _gamePhase = 'playing';
        _questionIndex = data['index'] as int;
        _totalQuestions = data['total'] as int;
        _currentQuestion = data['question'] as String;
        _options = List<String>.from(data['options'] as List);
        _timeLimit = data['timeLimit'] as int;
        _secondsLeft = _timeLimit;
        _correctIndex = -1;
        _explanation = '';
      });
      _startTimer();
    };

    // Admin sees answer_result from own socket too (host might not answer, but
    // we track answeredCount via question_result leaderboard length change)
    s.onAnswerResult = (_) {}; // Host doesn't answer; ignore

    // Question result – show correct answer + leaderboard
    s.onQuestionResult = (data) {
      if (!mounted) return;
      _timer?.cancel();
      final lb = List<Map<String, dynamic>>.from(
        (data['leaderboard'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
      setState(() {
        _gamePhase = 'result';
        _correctIndex = data['correctIndex'] as int;
        _explanation = (data['explanation'] as String?) ?? '';
        _leaderboard = lb;
      });
    };

    // Game over
    s.onGameOver = (data) {
      if (!mounted) return;
      _timer?.cancel();
      final lb = List<Map<String, dynamic>>.from(
        (data['leaderboard'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
      setState(() {
        _gamePhase = 'over';
        _leaderboard = lb;
      });
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LeaderboardScreen(
            leaderboard: lb,
            playerName: widget.playerName,
            totalScore: 0,
            isAdmin: true,
          ),
        ),
      );
    };

    // Game reset
    s.onGameReset = () {
      if (!mounted) return;
      _timer?.cancel();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    };
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabs.dispose();
    final s = SocketService.instance;
    s.onNewQuestion = null;
    s.onAnswerResult = null;
    s.onQuestionResult = null;
    s.onGameOver = null;
    s.onGameReset = null;
    s.onRoomUpdate = null;
    super.dispose();
  }

  // ── Control actions ────────────────────────────────────────────────────────

  void _skipQuestion() {
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Skip Question?',
        message: 'Move to the next question immediately.',
        confirmLabel: 'Skip',
        confirmColor: AppTheme.answerYellow,
        onConfirm: () => SocketService.instance.skipQuestion(),
      ),
    );
  }

  void _endGame() {
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'End Game Early?',
        message: 'This will end the game and show the final leaderboard.',
        confirmLabel: 'End Game',
        confirmColor: AppTheme.answerRed,
        onConfirm: () => SocketService.instance.endGame(),
      ),
    );
  }

  void _resetGame() {
    showDialog(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Reset Game?',
        message: 'All scores will be cleared and players returned to lobby.',
        confirmLabel: 'Reset',
        confirmColor: Colors.orange,
        onConfirm: () => SocketService.instance.resetGame(),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

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
                top: -80,
                right: -60,
                child: _GlowOrb(color: AppTheme.accent, size: 240)),
            Positioned(
                bottom: -90,
                left: -70,
                child: _GlowOrb(color: AppTheme.accentNeon, size: 210)),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(compact),
                  if (_currentQuestion.isNotEmpty) _buildQuestionCard(),
                  _buildTabBar(compact),
                  Expanded(
                    child: TabBarView(
                      controller: _tabs,
                      children: [
                        _buildControlsTab(),
                        _buildLeaderboardTab(),
                      ],
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

  Widget _buildTopBar(bool compact) {
    final timerColor = _secondsLeft > 5
        ? AppTheme.accentNeon
        : _secondsLeft > 2
            ? Colors.orange
            : AppTheme.answerRed;

    return Container(
      margin: EdgeInsets.fromLTRB(compact ? 10 : 16, compact ? 10 : 14,
          compact ? 10 : 16, compact ? 8 : 10),
      padding: EdgeInsets.fromLTRB(compact ? 10 : 14, compact ? 10 : 12,
          compact ? 10 : 14, compact ? 10 : 12),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x24FFFFFF)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 36 : 42,
            height: compact ? 36 : 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFF59E0B)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.admin_panel_settings_rounded,
                size: compact ? 18 : 22, color: Colors.black),
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _totalQuestions > 0
                      ? 'Question ${_questionIndex + 1} / $_totalQuestions'
                      : 'Admin Dashboard',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 13 : 15),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_players.length} player online',
                  style: TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontWeight: FontWeight.w500,
                      fontSize: compact ? 11 : 12),
                ),
                if (_totalQuestions > 0) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (_questionIndex + 1) / _totalQuestions,
                      backgroundColor: Colors.white24,
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFFA78BFA)),
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(width: compact ? 8 : 10),
          if (_gamePhase == 'playing' && _totalQuestions > 0)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: compact ? 44 : 50,
              height: compact ? 44 : 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: timerColor.withOpacity(0.15),
                border: Border.all(color: timerColor, width: 3),
              ),
              child: Center(
                child: Text(
                  '$_secondsLeft',
                  style: TextStyle(
                      color: timerColor,
                      fontSize: compact ? 15 : 18,
                      fontWeight: FontWeight.w900),
                ),
              ),
            ),
          if (_gamePhase == 'result')
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: compact ? 8 : 10, vertical: compact ? 6 : 7),
              decoration: BoxDecoration(
                color: const Color(0x2206FFA5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentNeon.withOpacity(0.5)),
              ),
              child: Text('RESULT',
                  style: TextStyle(
                      color: AppTheme.accentNeon,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 11 : 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 380;

    return Container(
      margin: EdgeInsets.fromLTRB(compact ? 10 : 16, 0, compact ? 10 : 16, 12),
      padding: EdgeInsets.all(compact ? 12 : 18),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x22FFFFFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _currentQuestion,
            style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 15 : 17,
                fontWeight: FontWeight.w700,
                height: 1.4),
          ),
          if (_options.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_options.length, (i) {
                final isCorrect = _correctIndex >= 0 && i == _correctIndex;
                final color = AppTheme.answerColors[i];
                return Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: compact ? 9 : 12, vertical: compact ? 6 : 8),
                  decoration: BoxDecoration(
                    color: isCorrect
                        ? color.withOpacity(0.35)
                        : color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: isCorrect ? color : color.withOpacity(0.3),
                        width: isCorrect ? 2 : 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AppTheme.answerIcons[i],
                          color: color, size: compact ? 12 : 14),
                      SizedBox(width: compact ? 4 : 6),
                      Text(
                        _options[i],
                        style: TextStyle(
                          color: isCorrect ? Colors.white : Colors.white70,
                          fontSize: compact ? 12 : 13,
                          fontWeight:
                              isCorrect ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      if (isCorrect) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 14),
                      ],
                    ],
                  ),
                );
              }),
            ),
            if (_explanation.isNotEmpty && _gamePhase == 'result') ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentNeon.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AppTheme.accentNeon.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lightbulb_rounded,
                        color: AppTheme.accentNeon, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _explanation,
                        style: const TextStyle(
                            color: AppTheme.accentNeon,
                            fontSize: 13,
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    ).animate(key: ValueKey(_questionIndex)).fadeIn(duration: 400.ms);
  }

  Widget _buildTabBar(bool compact) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x20FFFFFF)),
      ),
      child: TabBar(
        controller: _tabs,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]),
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle:
            TextStyle(fontWeight: FontWeight.w700, fontSize: compact ? 12 : 13),
        tabs: const [
          Tab(
            icon: Icon(Icons.gamepad_rounded, size: 18),
            text: 'Controls',
          ),
          Tab(
            icon: Icon(Icons.leaderboard_rounded, size: 18),
            text: 'Leaderboard',
          ),
        ],
      ),
    );
  }

  Widget _buildControlsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),

          // Section title
          const Text('Game Controls',
              style: TextStyle(
                  color: Color(0xAAFFFFFF),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2)),
          const SizedBox(height: 12),

          // Skip question
          _AdminActionCard(
            icon: Icons.skip_next_rounded,
            title: 'Skip Question',
            subtitle: 'Move to next question immediately',
            color: AppTheme.answerYellow,
            onTap: _gamePhase == 'playing' ? _skipQuestion : null,
          ),
          const SizedBox(height: 12),

          // End game
          _AdminActionCard(
            icon: Icons.stop_circle_rounded,
            title: 'End Game',
            subtitle: 'Show final leaderboard now',
            color: AppTheme.answerRed,
            onTap: _gamePhase == 'playing' || _gamePhase == 'result'
                ? _endGame
                : null,
          ),
          const SizedBox(height: 12),

          // Reset
          _AdminActionCard(
            icon: Icons.restart_alt_rounded,
            title: 'Reset & Return to Lobby',
            subtitle: 'Clear all scores, back to waiting room',
            color: Colors.orange,
            onTap: _resetGame,
          ),

          const SizedBox(height: 24),

          // Status card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x20FFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Game Status',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                const SizedBox(height: 12),
                _StatusRow(
                  label: 'Phase',
                  value: _gamePhase.toUpperCase(),
                  valueColor: _gamePhase == 'playing'
                      ? AppTheme.accentNeon
                      : Colors.orange,
                ),
                const SizedBox(height: 8),
                _StatusRow(
                  label: 'Question',
                  value: _totalQuestions > 0
                      ? '${_questionIndex + 1} / $_totalQuestions'
                      : '—',
                  valueColor: Colors.white,
                ),
                const SizedBox(height: 8),
                _StatusRow(
                  label: 'Players',
                  value: '${_players.length}',
                  valueColor: Colors.white,
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x14FFFFFF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0x20FFFFFF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Connected Players',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                const SizedBox(height: 10),
                if (_players.isEmpty)
                  const Text('No players yet',
                      style: TextStyle(color: Colors.white54, fontSize: 13)),
                ..._players.map((p) {
                  final name = p['name'] as String? ?? 'Unknown';
                  final isHost = p['isHost'] == true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x14FFFFFF)),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: isHost
                              ? const Color(0xFFFFD700).withOpacity(0.25)
                              : AppTheme.accent.withOpacity(0.25),
                          child: Text(
                            name.isEmpty ? '?' : name[0].toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                        if (isHost)
                          const Icon(Icons.star_rounded,
                              color: Color(0xFFFFD700), size: 16),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTab() {
    if (_leaderboard.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard_rounded, color: Color(0x44FFFFFF), size: 56),
            SizedBox(height: 16),
            Text('Leaderboard will appear\nafter the first question',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0x88FFFFFF), fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: _leaderboard.length,
      itemBuilder: (ctx, i) {
        final p = _leaderboard[i];
        final rank = p['rank'] as int;
        final name = p['name'] as String;
        final score = p['score'] as int;

        Widget rankWidget;
        if (rank == 1) {
          rankWidget = const Text('🥇', style: TextStyle(fontSize: 24));
        } else if (rank == 2) {
          rankWidget = const Text('🥈', style: TextStyle(fontSize: 24));
        } else if (rank == 3) {
          rankWidget = const Text('🥉', style: TextStyle(fontSize: 24));
        } else {
          rankWidget = Text('#$rank',
              style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 15,
                  fontWeight: FontWeight.w700));
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x18FFFFFF)),
          ),
          child: Row(
            children: [
              SizedBox(width: 38, child: rankWidget),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 18,
                backgroundColor: AppTheme.answerColors[i % 4].withOpacity(0.4),
                child: Text(name[0].toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [
                    Color(0xFF7C3AED),
                    Color(0xFF5B21B6),
                  ]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$score pts',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        )
            .animate()
            .slideX(
              begin: 0.3,
              delay: Duration(milliseconds: i * 50),
              duration: 300.ms,
              curve: Curves.easeOut,
            )
            .fadeIn(delay: Duration(milliseconds: i * 50));
      },
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
        color: color.withOpacity(0.08),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.16),
            blurRadius: 90,
            spreadRadius: 18,
          ),
        ],
      ),
    );
  }
}

// ── Helper widgets ─────────────────────────────────────────────────────────────

class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;

  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: disabled ? 0.4 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: disabled
                ? []
                : [
                    BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            color: disabled ? Colors.white54 : Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: TextStyle(
                            color: disabled ? Colors.white38 : Colors.white60,
                            fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  color: disabled ? Colors.white24 : color, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatusRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: valueColor, fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final VoidCallback onConfirm;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A0A3C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: Color(0x30FFFFFF)),
      ),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
      content: Text(message,
          style: const TextStyle(color: Colors.white70, fontSize: 14)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(confirmLabel,
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
