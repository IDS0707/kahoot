/// Public question metadata (no answers).
///
/// 🔐 SECURITY: As of Faza 2 the authoritative question vault lives in
/// Postgres (`questions` table) and answers are validated server-side
/// via `rpc_submit_answer`. The constants below are kept ONLY for:
///   - the admin edit dialog placeholder text (Faza 3 fetches from server)
///   - the offline fallback path in [SocketService] when RPCs are unreachable
///
/// `correctIndex` and `explanation` have been intentionally redacted from
/// the client bundle so a player inspecting their app can't cheat.
final List<Map<String, dynamic>> kQuestions = [
  {
    'question': "She ___ already finished her homework.",
    'options': ["have", "has", "had", "is"],
    'timeLimit': 15,
  },
  {
    'question': "I ___ never been to Paris.",
    'options': ["have", "has", "had", "am"],
    'timeLimit': 15,
  },
  {
    'question': "They ___ just arrived at the airport.",
    'options': ["has", "have", "had", "are"],
    'timeLimit': 15,
  },
  {
    'question': "___ you ever eaten sushi?",
    'options': ["Have", "Has", "Did", "Do"],
    'timeLimit': 15,
  },
  {
    'question': "He ___ lived in London for five years.",
    'options': ["have", "has", "had", "is"],
    'timeLimit': 15,
  },
  {
    'question': "We ___ not finished the project yet.",
    'options': ["has", "have", "had", "are"],
    'timeLimit': 15,
  },
  {
    'question': "___ she ever seen the Eiffel Tower?",
    'options': ["Have", "Has", "Did", "Does"],
    'timeLimit': 15,
  },
  {
    'question': "I have just ___ a new book.",
    'options': ["read", "reads", "reading", "readed"],
    'timeLimit': 15,
  },
  {
    'question': "Which sentence is correct?",
    'options': [
      "She has went to the store.",
      "She has gone to the store.",
      "She have gone to the store.",
      "She had go to the store.",
    ],
    'timeLimit': 18,
  },
  {
    'question': "They have ___ dinner already.",
    'options': ["eat", "ate", "eaten", "eating"],
    'timeLimit': 15,
  },
  {
    'question': "My parents ___ never visited Japan.",
    'options': ["has", "have", "had", "are"],
    'timeLimit': 15,
  },
  {
    'question': "She has ___ her keys somewhere.",
    'options': ["lose", "lost", "losing", "losted"],
    'timeLimit': 15,
  },
  {
    'question': "___ he finished his work yet?",
    'options': ["Have", "Has", "Did", "Is"],
    'timeLimit': 15,
  },
  {
    'question': "I have ___ this movie three times.",
    'options': ["see", "saw", "seen", "seeing"],
    'timeLimit': 15,
  },
  {
    'question': "We have ___ in this city since 2010.",
    'options': ["live", "lived", "living", "lives"],
    'timeLimit': 15,
  },
];
