/**
 * server.js – Present Perfect Quiz Backend
 *
 * Stack  : Express + Socket.IO
 * Port   : process.env.PORT  || 3000
 *
 * Socket events (client → server):
 *   join        { name }
 *   start_game  (host only)
 *   answer      { questionIndex, answerIndex }
 *   reset_game  (host only)
 *
 * Socket events (server → client):
 *   joined          { name, isHost }
 *   room_update     { players, count }
 *   game_started
 *   new_question    { index, total, question, options, timeLimit }
 *   answer_result   { isCorrect, points, totalScore, correctIndex }
 *   question_result { questionIndex, correctIndex, correctAnswer, leaderboard }
 *   game_over       { leaderboard }
 *   game_reset
 */

const express = require("express");
const http = require("http");
const { Server } = require("socket.io");
const cors = require("cors");

const questions = require("./data/questions");
const ADMIN_CODE = "admin771";

// ─── Express setup ────────────────────────────────────────────────────────────
const app = express();
app.use(cors({ origin: "*" })); // tighten in production
app.use(express.json());

const server = http.createServer(app);

// ─── Socket.IO setup ──────────────────────────────────────────────────────────
const io = new Server(server, {
  cors: { origin: "*", methods: ["GET", "POST"] },
});

// ─── Game State (in-memory) ───────────────────────────────────────────────────
/**
 * players: Map<socketId, { name, score, isHost, answered }>
 */
let players = {};
let gameState = "waiting"; // 'waiting' | 'playing' | 'finished'
let currentQuestionIndex = 0;
let questionStartTime = 0;
let questionTimer = null;

// ─── Helpers ──────────────────────────────────────────────────────────────────

function getLeaderboard() {
  return Object.values(players)
    .sort((a, b) => b.score - a.score)
    .map((p, i) => ({ rank: i + 1, name: p.name, score: p.score }));
}

function getPlayerList() {
  return Object.values(players).map((p) => ({
    name: p.name,
    score: p.score,
    isHost: p.isHost,
  }));
}

function broadcastRoomUpdate() {
  io.emit("room_update", {
    players: getPlayerList(),
    count: Object.keys(players).length,
  });
}

function isAdminName(name) {
  return typeof name === "string" && name.trim().toLowerCase() === ADMIN_CODE;
}

// ─── Question flow ────────────────────────────────────────────────────────────

function sendNextQuestion() {
  if (currentQuestionIndex >= questions.length) {
    endGame();
    return;
  }

  const q = questions[currentQuestionIndex];
  questionStartTime = Date.now();

  // Reset answered flag for all active players
  Object.values(players).forEach((p) => {
    p.answered = false;
  });

  // Send question WITHOUT the correct answer
  io.emit("new_question", {
    index: currentQuestionIndex,
    total: questions.length,
    question: q.question,
    options: q.options,
    timeLimit: q.timeLimit,
  });

  console.log(
    `[Q${currentQuestionIndex + 1}/${questions.length}] ${q.question}`
  );

  // Auto-end question when timer expires
  questionTimer = setTimeout(processQuestionEnd, q.timeLimit * 1000);
}

function processQuestionEnd() {
  if (questionTimer) {
    clearTimeout(questionTimer);
    questionTimer = null;
  }

  const q = questions[currentQuestionIndex];

  io.emit("question_result", {
    questionIndex: currentQuestionIndex,
    correctIndex: q.correctIndex,
    correctAnswer: q.options[q.correctIndex],
    explanation: q.explanation,
    leaderboard: getLeaderboard(),
  });

  currentQuestionIndex++;

  // Pause 4 s, then send next question (or end game)
  setTimeout(sendNextQuestion, 4000);
}

function endGame() {
  gameState = "finished";
  console.log("[*] Game over! Final leaderboard:", getLeaderboard());
  io.emit("game_over", { leaderboard: getLeaderboard() });
}

// ─── Socket handlers ──────────────────────────────────────────────────────────

io.on("connection", (socket) => {
  console.log(`[+] Connection: ${socket.id}`);

  // ── join ────────────────────────────────────────────────────────────────────
  socket.on("join", ({ name }) => {
    if (!name || typeof name !== "string") return;

    // If game finished/over and room is empty → auto-reset so a new game can start
    if ((gameState === "finished" || gameState === "over") && Object.keys(players).length === 0) {
      gameState = "waiting";
      currentQuestionIndex = 0;
      if (questionTimer) { clearTimeout(questionTimer); questionTimer = null; }
    }

    // Don't allow joining during an active game
    if (gameState === "playing") {
      socket.emit("error", { message: "Game already in progress" });
      return;
    }

    // Sanitise name: trim + limit length
    const safeName = name.trim().substring(0, 20);
    const adminId = Object.keys(players).find((id) => players[id].isHost);
    const wantsAdmin = isAdminName(safeName);

    if (wantsAdmin && adminId) {
      socket.emit("error", { message: "Admin already connected" });
      return;
    }

    const isHost = wantsAdmin;

    players[socket.id] = {
      name: safeName,
      score: 0,
      isHost,
      answered: false,
    };

    console.log(`[+] "${safeName}" joined (host: ${isHost})`);

    // Tell everyone the room changed
    broadcastRoomUpdate();

    // Tell the joining player their role + current player list
    socket.emit("joined", { name: safeName, isHost, players: getPlayerList() });
  });

  // ── start_game ──────────────────────────────────────────────────────────────
  socket.on("start_game", () => {
    if (!players[socket.id]?.isHost) return;
    if (gameState !== "waiting") return;

    gameState = "playing";
    currentQuestionIndex = 0;

    // Reset all scores
    Object.values(players).forEach((p) => {
      p.score = 0;
    });

    console.log("[*] Game started!");
    io.emit("game_started");

    // Small delay so clients can animate the transition
    setTimeout(sendNextQuestion, 2000);
  });

  // ── answer ───────────────────────────────────────────────────────────────────
  socket.on("answer", ({ questionIndex, answerIndex }) => {
    if (gameState !== "playing") return;
    if (questionIndex !== currentQuestionIndex) return; // stale answer

    const player = players[socket.id];
    if (!player || player.answered) return; // already answered

    player.answered = true;

    const q = questions[currentQuestionIndex];
    const isCorrect = answerIndex === q.correctIndex;
    const elapsed = (Date.now() - questionStartTime) / 1000;

    // Scoring: max 1 000 pts, decays linearly with time; minimum 100 for correct
    const points = isCorrect
      ? Math.max(100, Math.round(1000 * (1 - elapsed / q.timeLimit)))
      : 0;

    player.score += points;

    // Send personalised result to this player only
    socket.emit("answer_result", {
      isCorrect,
      points,
      totalScore: player.score,
      correctIndex: q.correctIndex,
    });

    console.log(
      `[A] "${player.name}" → ${isCorrect ? "✓" : "✗"} (+${points} pts, total: ${player.score})`
    );

    // If every connected player has answered → end question early
    // If every non-host player has answered → end question early
    const nonHosts = Object.values(players).filter((p) => !p.isHost);
    const allAnswered = nonHosts.length > 0 && nonHosts.every((p) => p.answered);
    if (allAnswered) processQuestionEnd();
  });

  // ── reset_game ───────────────────────────────────────────────────────────────
  socket.on("reset_game", () => {
    if (!players[socket.id]?.isHost) return;

    gameState = "waiting";
    currentQuestionIndex = 0;
    if (questionTimer) clearTimeout(questionTimer);

    Object.values(players).forEach((p) => {
      p.score = 0;
      p.answered = false;
    });

    console.log("[*] Game reset by host");
    io.emit("game_reset");
    broadcastRoomUpdate();
  });
  // ── skip_question ─────────────────────────────────────────────────────────
  socket.on('skip_question', () => {
    if (!players[socket.id]?.isHost) return;
    if (gameState !== 'playing') return;
    console.log('[*] Host skipped question');
    processQuestionEnd();
  });

  // ── end_game ──────────────────────────────────────────────────────────────
  socket.on('end_game', () => {
    if (!players[socket.id]?.isHost) return;
    if (gameState !== 'playing') return;
    if (questionTimer) clearTimeout(questionTimer);
    questionTimer = null;
    console.log('[*] Host ended game early');
    endGame();
  });
  // ── disconnect ───────────────────────────────────────────────────────────────
  socket.on("disconnect", () => {
    const player = players[socket.id];
    if (!player) return;

    console.log(`[-] "${player.name}" disconnected`);

    const wasHost = player.isHost;
    delete players[socket.id];

    // If host left, transfer host only to another admin771 user (if present)
    if (wasHost && gameState === "waiting") {
      const ids = Object.keys(players);
      const nextAdminId = ids.find((id) => isAdminName(players[id].name));
      if (nextAdminId) {
        players[nextAdminId].isHost = true;
        console.log(`[~] New host: "${players[nextAdminId].name}"`);
      }
    }

    // If all players disconnected after game, reset state
    if (Object.keys(players).length === 0) {
      gameState = "waiting";
      currentQuestionIndex = 0;
      if (questionTimer) { clearTimeout(questionTimer); questionTimer = null; }
      console.log("[~] All players left – game reset to waiting");
    }

    broadcastRoomUpdate();
  });
});

// ─── REST endpoints ───────────────────────────────────────────────────────────

app.get("/", (_req, res) => {
  res.json({ message: "Kahoot Present Perfect Quiz API", version: "1.0.0" });
});

app.get("/health", (_req, res) => {
  res.json({
    status: "healthy",
    gameState,
    playerCount: Object.keys(players).length,
    currentQuestion: currentQuestionIndex,
  });
});

// ─── Start ────────────────────────────────────────────────────────────────────

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚀  Server listening on http://localhost:${PORT}`);
});
