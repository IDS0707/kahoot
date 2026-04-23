import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/socket_service.dart';
import '../theme/app_theme.dart';
import 'login_screen.dart';

class LeaderboardScreen extends StatelessWidget {
  final List<Map<String, dynamic>> leaderboard;
  final String playerName;
  final int totalScore;

  /// True when host navigates here (no personal rank to highlight)
  final bool isAdmin;

  const LeaderboardScreen({
    super.key,
    required this.leaderboard,
    required this.playerName,
    required this.totalScore,
    this.isAdmin = false,
  });

  int get _myRank {
    if (isAdmin) return -1;
    final idx = leaderboard.indexWhere((p) => p['name'] == playerName);
    return idx >= 0 ? idx + 1 : leaderboard.length;
  }

  @override
  Widget build(BuildContext context) {
    final myRank = _myRank;
    final compact = MediaQuery.sizeOf(context).width < 380;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Stack(
          children: [
            Positioned(
                top: -60,
                right: -40,
                child: _GlowOrb(color: AppTheme.accent, size: 220)),
            Positioned(
                bottom: -80,
                left: -60,
                child: _GlowOrb(color: AppTheme.answerGreen, size: 200)),
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(myRank, compact),
                  Expanded(child: _buildList(compact)),
                  _buildPlayAgainButton(context, compact),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(int myRank, bool compact) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 14 : 24, compact ? 14 : 24,
          compact ? 14 : 24, compact ? 10 : 16),
      child: Column(
        children: [
          Text('🏆', style: TextStyle(fontSize: compact ? 52 : 64))
              .animate()
              .scale(
                begin: const Offset(0, 0),
                duration: 700.ms,
                curve: Curves.elasticOut,
              ),
          SizedBox(height: compact ? 6 : 10),
          ShaderMask(
            shaderCallback: (b) => const LinearGradient(
              colors: [Colors.white, Color(0xFFA78BFA)],
            ).createShader(b),
            child: Text(
              'Game Over!',
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 28 : 34,
                fontWeight: FontWeight.w900,
              ),
            ),
          ).animate().fadeIn(delay: 250.ms),
          SizedBox(height: compact ? 4 : 6),
          Text(
            isAdmin
                ? '${leaderboard.length} players competed'
                : 'Your rank: #$myRank  •  $totalScore pts',
            style:
                TextStyle(color: Colors.white70, fontSize: compact ? 13 : 15),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildList(bool compact) {
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
      itemCount: leaderboard.length,
      itemBuilder: (context, index) {
        final player = leaderboard[index];
        final rank = player['rank'] as int;
        final name = player['name'] as String;
        final score = player['score'] as int;
        final isMe = !isAdmin && name == playerName;

        Widget rankWidget;
        if (rank == 1) {
          rankWidget =
              Text('🥇', style: TextStyle(fontSize: compact ? 24 : 28));
        } else if (rank == 2) {
          rankWidget =
              Text('🥈', style: TextStyle(fontSize: compact ? 24 : 28));
        } else if (rank == 3) {
          rankWidget =
              Text('🥉', style: TextStyle(fontSize: compact ? 24 : 28));
        } else {
          rankWidget = Text(
            '#$rank',
            style: TextStyle(
              color: Colors.white60,
              fontSize: compact ? 14 : 17,
              fontWeight: FontWeight.bold,
            ),
          );
        }

        return Container(
          margin: EdgeInsets.only(bottom: compact ? 8 : 10),
          padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : 16, vertical: compact ? 10 : 14),
          decoration: BoxDecoration(
            color: isMe
                ? AppTheme.accent.withOpacity(0.25)
                : const Color(0x14FFFFFF),
            borderRadius: BorderRadius.circular(16),
            border: isMe
                ? Border.all(color: AppTheme.accentGlow, width: 2)
                : Border.all(color: const Color(0x20FFFFFF)),
            boxShadow: isMe
                ? [
                    BoxShadow(
                        color: AppTheme.accent.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4))
                  ]
                : [],
          ),
          child: Row(
            children: [
              SizedBox(width: compact ? 32 : 42, child: rankWidget),
              SizedBox(width: compact ? 8 : 10),
              CircleAvatar(
                radius: compact ? 16 : 20,
                backgroundColor:
                    AppTheme.answerColors[index % 4].withOpacity(0.4),
                child: Text(
                  name[0].toUpperCase(),
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: compact ? 13 : 15,
                  ),
                ),
              ),
              SizedBox(width: compact ? 8 : 12),
              Expanded(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 14 : 16,
                    fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: compact ? 8 : 10, vertical: compact ? 4 : 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFF59E0B)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$score pts',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: compact ? 12 : 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        )
            .animate()
            .slideX(
              begin: 0.4,
              delay: Duration(milliseconds: 600 + index * 100),
              duration: 400.ms,
              curve: Curves.easeOut,
            )
            .fadeIn(delay: Duration(milliseconds: 600 + index * 100));
      },
    );
  }

  Widget _buildPlayAgainButton(BuildContext context, bool compact) {
    return Padding(
      padding: EdgeInsets.all(compact ? 14 : 24),
      child: GestureDetector(
        onTap: () {
          SocketService.instance.disconnect();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        },
        child: Container(
          width: double.infinity,
          height: compact ? 50 : 58,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)]),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.accent.withOpacity(0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.replay_rounded, color: Colors.white, size: 24),
              const SizedBox(width: 10),
              Text(
                'Play Again',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: compact ? 16 : 18,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      )
          .animate()
          .slideY(begin: 0.4, delay: 900.ms, duration: 400.ms)
          .fadeIn(delay: 900.ms),
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
