# 🎮 Present Perfect Quiz – Kahoot Clone

A real-time multiplayer quiz game for learning English Present Perfect tense.  
Built with **Flutter** (frontend) + **Node.js + Socket.IO** (backend).

---

## 📁 Project Structure

```
kahoot/
├── backend/          # Node.js + Socket.IO server
│   ├── server.js
│   ├── data/
│   │   └── questions.js
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── package.json
└── frontend/         # Flutter app (Android / iOS / Web)
    ├── lib/
    │   ├── main.dart
    │   ├── config.dart          ← change server URL here
    │   ├── services/
    │   │   └── socket_service.dart
    │   ├── screens/
    │   │   ├── login_screen.dart
    │   │   ├── waiting_room_screen.dart
    │   │   ├── quiz_screen.dart
    │   │   └── leaderboard_screen.dart
    │   ├── widgets/
    │   │   └── answer_button.dart
    │   └── theme/
    │       └── app_theme.dart
    ├── pubspec.yaml
    └── vercel.json
```

---

## 🚀 Quick Start

### 1 – Backend (local)

```bash
cd backend
npm install
npm run dev        # nodemon, hot-reload
# or
npm start          # plain node
```

Server starts at **http://localhost:3000**  
Health check: http://localhost:3000/health

---

### 2 – Backend (Docker)

```bash
cd backend
docker-compose up --build
```

---

### 3 – Flutter Frontend

```bash
cd frontend
flutter pub get

# Android / iOS
flutter run

# Web
flutter run -d chrome

# Release web build
flutter build web --release
```

**Important:** Update the server URL in `lib/config.dart`:

```dart
static const String serverUrl = 'http://YOUR_BACKEND_URL:3000';
```

---

## 🎯 Game Flow

```
Login  →  Waiting Room  →  Quiz (×10 questions)  →  Leaderboard
```

1. Any player who joins first becomes **Host** (shown with ⭐).
2. Host clicks **Start Game**.
3. Server broadcasts 10 Present Perfect questions one by one.
4. Players have **15 seconds** per question.
5. Scoring: faster correct answers earn more points (max 1 000 per question).
6. After all questions → final **Leaderboard** with 🥇 🥈 🥉 medals.

---

## 🌐 Socket Events

| Direction | Event | Payload |
|-----------|-------|---------|
| Client → Server | `join` | `{ name }` |
| Client → Server | `start_game` | – |
| Client → Server | `answer` | `{ questionIndex, answerIndex }` |
| Client → Server | `reset_game` | – |
| Server → Client | `joined` | `{ name, isHost }` |
| Server → Client | `room_update` | `{ players, count }` |
| Server → Client | `game_started` | – |
| Server → Client | `new_question` | `{ index, total, question, options, timeLimit }` |
| Server → Client | `answer_result` | `{ isCorrect, points, totalScore, correctIndex }` |
| Server → Client | `question_result` | `{ correctIndex, correctAnswer, leaderboard }` |
| Server → Client | `game_over` | `{ leaderboard }` |
| Server → Client | `game_reset` | – |

---

## ☁️ Deployment

### Backend → Render

1. Push `backend/` to a GitHub repo.
2. Create a new **Web Service** on [render.com](https://render.com).
3. Set **Start Command**: `node server.js`
4. Set **Environment Variable**: `PORT=10000` (Render default).
5. Update `lib/config.dart` in the Flutter app with your Render URL.

### Frontend → Vercel

```bash
cd frontend
flutter build web --release
vercel deploy build/web --prod
```

Or connect the GitHub repo to Vercel and set:
- **Build Command**: `flutter build web --release`
- **Output Directory**: `build/web`

---

## 📝 Questions (Present Perfect)

| # | Question | Correct |
|---|----------|---------|
| 1 | She ___ already eaten lunch. | **has** |
| 2 | Have you ever ___ to Paris? | **been** |
| 3 | They ___ just arrived. | **have** |
| 4 | I have ___ this movie before. | **seen** |
| 5 | He ___ never tried sushi. | **has** |
| 6 | We have lived here ___ five years. | **for** |
| 7 | Has she ___ her homework yet? | **finished** |
| 8 | I ___ been waiting for two hours. | **have** |
| 9 | Which sentence is correct? | **I have seen the film** |
| 10 | She has ___ London three times. | **visited** |

---

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter 3.x (Android, iOS, Web) |
| Animations | flutter_animate |
| Backend | Node.js 18 + Express |
| Real-time | Socket.IO 4 |
| Containerisation | Docker + docker-compose |
| Frontend deploy | Vercel |
| Backend deploy | Render |
