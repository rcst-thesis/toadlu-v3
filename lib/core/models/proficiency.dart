class KnowledgeOption {
  final String label;
  final int level;

  const KnowledgeOption({required this.label, required this.level});
}

const knowledgeOptions = [
  KnowledgeOption(label: "I’m still learning", level: 1),
  KnowledgeOption(label: 'I know a bit', level: 2),
  KnowledgeOption(label: 'I can understand most', level: 3),
  KnowledgeOption(label: "I’m fluent", level: 4),
];

enum EvaluationQuestionType {
  whatIsTheWord,
  selectMissingWord,
  translateSentence,
  matchingPair,
}

enum HomeMapDataset { easy, medium, hard }
