import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/socket_service.dart';
import '../theme/app_theme.dart';
import '../widgets/answer_button.dart';
import 'leaderboard_screen.dart';

enum _QuizState {
  waiting,
  question,
  answered,
  showResult,
}

class QuizScreen extends StatefulWidget {
  final String playerName;
  final bool isHost;

  const QuizScreen({
    super.key,
    required this.playerName,
    required this.isHost,
  });

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  _QuizState _state = _QuizState.waiting;

  int _questionIndex = 0;
  int _totalQuestions = 0;
  String _question = '';
  List<String> _options = [];
  int _timeLimit = 15;

  int _selectedAnswer = -1;
  bool _isCorrect = false;
  int _pointsEarned = 0;
  int _totalScore = 0;
  int _correctIndex = -1;

  Timer? _timer;
  int _secondsLeft = 15;

  @override
  void initState() {
    super.initState();
    _registerListeners();
  }

  void _registerListeners() {
    final socket = SocketService.instance;

    socket.onNewQuestion = (data) {
      if (!mounted) return;
      _timer?.cancel();
      setState(() {
        _state = _QuizState.question;
        _questionIndex = data['index'] as int;
        _totalQuestions = data['total'] as int;
        _question = data['question'] as String;
        _options = List<String>.from(data['options'] as List);
        _timeLimit = data['timeLimit'] as int;
        _secondsLeft = _timeLimit;
        _selectedAnswer = -1;
        _correctIndex = -1;
        _isCorrect = false;
        _pointsEarned = 0;
      });
      _startTimer();
    };

    socket.onAnswerResult = (data) {
      if (!mounted) return;
      _timer?.cancel();
      setState(() {
        _state = _QuizState.answered;
        _isCorrect = data['isCorrect'] as bool;
        _pointsEarned = data['points'] as int;
        _totalScore = data['totalScore'] as int;
        _correctIndex = data['correctIndex'] as int;
      });
    };

    socket.onQuestionResult = (data) {
      if (!mounted) return;
      _timer?.cancel();
      setState(() {
        _state = _QuizState.showResult;
        _correctIndex = data['correctIndex'] as int;
      });
    };

    socket.onGameOver = (data) {
      if (!mounted) return;
      _timer?.cancel();
      final leaderboard = List<Map<String, dynamic>>.from(
        (data['leaderboard'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map)),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => LeaderboardScreen(
            leaderboard: leaderboard,
            playerName: widget.playerName,
            totalScore: _totalScore,
            isAdmin: false,
          ),
        ),
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

  void _selectAnswer(int index) {
    if (_state != _QuizState.question) return;
    _timer?.cancel();
    setState(() {
      _selectedAnswer = index;
      _state = _QuizState.answered;
    });
    SocketService.instance.sendAnswer(_questionIndex, index);
  }

  @override
  void dispose() {
    _timer?.cancel();
    final socket = SocketService.instance;
    socket.onNewQuestion = null;
    socket.onAnswerResult = null;
    socket.onQuestionResult = null;
    socket.onGameOver = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_state == _QuizState.waiting) return _buildWaiting();
    return _buildQuiz();
  }

  Widget _buildWaiting() {
    final compact = MediaQuery.sizeOf(context).width < 380;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Stack(
          children: [
            Positioned(
                top: -80,
                left: -60,
                child: _GlowOrb(color: AppTheme.accent, size: 230)),
            Positioned(
                bottom: -90,
                right: -70,
                child: _GlowOrb(color: AppTheme.accentNeon, size: 220)),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3),
                  SizedBox(height: compact ? 16 : 24),
                  Text(
                    'Get ready! 🎯',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 24 : 28,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: compact ? 6 : 8),
                  Text(
                    'First question is coming...',
                    style: TextStyle(
                        color: Colors.white70, fontSize: compact ? 14 : 16),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuiz() {
    final compact = MediaQuery.sizeOf(context).width < 380;

    final bool isAnswered =
        _state == _QuizState.answered || _state == _QuizState.showResult;

    final double progress = isAnswered ? 0 : _secondsLeft / _timeLimit;

    final Color timerColor = _secondsLeft > 5
        ? AppTheme.accentNeon
        : _secondsLeft > 2
            ? Colors.orange
            : AppTheme.answerRed;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.mainGradient),
        child: Stack(
          children: [
            Positioned(
                top: -80,
                left: -60,
                child: _GlowOrb(color: AppTheme.accent, size: 220)),
            Positioned(
                bottom: -90,
                right: -70,
                child: _GlowOrb(color: AppTheme.accentNeon, size: 230)),
            SafeArea(
              child: Column(
                children: [
                  _buildTopBar(timerColor, progress, compact),
                  _buildScoreChip(compact),
                  SizedBox(height: compact ? 6 : 8),
                  Expanded(
                    flex: 3,
                    child: _buildQuestionCard(compact),
                  ),
                  if (_state == _QuizState.answered) _buildAnswerBanner(),
                  if (_state == _QuizState.answered)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Text(
                        'Waiting for other players...',
                        style: TextStyle(color: Colors.white60, fontSize: 13),
                      ),
                    ),
                  Expanded(
                    flex: 4,
                    child: _buildAnswerGrid(isAnswered, compact),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(Color timerColor, double progress, bool compact) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          compact ? 10 : 16, compact ? 8 : 12, compact ? 10 : 16, 0),
      child: Container(
        padding: EdgeInsets.fromLTRB(compact ? 10 : 12, compact ? 8 : 10,
            compact ? 10 : 12, compact ? 8 : 10),
        decoration: BoxDecoration(
          color: const Color(0x14FFFFFF),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x20FFFFFF)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: compact ? 10 : 12, vertical: compact ? 5 : 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Q ${_questionIndex + 1} / $_totalQuestions',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: compact ? 12 : 14,
                    ),
                  ),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: compact ? 42 : 50,
                  height: compact ? 42 : 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: timerColor.withOpacity(0.2),
                    border: Border.all(color: timerColor, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      '$_secondsLeft',
                      style: TextStyle(
                        color: timerColor,
                        fontSize: compact ? 16 : 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(timerColor),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChip(bool compact) {
    return Padding(
      padding: EdgeInsets.only(top: compact ? 6 : 10),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 16, vertical: compact ? 5 : 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF312E81), Color(0xFF6D28D9)],
          ),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: const Color(0x66FFFFFF)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accent.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
            const SizedBox(width: 5),
            Text(
              '$_totalScore pts',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: compact ? 13 : 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(bool compact) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          compact ? 10 : 16, compact ? 6 : 8, compact ? 10 : 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.13),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x22FFFFFF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(compact ? 16 : 24),
            child: Text(
              _question,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 18 : 21,
                fontWeight: FontWeight.bold,
                height: 1.45,
              ),
            ),
          ),
        ),
      )
          .animate(key: ValueKey(_questionIndex))
          .scale(
            begin: const Offset(0.85, 0.85),
            duration: 450.ms,
            curve: Curves.elasticOut,
          )
          .fadeIn(duration: 300.ms),
    );
  }

  Widget _buildAnswerBanner() {
    if (_isCorrect) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.greenAccent, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.greenAccent, size: 26),
            const SizedBox(width: 8),
            Text(
              'Correct!  +$_pointsEarned pts',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      )
          .animate()
          .scale(
            begin: const Offset(0.7, 0.7),
            duration: 400.ms,
            curve: Curves.elasticOut,
          )
          .fadeIn();
    }

    if (_selectedAnswer >= 0) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.25),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.redAccent, width: 1.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 26),
            SizedBox(width: 8),
            Text(
              'Wrong answer!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ).animate().scale(
            begin: const Offset(0.7, 0.7),
            duration: 400.ms,
            curve: Curves.elasticOut,
          );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange, width: 1.5),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer_off_rounded, color: Colors.orange, size: 26),
          SizedBox(width: 8),
          Text(
            'Time\'s up!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(int index, bool isAnswered) {
    if (index >= _options.length) return const SizedBox.shrink();
    final isSelected = _selectedAnswer == index;
    final isThisCorrect = _correctIndex >= 0 && index == _correctIndex;

    return Expanded(
      child: AnswerButton(
        label: _options[index],
        color: AppTheme.answerColors[index % 4],
        icon: AppTheme.answerIcons[index % 4],
        index: index,
        onPressed: isAnswered ? null : () => _selectAnswer(index),
        isSelected: isSelected,
        showCorrect: isAnswered && _isCorrect && _correctIndex >= 0,
        isCorrect: isThisCorrect,
      ),
    );
  }

  Widget _buildAnswerGrid(bool isAnswered, bool compact) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 8 : 14, compact ? 2 : 4,
          compact ? 8 : 14, compact ? 8 : 14),
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                _buildAnswerButton(0, isAnswered),
                SizedBox(width: compact ? 8 : 12),
                _buildAnswerButton(1, isAnswered),
              ],
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Expanded(
            child: Row(
              children: [
                _buildAnswerButton(2, isAnswered),
                SizedBox(width: compact ? 8 : 12),
                _buildAnswerButton(3, isAnswered),
              ],
            ),
          ),
        ],
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
