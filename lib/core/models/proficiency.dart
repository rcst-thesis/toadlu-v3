/// Describes one visible knowledge option on the onboarding screen.
///
/// The label is shown to the user, while `level` is kept internal so the app
/// can store a simple numeric proficiency value without showing "Level 1",
/// "Level 2", etc. in the UI.
class KnowledgeOption {
  final String label;
  final int level;

  const KnowledgeOption({required this.label, required this.level});
}

const knowledgeOptions = [
  KnowledgeOption(label: "I'm still learning", level: 1),
  KnowledgeOption(label: 'I know a bit', level: 2),
  KnowledgeOption(label: 'I can understand most', level: 3),
  KnowledgeOption(label: "I'm fluent", level: 4),
];

/// Question formats used by the onboarding evaluation test.
///
/// The evaluation screen reads this enum to decide which exercise widget to
/// show for each generated question.
enum EvaluationQuestionType {
  whatIsTheWord,
  selectMissingWord,
  translateSentence,
  matchingPair,
}

/// Internal dataset choice for lesson generation.
///
/// The user never sees these names. The evaluation score maps to one of these
/// datasets so the Home Map can start with easier or harder generated content.
enum HomeMapDataset { easy, medium, hard }
