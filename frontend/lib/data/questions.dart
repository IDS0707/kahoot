/// All quiz questions with correct answers.
/// The correctIndex is only used locally (client-side scoring).
const List<Map<String, dynamic>> kQuestions = [
  {
    'question': "She ___ already finished her homework.",
    'options': ["have", "has", "had", "is"],
    'correctIndex': 1,
    'timeLimit': 15,
    'explanation':
        "With 3rd person singular (she), Present Perfect uses 'has': she has finished.",
  },
  {
    'question': "I ___ never been to Paris.",
    'options': ["have", "has", "had", "am"],
    'correctIndex': 0,
    'timeLimit': 15,
    'explanation': "With 'I', Present Perfect uses 'have': I have never been.",
  },
  {
    'question': "They ___ just arrived at the airport.",
    'options': ["has", "have", "had", "are"],
    'correctIndex': 1,
    'timeLimit': 15,
    'explanation':
        "Plural subject 'they' takes 'have' in Present Perfect: they have arrived.",
  },
  {
    'question': "___ you ever eaten sushi?",
    'options': ["Have", "Has", "Did", "Do"],
    'correctIndex': 0,
    'timeLimit': 15,
    'explanation':
        "For Present Perfect questions with 'you', use 'Have': Have you ever eaten?",
  },
  {
    'question': "He ___ lived in London for five years.",
    'options': ["have", "has", "had", "is"],
    'correctIndex': 1,
    'timeLimit': 15,
    'explanation':
        "3rd person singular 'he' uses 'has' in Present Perfect: he has lived.",
  },
  {
    'question': "We ___ not finished the project yet.",
    'options': ["has", "have", "had", "are"],
    'correctIndex': 1,
    'timeLimit': 15,
    'explanation':
        "With 'we', Present Perfect negative uses 'have not': we have not finished.",
  },
  {
    'question': "___ she ever seen the Eiffel Tower?",
    'options': ["Have", "Has", "Did", "Does"],
    'correctIndex': 1,
    'timeLimit': 15,
    'explanation':
        "For Present Perfect questions with 'she', use 'Has': Has she ever seen?",
  },
  {
    'question': "I have just ___ a new book.",
    'options': ["read", "reads", "reading", "readed"],
    'correctIndex': 0,
    'timeLimit': 15,
    'explanation':
        "After 'have/has', always use the past participle: read (irregular verb).",
  },
  {
    'question': "Which sentence is correct?",
    'options': [
      "She has went to the store.",
      "She has gone to the store.",
      "She have gone to the store.",
      "She had go to the store.",
    ],
    'correctIndex': 1,
    'timeLimit': 15,
    'explanation':
        "Correct Present Perfect: 'has' + past participle 'gone' (not 'went').",
  },
  {
    'question': "They have ___ dinner already.",
    'options': ["eat", "ate", "eaten", "eating"],
    'correctIndex': 2,
    'timeLimit': 15,
    'explanation':
        "After 'have', use the past participle 'eaten', not the base or past form.",
  },
  {
    'question': "My parents ___ never visited Japan.",
    'options': ["has", "have", "had", "are"],
    'correctIndex': 1,
    'timeLimit': 15,
    'explanation':
        "Plural subject 'my parents' uses 'have' in Present Perfect.",
  },
  {
    'question': "She has ___ her keys somewhere.",
    'options': ["lose", "lost", "losing", "losted"],
    'correctIndex': 1,
    'timeLimit': 15,
    'explanation':
        "After 'has', use past participle 'lost' (irregular verb: lose-lost-lost).",
  },
  {
    'question': "___ he finished his work yet?",
    'options': ["Have", "Has", "Did", "Is"],
    'correctIndex': 1,
    'timeLimit': 15,
    'explanation':
        "For Present Perfect questions with 'he', use 'Has': Has he finished yet?",
  },
  {
    'question': "I have ___ this movie three times.",
    'options': ["see", "saw", "seen", "seeing"],
    'correctIndex': 2,
    'timeLimit': 15,
    'explanation':
        "Past participle of 'see' is 'seen' (irregular): I have seen.",
  },
  {
    'question': "We have ___ in this city since 2010.",
    'options': ["live", "lived", "living", "lives"],
    'correctIndex': 1,
    'timeLimit': 15,
    'explanation':
        "Regular verb 'live' → past participle 'lived'. Used with 'since' for duration.",
  },
];
