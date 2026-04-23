/**
 * Present Perfect quiz questions.
 * Each question has:
 *   - id          : unique number
 *   - question    : sentence shown to players
 *   - options     : array of 4 answer choices
 *   - correctIndex: 0-based index of the correct choice
 *   - timeLimit   : seconds allowed to answer (10-15)
 *   - explanation : grammar note shown after the question
 */
const questions = [
  {
    id: 1,
    question: "She ___ already finished her homework.",
    options: ["have", "has", "had", "is"],
    correctIndex: 1,
    timeLimit: 15,
    explanation: "With 3rd person singular (she), Present Perfect uses 'has': she has finished.",
  },
  {
    id: 2,
    question: "I ___ never been to Paris.",
    options: ["have", "has", "had", "am"],
    correctIndex: 0,
    timeLimit: 15,
    explanation: "With 'I', Present Perfect uses 'have': I have never been.",
  },
  {
    id: 3,
    question: "They ___ just arrived at the airport.",
    options: ["has", "have", "had", "are"],
    correctIndex: 1,
    timeLimit: 15,
    explanation: "Plural subject 'they' takes 'have' in Present Perfect: they have arrived.",
  },
  {
    id: 4,
    question: "___ you ever eaten sushi?",
    options: ["Have", "Has", "Did", "Do"],
    correctIndex: 0,
    timeLimit: 15,
    explanation: "For Present Perfect questions with 'you', use 'Have': Have you ever eaten?",
  },
  {
    id: 5,
    question: "He ___ lived in London for five years.",
    options: ["have", "has", "had", "is"],
    correctIndex: 1,
    timeLimit: 15,
    explanation: "3rd person singular 'he' uses 'has' in Present Perfect: he has lived.",
  },
  {
    id: 6,
    question: "We ___ not finished the project yet.",
    options: ["has", "have", "had", "are"],
    correctIndex: 1,
    timeLimit: 15,
    explanation: "With 'we', Present Perfect negative uses 'have not': we have not finished.",
  },
  {
    id: 7,
    question: "___ she ever seen the Eiffel Tower?",
    options: ["Have", "Has", "Did", "Does"],
    correctIndex: 1,
    timeLimit: 15,
    explanation: "For Present Perfect questions with 'she', use 'Has': Has she ever seen?",
  },
  {
    id: 8,
    question: "I have just ___ a new book.",
    options: ["read", "reads", "reading", "readed"],
    correctIndex: 0,
    timeLimit: 15,
    explanation: "After 'have/has', always use the past participle: read (irregular verb).",
  },
  {
    id: 9,
    question: "Which sentence is correct?",
    options: [
      "She has went to the store.",
      "She has gone to the store.",
      "She have gone to the store.",
      "She had go to the store.",
    ],
    correctIndex: 1,
    timeLimit: 15,
    explanation: "Correct Present Perfect: 'has' + past participle 'gone' (not 'went').",
  },
  {
    id: 10,
    question: "They have ___ dinner already.",
    options: ["eat", "ate", "eaten", "eating"],
    correctIndex: 2,
    timeLimit: 15,
    explanation: "After 'have', use the past participle 'eaten', not the base or past form.",
  },
  {
    id: 11,
    question: "My parents ___ never visited Japan.",
    options: ["has", "have", "had", "are"],
    correctIndex: 1,
    timeLimit: 15,
    explanation: "Plural subject 'my parents' uses 'have' in Present Perfect.",
  },
  {
    id: 12,
    question: "She has ___ her keys somewhere.",
    options: ["lose", "lost", "losing", "losted"],
    correctIndex: 1,
    timeLimit: 15,
    explanation: "After 'has', use past participle 'lost' (irregular verb: lose-lost-lost).",
  },
  {
    id: 13,
    question: "___ he finished his work yet?",
    options: ["Have", "Has", "Did", "Is"],
    correctIndex: 1,
    timeLimit: 15,
    explanation: "For Present Perfect questions with 'he', use 'Has': Has he finished yet?",
  },
  {
    id: 14,
    question: "I have ___ this movie three times.",
    options: ["see", "saw", "seen", "seeing"],
    correctIndex: 2,
    timeLimit: 15,
    explanation: "Past participle of 'see' is 'seen' (irregular): I have seen.",
  },
  {
    id: 15,
    question: "We have ___ in this city since 2010.",
    options: ["live", "lived", "living", "lives"],
    correctIndex: 1,
    timeLimit: 15,
    explanation: "Regular verb 'live' → past participle 'lived'. Used with 'since' for duration.",
  },
];

module.exports = questions;
