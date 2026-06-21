import 'dart:math' as math;

import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/data/lesson_bank/grade_1_lesson_bank.dart';
import 'package:tudloapp/data/lesson_bank/grade_2_lesson_bank.dart';
import 'package:tudloapp/data/lesson_bank/grade_3_lesson_bank.dart';
import 'package:tudloapp/data/lesson_bank/grade_lesson_dataset.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank_item.dart';

export 'package:tudloapp/data/lesson_bank/lesson_bank_item.dart';

enum QuestionType {
  translationChoice,
  arrangeWords,
  fillBlank,
  choice,
  matching,
  completeSentence,
  buildSentence,
  imageChoice,
}

/// Data model used by both map lessons and tests.
///
/// The named constructors keep each question type explicit while still letting
/// the UI render all questions through one model.
class LessonQuestion {
  final QuestionType type;
  final String prompt;
  final String answer;
  final List<String> choices;
  final List<String> leftItems;
  final List<String> rightItems;
  final List<String> sentenceWords;
  final List<LessonTerm> imageChoices;
  final String imagePath;
  final String sentenceMeaning;
  final Map<String, String> wordMeanings;
  final String targetPhrase;
  final String targetMeaning;
  final String directionLabel;

  const LessonQuestion.choice({
    required this.prompt,
    required this.answer,
    required this.choices,
    this.imagePath = '',
    this.sentenceMeaning = '',
    this.wordMeanings = const {},
    this.targetPhrase = '',
    this.targetMeaning = '',
    this.directionLabel = '',
  }) : type = QuestionType.choice,
       leftItems = const [],
       rightItems = const [],
       sentenceWords = const [],
       imageChoices = const [];

  const LessonQuestion.translationChoice({
    required this.prompt,
    required this.answer,
    required this.choices,
    this.imagePath = '',
    this.sentenceMeaning = '',
    this.wordMeanings = const {},
    this.targetPhrase = '',
    this.targetMeaning = '',
    this.directionLabel = '',
  }) : type = QuestionType.translationChoice,
       leftItems = const [],
       rightItems = const [],
       sentenceWords = const [],
       imageChoices = const [];

  const LessonQuestion.fillBlank({
    required this.prompt,
    required this.answer,
    required this.choices,
    this.imagePath = '',
    this.sentenceMeaning = '',
    this.wordMeanings = const {},
    this.targetPhrase = '',
    this.targetMeaning = '',
    this.directionLabel = '',
  }) : type = QuestionType.fillBlank,
       leftItems = const [],
       rightItems = const [],
       sentenceWords = const [],
       imageChoices = const [];

  const LessonQuestion.matching({
    required this.prompt,
    required this.leftItems,
    required this.rightItems,
    this.targetPhrase = '',
    this.targetMeaning = '',
    this.directionLabel = '',
  }) : type = QuestionType.matching,
       answer = '',
       choices = const [],
       sentenceWords = const [],
       imageChoices = const [],
       imagePath = '',
       sentenceMeaning = '',
       wordMeanings = const {};

  const LessonQuestion.completeSentence({
    required this.prompt,
    required this.answer,
    required this.choices,
    this.imagePath = '',
    this.sentenceMeaning = '',
    this.wordMeanings = const {},
    this.targetPhrase = '',
    this.targetMeaning = '',
    this.directionLabel = '',
  }) : type = QuestionType.completeSentence,
       leftItems = const [],
       rightItems = const [],
       sentenceWords = const [],
       imageChoices = const [];

  const LessonQuestion.buildSentence({
    required this.prompt,
    required this.answer,
    required this.sentenceWords,
    this.imagePath = '',
    this.sentenceMeaning = '',
    this.wordMeanings = const {},
    this.targetPhrase = '',
    this.targetMeaning = '',
    this.directionLabel = '',
  }) : type = QuestionType.buildSentence,
       choices = const [],
       leftItems = const [],
       rightItems = const [],
       imageChoices = const [];

  const LessonQuestion.arrangeWords({
    required this.prompt,
    required this.answer,
    required this.sentenceWords,
    this.imagePath = '',
    this.sentenceMeaning = '',
    this.wordMeanings = const {},
    this.targetPhrase = '',
    this.targetMeaning = '',
    this.directionLabel = '',
  }) : type = QuestionType.arrangeWords,
       choices = const [],
       leftItems = const [],
       rightItems = const [],
       imageChoices = const [];

  const LessonQuestion.imageChoice({
    required this.prompt,
    required this.answer,
    required this.imageChoices,
    this.imagePath = '',
    this.sentenceMeaning = '',
    this.wordMeanings = const {},
    this.targetPhrase = '',
    this.targetMeaning = '',
    this.directionLabel = '',
  }) : type = QuestionType.imageChoice,
       choices = const [],
       leftItems = const [],
       rightItems = const [],
       sentenceWords = const [];
}

class LessonExample {
  final String category;
  final String hiligaynon;
  final String english;
  final String note;

  const LessonExample({
    this.category = '',
    required this.hiligaynon,
    required this.english,
    this.note = '',
  });
}

class LessonConceptCard {
  final String title;
  final String hiligaynon;
  final String english;

  const LessonConceptCard({
    required this.title,
    required this.hiligaynon,
    required this.english,
  });
}

class LessonLevelContent {
  final String title;
  final String storyTitle;
  final String story;
  final String shortLesson;
  final List<LessonConceptCard> concepts;
  final List<LessonExample> examples;

  const LessonLevelContent({
    required this.title,
    required this.storyTitle,
    required this.story,
    required this.shortLesson,
    this.concepts = const [],
    required this.examples,
  });
}

/// Central lesson content source.
///
/// Level Game questions use only the current unit's terms. Unit Content Preview
/// also reads from this same bank, so editing content here updates both places.
class LessonBank {
  static const unitTitles = {
    1: 'Pagkilala sa Akon Kaugalingon kag Pamilya',
    2: 'Pakig-istorya sa Palibot',
    3: 'Ako kag Akon mga Abyan',
    4: 'Palangga Ko ang Pamilya',
    5: 'Adlaw-adlaw nga Kabuhi',
    6: 'Akon Komunidad',
  };

  static const gradeDatasets = {
    GradeLevel.grade1: grade1LessonDataset,
    GradeLevel.grade2: grade2LessonDataset,
    GradeLevel.grade3: grade3LessonDataset,
  };

  static const terms = [
    // Unit 1: Everyday Conversation.
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Maayong aga',
      eng: 'Good morning',
      missingSentence: 'Maayong ___.',
      missingAnswer: 'aga',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Kamusta ka?',
      eng: 'How are you?',
      missingSentence: '___ ka?',
      missingAnswer: 'Kamusta',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Maayong aga, Josh! Kamusta ka?',
      eng: 'Good morning, Josh! How are you?',
      wordBlocks: ['Maayong', 'aga,', 'Josh!', 'Kamusta', 'ka?'],
      imagePath:
          'assets/images/level_game/unit 1/arrange-words/good-morning-how-are-you.png',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Grabe gid ang init subong',
      eng: "It's really hot today",
      wordBlocks: ['gid', 'init', 'grabe', 'subong', 'ang'],
      imagePath:
          'assets/images/level_game/unit 1/arrange-words/It\'s-really-hot-today.png',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Ga pila kami para mag bayad.',
      eng: 'We are lining up to pay',
      missingSentence: 'ga pila ____ para mag ____.',
      missingAnswer: 'kami bayad',
      choices: ['gina', 'kami', 'dalagan', 'bayad', 'kaon', 'kanta'],
      imagePath:
          'assets/images/level_game/unit 1/complete_the_sentence/ga-pila-kami-para-mag-bayad.png',
      wordMeanings: {
        'pila': 'line',
        'dalagan': 'ran',
        'kami': 'we/us',
        'kaon': 'eat',
        'bayad': 'pay',
      },
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Ga hulat ako sang jeep.',
      eng: 'I am waiting for a jeep.',
      missingSentence: 'ga ____ ako sang ____.',
      missingAnswer: 'hulat jeep',
      choices: ['hulat', 'jeep', 'kaon', 'kanta', 'dalagan', 'tubig'],
      imagePath:
          'assets/images/level_game/unit 1/complete_the_sentence/ga-hulat-ako-sang-jeep.png',
      wordMeanings: {
        'ga': 'is / currently',
        'hulat': 'waiting',
        'ako': 'I / me',
        'sang': 'for / of',
        'jeep': 'jeepney',
      },
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Ga ano ka subong',
      eng: 'What are you doing right now',
      missingSentence: 'Ga ano ka ___.',
      missingAnswer: 'subong',
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Kamusta ang adlaw mo?',
      eng: 'How is your day?',
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Diin ka subong?',
      eng: 'Where are you right now?',
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Salamat',
      eng: 'Thank you',
      missingSentence: 'Salamat ___.',
      missingAnswer: 'gid',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Palihog',
      eng: 'Please',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Huo',
      eng: 'Yes',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Indi',
      eng: 'No',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Okay lang ako',
      eng: "I'm okay",
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Maayo man ako',
      eng: "I'm fine",
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Kitaay ta liwat',
      eng: 'See you again',
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Gina lagas ako sang ido.',
      eng: 'I am being chased by a dog.',
      missingSentence: '____ ____ ako sang ____.',
      missingAnswer: 'gina lagas ido',
      choices: ['basa', 'gina', 'tubig', 'lagas', 'kaon', 'ido'],
      imagePath:
          'assets/images/level_game/unit 1/complete_the_sentence/gina-lagas-ako-sang-ido.png',
      wordMeanings: {'ako': 'I / me', 'sang': 'by / of'},
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Na basa akon bayo kay nag-ulan gulpi.',
      eng: 'My clothes got wet because it suddenly rained.',
      missingSentence: 'Na ____ akon bayo kay nag-ulan gulpi.',
      missingAnswer: 'basa',
      choices: ['dako', 'init', 'basa', 'gamay'],
      imagePath:
          'assets/images/level_game/unit 1/complete_the_sentence/Na-basa-bayo-ko-kay-nag-ulan-gulpi.png',
      wordMeanings: {
        'Na': 'got / became',
        'akon': 'my',
        'bayo': 'clothes',
        'kay': 'because',
        'nag-ulan': 'rained / it rained',
        'gulpi': 'suddenly',
      },
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Ang ngalan ko si Nicole',
      eng: 'My name is Nicole',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Lamig',
      eng: 'Cold',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Init',
      eng: 'Hot',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Nanay',
      eng: 'Mother',
      imagePath:
          'assets/images/level_game/unit 1/image_choice/people/mother.png',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Tatay',
      eng: 'Father',
      imagePath:
          'assets/images/level_game/unit 1/image_choice/people/father.png',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Lola',
      eng: 'Grandmother',
      imagePath:
          'assets/images/level_game/unit 1/image_choice/people/grandmother.png',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Lolo',
      eng: 'Grandfather',
      imagePath:
          'assets/images/level_game/unit 1/image_choice/people/grandfather.png',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Jeep',
      eng: 'Jeepney',
      imagePath:
          'assets/images/level_game/unit 1/image_choice/transportation/Jeep.png',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Bangka',
      eng: 'Boat',
      imagePath:
          'assets/images/level_game/unit 1/image_choice/transportation/Bangka.png',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Eroplano',
      eng: 'Airplane',
      imagePath:
          'assets/images/level_game/unit 1/image_choice/transportation/Eroplano.png',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 1,
      hil: 'Traysikad',
      eng: 'Tricycle',
      imagePath:
          'assets/images/level_game/unit 1/image_choice/transportation/Traysikad.png',
      lessonNumber: 1,
    ),

    // Grade 2 Unit 1: Mga Ginakawilihan Ko.
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Kasilingan',
      eng: 'Neighbor',
      exampleSentenceHiligaynon:
          'Mabuot kag mabinuligon ang amon mga kasilingan.',
      exampleSentenceEnglish: 'Our neighbors are kind and helpful.',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Pangalan',
      eng: 'Noun',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Tawo',
      eng: 'Person',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Butang',
      eng: 'Thing',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Sapat',
      eng: 'Animal',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Lugar',
      eng: 'Place',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Hitabo',
      eng: 'Event',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Lapis',
      eng: 'Pencil',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Parke',
      eng: 'Park',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Pispis',
      eng: 'Bird',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Kuring',
      eng: 'Cat',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Pat-od nga pangalan',
      eng: 'Proper noun',
      lessonNumber: 2,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Kinaandan nga pangalan',
      eng: 'Common noun',
      lessonNumber: 2,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Rina',
      eng: 'Child',
      lessonNumber: 2,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Nanay Rowena',
      eng: 'Mother',
      lessonNumber: 2,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Mayor Basilio',
      eng: 'Mayor',
      lessonNumber: 2,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Manunudlo',
      eng: 'Teacher',
      lessonNumber: 2,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Tanda',
      eng: 'Sign',
      exampleSentenceHiligaynon: 'Madamo ang tanda nga makita sa karsada.',
      exampleSentenceEnglish: 'Many signs can be seen on the road.',
      lessonNumber: 3,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Iloilo River',
      eng: 'River',
      lessonNumber: 3,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Boracay',
      eng: 'Beach place',
      lessonNumber: 3,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Plaza Libertad',
      eng: 'Park',
      lessonNumber: 3,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Merkado',
      eng: 'Market',
      lessonNumber: 3,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Kalendaryo',
      eng: 'Calendar',
      exampleSentenceHiligaynon:
          'Tan-awa ang kalendaryo agud mahibalu-an ang adlaw.',
      exampleSentenceEnglish: 'Look at the calendar to know the day.',
      lessonNumber: 4,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Kahiwatan',
      eng: 'Event or celebration',
      lessonNumber: 4,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Bag-ong Tuig',
      eng: 'New Year',
      lessonNumber: 4,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Adlaw sang Kahilwayan',
      eng: 'Independence Day',
      lessonNumber: 4,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Rizal Day',
      eng: 'Rizal Day',
      lessonNumber: 4,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Baganihan',
      eng: 'Hero',
      exampleSentenceHiligaynon: 'Ginkilala nga isa ka baganihan si Lito.',
      exampleSentenceEnglish: 'Lito was recognized as a hero.',
      lessonNumber: 5,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Sakripisyo',
      eng: 'Sacrifice',
      lessonNumber: 5,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Dr. Jose Rizal',
      eng: 'National hero',
      lessonNumber: 5,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Mga Ginakawilihan Ko',
      gradeLevel: 2,
      type: LessonContentType.word,
      hil: 'Pilipinas',
      eng: 'Philippines',
      lessonNumber: 5,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 3,
      hil: 'Pangalan',
      eng: 'Noun',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 3,
      hil: 'Tawo',
      eng: 'Person',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 3,
      hil: 'Lugar',
      eng: 'Place',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 3,
      hil: 'Butang',
      eng: 'Thing',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 3,
      hil: 'Sapat',
      eng: 'Animal',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 3,
      hil: 'Halamtangan',
      eng: 'Setting',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 3,
      hil: 'Katawhan',
      eng: 'Characters',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 3,
      hil: 'Hinabo',
      eng: 'Event',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 3,
      hil: 'Rina',
      eng: 'child',
      imagePath:
          'assets/images/level_game/unit 1/image_choice/people/mother.png',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 3,
      hil: 'Nanay Rowena',
      eng: 'mother',
      imagePath:
          'assets/images/level_game/unit 1/image_choice/people/mother.png',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 3,
      hil: 'Mayor Basilio',
      eng: 'mayor',
      imagePath:
          'assets/images/level_game/unit 1/image_choice/people/father.png',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 3,
      hil: 'Iloilo River',
      eng: 'river',
      lessonNumber: 1,
    ),
    LessonTerm(
      unitNumber: 1,
      unitTitle: 'Everyday Conversation',
      gradeLevel: 3,
      hil: 'Plaza Libertad',
      eng: 'park',
      lessonNumber: 1,
    ),

    // Unit 2: Talk to Locals.
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'Diin ang Jaro Plaza?',
      eng: 'Where is Jaro Plaza?',
    ),
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'Ano nga jeep sakyan ko?',
      eng: 'What jeepney should I take?',
    ),
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'Jeep',
      eng: 'Jeepney',
      imagePath:
          'assets/images/level_game/unit 1/image_choice/transportation/Jeep.png',
    ),
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'Bangka',
      eng: 'Boat',
      imagePath:
          'assets/images/level_game/unit 1/image_choice/transportation/Bangka.png',
    ),
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'Eroplano',
      eng: 'Airplane',
      imagePath:
          'assets/images/level_game/unit 1/image_choice/transportation/Eroplano.png',
    ),
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'Traysikad',
      eng: 'Pedicab',
      imagePath:
          'assets/images/level_game/unit 1/image_choice/transportation/Traysikad.png',
    ),
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'Tagpila ang mangga?',
      eng: 'How much are the mangoes?',
      missingSentence: 'Tagpila ang ___?',
      missingAnswer: 'mangga',
    ),
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'Mangga',
      eng: 'Mango',
    ),
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'Diin ang merkado?',
      eng: 'Where is the market?',
    ),
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'Merkado',
      eng: 'Market',
    ),
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'Diin ang terminal?',
      eng: 'Where is the terminal?',
    ),
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'Terminal',
      eng: 'Terminal',
    ),
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'Pakadto ini sa CPU?',
      eng: 'Is this going to CPU?',
    ),
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'Pila ang plete?',
      eng: 'How much is the fare?',
      missingSentence: 'Pila ang ___?',
      missingAnswer: 'plete',
    ),
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'Plete',
      eng: 'Fare',
    ),
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'Lugar lang',
      eng: 'Please stop here',
    ),
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'Mabakal ako sini',
      eng: 'I will buy this',
    ),
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'Mahal ini?',
      eng: 'Is this expensive?',
    ),
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'May lapit nga tindahan?',
      eng: 'Is there a nearby store?',
    ),
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'Tindahan',
      eng: 'Store',
    ),
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'Diin ang CR?',
      eng: 'Where is the restroom?',
    ),
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'Pwede mo ako buligan?',
      eng: 'Can you help me?',
      wordMeanings: {
        'Pwede': 'can / may / possible',
        'mo': 'you / your',
        'ako': 'me / I',
        'buligan': 'help',
      },
    ),
    LessonTerm(
      unitNumber: 2,
      unitTitle: 'Talk to Locals',
      gradeLevel: 2,
      hil: 'Buligi ako palihog',
      eng: 'Help me please',
    ),

    // Unit 3: Conversation with Friends.
    LessonTerm(
      unitNumber: 3,
      unitTitle: 'Conversation with Friends',
      gradeLevel: 2,
      hil: 'Nabatian mo ang natabo sa school?',
      eng: 'Have you heard what happened at school?',
    ),
    LessonTerm(
      unitNumber: 3,
      unitTitle: 'Conversation with Friends',
      gradeLevel: 2,
      hil: 'Ginahulat ta ka',
      eng: "I'm waiting for you",
    ),
    LessonTerm(
      unitNumber: 3,
      unitTitle: 'Conversation with Friends',
      gradeLevel: 2,
      hil: 'Kadto na ta',
      eng: "Let's go",
    ),
    LessonTerm(
      unitNumber: 3,
      unitTitle: 'Conversation with Friends',
      gradeLevel: 2,
      hil: 'Kadto',
      eng: 'Go',
    ),
    LessonTerm(
      unitNumber: 3,
      unitTitle: 'Conversation with Friends',
      gradeLevel: 2,
      hil: 'Ari na ko',
      eng: "I'm here",
    ),
    LessonTerm(
      unitNumber: 3,
      unitTitle: 'Conversation with Friends',
      gradeLevel: 2,
      hil: 'Diin ka?',
      eng: 'Where are you?',
    ),
    LessonTerm(
      unitNumber: 3,
      unitTitle: 'Conversation with Friends',
      gradeLevel: 2,
      hil: 'Makadto ka?',
      eng: 'Are you coming?',
    ),
    LessonTerm(
      unitNumber: 3,
      unitTitle: 'Conversation with Friends',
      gradeLevel: 2,
      hil: 'Mangaon ta',
      eng: "Let's eat",
    ),
    LessonTerm(
      unitNumber: 3,
      unitTitle: 'Conversation with Friends',
      gradeLevel: 2,
      hil: 'Mauna ako',
      eng: "I'll go first",
    ),
    LessonTerm(
      unitNumber: 3,
      unitTitle: 'Conversation with Friends',
      gradeLevel: 2,
      hil: 'Hulata ko',
      eng: 'Wait for me',
      missingSentence: '___ ko.',
      missingAnswer: 'Hulata',
    ),
    LessonTerm(
      unitNumber: 3,
      unitTitle: 'Conversation with Friends',
      gradeLevel: 2,
      hil: 'Hulat',
      eng: 'Wait',
    ),
    LessonTerm(
      unitNumber: 3,
      unitTitle: 'Conversation with Friends',
      gradeLevel: 2,
      hil: 'Katawa man na',
      eng: "That's funny",
    ),
    LessonTerm(
      unitNumber: 3,
      unitTitle: 'Conversation with Friends',
      gradeLevel: 2,
      hil: 'Katawa',
      eng: 'Funny',
    ),
    LessonTerm(
      unitNumber: 3,
      unitTitle: 'Conversation with Friends',
      gradeLevel: 2,
      hil: 'Namiss ta ka',
      eng: 'I miss you',
    ),
    LessonTerm(
      unitNumber: 3,
      unitTitle: 'Conversation with Friends',
      gradeLevel: 2,
      hil: 'Kitaay ta karon',
      eng: "Let's meet later",
    ),
    LessonTerm(
      unitNumber: 3,
      unitTitle: 'Conversation with Friends',
      gradeLevel: 2,
      hil: 'Ano ginahimo mo?',
      eng: 'What are you doing?',
    ),
    LessonTerm(
      unitNumber: 3,
      unitTitle: 'Conversation with Friends',
      gradeLevel: 2,
      hil: 'Busy ako',
      eng: "I'm busy",
    ),
    LessonTerm(
      unitNumber: 3,
      unitTitle: 'Conversation with Friends',
      gradeLevel: 2,
      hil: 'Busy',
      eng: 'Busy',
    ),
    LessonTerm(
      unitNumber: 3,
      unitTitle: 'Conversation with Friends',
      gradeLevel: 2,
      hil: 'Chat-i ko karon',
      eng: 'Message me later',
    ),
    LessonTerm(
      unitNumber: 3,
      unitTitle: 'Conversation with Friends',
      gradeLevel: 2,
      hil: 'Chat',
      eng: 'Message',
    ),

    // Unit 4: Family is Love.
    LessonTerm(
      unitNumber: 4,
      unitTitle: 'Family is Love',
      gradeLevel: 3,
      hil: 'Nanay',
      eng: 'Mother',
      imagePath:
          'assets/images/level_game/unit 1/image_choice/people/mother.png',
    ),
    LessonTerm(
      unitNumber: 4,
      unitTitle: 'Family is Love',
      gradeLevel: 3,
      hil: 'Tatay',
      eng: 'Father',
      imagePath:
          'assets/images/level_game/unit 1/image_choice/people/father.png',
    ),
    LessonTerm(
      unitNumber: 4,
      unitTitle: 'Family is Love',
      gradeLevel: 3,
      hil: 'Utod',
      eng: 'Sibling',
    ),
    LessonTerm(
      unitNumber: 4,
      unitTitle: 'Family is Love',
      gradeLevel: 3,
      hil: 'Lola',
      eng: 'Grandmother',
      imagePath:
          'assets/images/level_game/unit 1/image_choice/people/grandmother.png',
    ),
    LessonTerm(
      unitNumber: 4,
      unitTitle: 'Family is Love',
      gradeLevel: 3,
      hil: 'Lolo',
      eng: 'Grandfather',
      imagePath:
          'assets/images/level_game/unit 1/image_choice/people/grandfather.png',
    ),
    LessonTerm(
      unitNumber: 4,
      unitTitle: 'Family is Love',
      gradeLevel: 3,
      hil: 'Palangga ko ang akon pamilya',
      eng: 'I love my family',
    ),
    LessonTerm(
      unitNumber: 4,
      unitTitle: 'Family is Love',
      gradeLevel: 3,
      hil: 'Diin si nanay?',
      eng: 'Where is mother?',
    ),
    LessonTerm(
      unitNumber: 4,
      unitTitle: 'Family is Love',
      gradeLevel: 3,
      hil: 'Nagaluto si tatay',
      eng: 'Father is cooking',
    ),
    LessonTerm(
      unitNumber: 4,
      unitTitle: 'Family is Love',
      gradeLevel: 3,
      hil: 'Nagakatulog ang akon utod',
      eng: 'My sibling is sleeping',
    ),
    LessonTerm(
      unitNumber: 4,
      unitTitle: 'Family is Love',
      gradeLevel: 3,
      hil: 'Buotan si lola',
      eng: 'Grandmother is kind',
    ),
    LessonTerm(
      unitNumber: 4,
      unitTitle: 'Family is Love',
      gradeLevel: 3,
      hil: 'Mangaon ta tanan',
      eng: "Let's eat together",
    ),
    LessonTerm(
      unitNumber: 4,
      unitTitle: 'Family is Love',
      gradeLevel: 3,
      hil: 'Halong',
      eng: 'Take care',
    ),
    LessonTerm(
      unitNumber: 4,
      unitTitle: 'Family is Love',
      gradeLevel: 3,
      hil: 'Namiss ko ang akon pamilya',
      eng: 'I miss my family',
    ),
    LessonTerm(
      unitNumber: 4,
      unitTitle: 'Family is Love',
      gradeLevel: 3,
      hil: 'Malipayon ang amon balay',
      eng: 'Our house is happy',
    ),
    LessonTerm(
      unitNumber: 4,
      unitTitle: 'Family is Love',
      gradeLevel: 3,
      hil: 'Buligi ang imo utod',
      eng: 'Help your sibling',
    ),

    // Unit 5: Daily Life.
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Nagmata ako sang aga.',
      eng: 'I woke up in the morning.',
      missingSentence: 'Nagmata ako sang ___.',
      missingAnswer: 'aga',
      choices: ['aga', 'gab-i', 'init', 'basa'],
      wordMeanings: {'Nagmata': 'woke up', 'ako': 'I / me', 'sang': 'in / of'},
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Gina lagas ako sang ido.',
      eng: 'I am being chased by a dog.',
      missingSentence: '____ ____ ako sang ____.',
      missingAnswer: 'gina lagas ido',
      choices: ['gina', 'lagas', 'ido', 'basa', 'kaon', 'tubig'],
      imagePath:
          'assets/images/level_game/unit 1/complete_the_sentence/gina-lagas-ako-sang-ido.png',
      wordMeanings: {'ako': 'I / me', 'sang': 'by / of'},
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Nagakaon ako',
      eng: 'I am eating',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Nagabasa ako',
      eng: 'I am reading',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Basa',
      eng: 'Read',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Nagakadto ako sa eskwelahan',
      eng: 'I am going to school',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Nagainom ako sang tubig',
      eng: 'I am drinking water',
      missingSentence: 'Nagainom ako sang ___.',
      missingAnswer: 'tubig',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Tubig',
      eng: 'Water',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Nagakatulog ako',
      eng: 'I am sleeping',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Nagatuon ako',
      eng: 'I am studying',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Nagapanglaba ako',
      eng: 'I am washing clothes',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Nagatinlo ako sang balay',
      eng: 'I am cleaning the house',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Aga ako nagbugtaw',
      eng: 'I woke up early',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Mapauli ako',
      eng: 'I will go home',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'May libro ako',
      eng: 'I have a book',
      missingSentence: 'May ___ ako.',
      missingAnswer: 'libro',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Libro',
      eng: 'Book',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Ido',
      eng: 'Dog',
      imagePath: 'assets/images/level_game/animal/dog.png',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Kuring',
      eng: 'Cat',
      imagePath: 'assets/images/level_game/animal/cat.png',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Pispis',
      eng: 'Bird',
      imagePath: 'assets/images/level_game/animal/bird.png',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Isda',
      eng: 'Fish',
      imagePath: 'assets/images/level_game/animal/fish.png',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Kinahanglan ko sang tubig',
      eng: 'I need water',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Kapoy ako',
      eng: 'I am tired',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Gutom ako',
      eng: 'I am hungry',
    ),
    LessonTerm(
      unitNumber: 5,
      unitTitle: 'Daily Life',
      gradeLevel: 3,
      hil: 'Nalipay ako',
      eng: 'I am happy',
    ),

    // Unit 6: Community.
    LessonTerm(
      unitNumber: 6,
      unitTitle: 'Community',
      gradeLevel: 3,
      hil: 'Barangay',
      eng: 'Barangay',
    ),
    LessonTerm(
      unitNumber: 6,
      unitTitle: 'Community',
      gradeLevel: 3,
      hil: 'Eskwelahan',
      eng: 'School',
    ),
    LessonTerm(
      unitNumber: 6,
      unitTitle: 'Community',
      gradeLevel: 3,
      hil: 'Simbahan',
      eng: 'Church',
    ),
    LessonTerm(
      unitNumber: 6,
      unitTitle: 'Community',
      gradeLevel: 3,
      hil: 'Ospital',
      eng: 'Hospital',
    ),
    LessonTerm(
      unitNumber: 6,
      unitTitle: 'Community',
      gradeLevel: 3,
      hil: 'Merkado',
      eng: 'Market',
    ),
    LessonTerm(
      unitNumber: 6,
      unitTitle: 'Community',
      gradeLevel: 3,
      hil: 'Istasyon sang pulis',
      eng: 'Police station',
    ),
    LessonTerm(
      unitNumber: 6,
      unitTitle: 'Community',
      gradeLevel: 3,
      hil: 'Istasyon sang bombero',
      eng: 'Fire station',
    ),
    LessonTerm(
      unitNumber: 6,
      unitTitle: 'Community',
      gradeLevel: 3,
      hil: 'Manunudlo',
      eng: 'Teacher',
    ),
    LessonTerm(
      unitNumber: 6,
      unitTitle: 'Community',
      gradeLevel: 3,
      hil: 'Nars',
      eng: 'Nurse',
    ),
    LessonTerm(
      unitNumber: 6,
      unitTitle: 'Community',
      gradeLevel: 3,
      hil: 'Doktor',
      eng: 'Doctor',
    ),
    LessonTerm(
      unitNumber: 6,
      unitTitle: 'Community',
      gradeLevel: 3,
      hil: 'Kapitan',
      eng: 'Barangay captain',
    ),
    LessonTerm(
      unitNumber: 6,
      unitTitle: 'Community',
      gradeLevel: 3,
      hil: 'Tinlo ang komunidad',
      eng: 'The community is clean',
    ),
    LessonTerm(
      unitNumber: 6,
      unitTitle: 'Community',
      gradeLevel: 3,
      hil: 'Buligi ang komunidad',
      eng: 'Help the community',
    ),
    LessonTerm(
      unitNumber: 6,
      unitTitle: 'Community',
      gradeLevel: 3,
      hil: 'Diin ang ospital?',
      eng: 'Where is the hospital?',
    ),
    LessonTerm(
      unitNumber: 6,
      unitTitle: 'Community',
      gradeLevel: 3,
      hil: 'Buotan ang manunudlo',
      eng: 'The teacher is kind',
    ),
    LessonTerm(
      unitNumber: 6,
      unitTitle: 'Community',
      gradeLevel: 3,
      hil: 'Nagabulig ang nars sa mga tawo',
      eng: 'The nurse helps people',
    ),
    LessonTerm(
      unitNumber: 6,
      unitTitle: 'Community',
      gradeLevel: 3,
      hil: 'Tipigan ta nga tinlo ang lugar',
      eng: "Let's keep the place clean",
    ),
  ];

  static LessonLevelContent contentForLevel(int level) {
    if (_isGradeTwoUnitOneTextbookLevel(level)) {
      return _gradeTwoUnitOneContentForLevel(level);
    }

    if (AppData.selectedGradeLevel == GradeLevel.grade3) {
      return _gradeThreePdfContentForLevel(level);
    }

    final dataset = _activeGradeDataset;
    final unit = unitForLevel(level);
    final unitTitle = unitTitles[unit] ?? 'Hiligaynon';
    final levelTerms = _nonScenarioTerms(_termsForLocalLesson(level));
    final focusTerms = levelTerms.take(4).toList();
    final focusLabels = focusTerms.map((term) => term.hil).toList();
    final focusWords = _joinQuoted(focusLabels);

    return LessonLevelContent(
      title: unitTitle,
      storyTitle: 'Listen and Learn',
      story: _applyGradeTemplate(
        dataset.storyTemplate,
        unitTitle: unitTitle,
        focusWords: focusWords,
      ),
      shortLesson: _applyGradeTemplate(
        dataset.lessonTemplate,
        unitTitle: unitTitle,
        focusWords: focusWords,
      ),
      examples: focusTerms
          .map((term) => LessonExample(hiligaynon: term.hil, english: term.eng))
          .toList(),
    );
  }

  static bool _isGradeTwoUnitOneTextbookLevel(int level) {
    if (AppData.selectedGradeLevel != GradeLevel.grade2) return false;
    if (unitForLevel(level) != 1) return false;
    final localLevel = ((level - 1) % AppData.unitLevels) + 1;
    return localLevel <= 5;
  }

  static LessonLevelContent _gradeTwoUnitOneContentForLevel(int level) {
    final localLevel = ((level - 1) % AppData.unitLevels) + 1;
    return switch (localLevel) {
      1 => const LessonLevelContent(
        title: 'Pangalan',
        storyTitle: 'Dalayawon',
        story:
            'Si Rina isa ka maalam nga bata. Samtang nagapauli siya, nakita niya ang iya mga kasilingan nga nagapaninlo sa Kalye Malinong, nagapananum sang bulak, kag nagabulig sa barangay nga wala sing bayad. Ginadayaw ni Rina ang ila pagbulig.',
        shortLesson:
            'Ang pangalan nagatuhoy sa ngalan sang tawo, butang, lugar, sapat, kag hitabo. Sa istorya, makakita kita sang mga ngalan pareho sang Rina, kasilingan, Kalye Malinong, bulak, kag pagpaninlo.',
        concepts: [
          LessonConceptCard(
            title: 'Pangalan',
            hiligaynon: 'Ngalan sang tawo, butang, lugar, sapat, ukon hitabo.',
            english: 'A noun names a person, thing, place, animal, or event.',
          ),
          LessonConceptCard(
            title: 'Tawo',
            hiligaynon: 'Pangalan sang tawo sa istorya ukon palibot.',
            english: 'Names a person.',
          ),
          LessonConceptCard(
            title: 'Lugar',
            hiligaynon: 'Pangalan sang lugar nga ginakadtuan ukon ginahambal.',
            english: 'Names a place.',
          ),
        ],
        examples: [
          LessonExample(
            category: 'Tawo',
            hiligaynon: 'Rina',
            english: 'child',
            note: 'Pangalan sang tawo',
          ),
          LessonExample(
            category: 'Butang',
            hiligaynon: 'lapis',
            english: 'pencil',
            note: 'Pangalan sang butang',
          ),
          LessonExample(
            category: 'Sapat',
            hiligaynon: 'kuring',
            english: 'cat',
            note: 'Pangalan sang sapat',
          ),
          LessonExample(
            category: 'Lugar',
            hiligaynon: 'parke',
            english: 'park',
            note: 'Pangalan sang lugar',
          ),
        ],
      ),
      2 => const LessonLevelContent(
        title: 'Pat-od kag Kinaandan nga Pangalan sang Tawo',
        storyTitle: 'Masarangan Ko Man Ini!',
        story:
            'Aga pa nagbugtaw si Rina kag ginpangita niya si Nanay Rowena. Nakita niya ang iya iloy kag mga kasilingan nga nagahanda para sa proyekto ni Mayor Basilio. Luyag man ni Rina magbulig.',
        shortLesson:
            'Ang pat-od nga pangalan nagatudlo sang eksakto nga ngalan sang tawo, pareho sang Rina ukon Nanay Rowena. Ang kinaandan nga pangalan nagatudlo sang ordinaryo nga ngalan, pareho sang bata, iloy, mayor, kag manunudlo.',
        concepts: [
          LessonConceptCard(
            title: 'Pat-od nga Pangalan',
            hiligaynon: 'Pinasahi ukon eksakto nga ngalan sang tawo.',
            english: 'A proper noun names one specific person.',
          ),
          LessonConceptCard(
            title: 'Kinaandan nga Pangalan',
            hiligaynon: 'Ordinaryo nga ngalan sang tawo.',
            english: 'A common noun names a kind of person.',
          ),
        ],
        examples: [
          LessonExample(
            category: 'Pat-od',
            hiligaynon: 'Rina',
            english: 'Rina',
            note: 'Eksakto nga ngalan',
          ),
          LessonExample(
            category: 'Pat-od',
            hiligaynon: 'Mayor Basilio',
            english: 'Mayor Basilio',
            note: 'Eksakto nga ngalan',
          ),
          LessonExample(
            category: 'Kinaandan',
            hiligaynon: 'bata',
            english: 'child',
            note: 'Ordinaryo nga ngalan',
          ),
          LessonExample(
            category: 'Kinaandan',
            hiligaynon: 'manunudlo',
            english: 'teacher',
            note: 'Ordinaryo nga ngalan',
          ),
        ],
      ),
      3 => const LessonLevelContent(
        title: 'Pat-od kag Kinaandan nga Pangalan sang Lugar',
        storyTitle: 'Mga Lugar sa Amon Komunidad',
        story:
            'Gintan-aw sang klase ni Rina ang mapa sang ila lugar. Nakita nila ang mga tanda, kalye, merkado, suba, kag mga bantog nga lugar pareho sang Iloilo River, Boracay, kag Plaza Libertad.',
        shortLesson:
            'Ang pat-od nga pangalan sang lugar amo ang eksakto nga ngalan sang isa ka lugar kag nagasugod sa daku nga letra. Ang kinaandan nga pangalan sang lugar amo ang ordinaryo nga ngalan pareho sang merkado, suba, ospital, ukon simbahan.',
        concepts: [
          LessonConceptCard(
            title: 'Pat-od nga Lugar',
            hiligaynon: 'Eksakto nga ngalan sang lugar.',
            english: 'A proper place noun names one specific place.',
          ),
          LessonConceptCard(
            title: 'Kinaandan nga Lugar',
            hiligaynon: 'Ordinaryo nga ngalan sang lugar.',
            english: 'A common place noun names a kind of place.',
          ),
          LessonConceptCard(
            title: 'Tanda',
            hiligaynon: 'Direksyon ukon simbolo nga nagabulig magtultol.',
            english: 'A sign helps people find a place.',
          ),
        ],
        examples: [
          LessonExample(
            category: 'Pat-od',
            hiligaynon: 'Iloilo River',
            english: 'river',
            note: 'Eksakto nga lugar',
          ),
          LessonExample(
            category: 'Pat-od',
            hiligaynon: 'Boracay',
            english: 'beach place',
            note: 'Eksakto nga lugar',
          ),
          LessonExample(
            category: 'Kinaandan',
            hiligaynon: 'merkado',
            english: 'market',
            note: 'Ordinaryo nga lugar',
          ),
          LessonExample(
            category: 'Kinaandan',
            hiligaynon: 'simbahan',
            english: 'church',
            note: 'Ordinaryo nga lugar',
          ),
        ],
      ),
      4 => const LessonLevelContent(
        title: 'Pat-od kag Kinaandan nga Pangalan sang Hitabo',
        storyTitle: 'Salamat sa Kalendaryo',
        story:
            'Ginamit ni Ayessa ang kalendaryo agud mahibalu-an ang mga importante nga adlaw kag kahiwatan sa bug-os nga tuig. Nakita niya ang Bag-ong Tuig, Adlaw sang Kahilwayan, Adlaw sang Paskwa, kag Rizal Day.',
        shortLesson:
            'Ang pat-od nga pangalan sang hitabo amo ang eksakto nga ngalan sang okasyon ukon adlaw. Ang kinaandan nga pangalan sang hitabo amo ang ordinaryo nga ngalan pareho sang kahiwatan, pista, ukon adlaw sang paghanduraw.',
        concepts: [
          LessonConceptCard(
            title: 'Kalendaryo',
            hiligaynon: 'Listahan sang adlaw, petsa, kag okasyon.',
            english: 'A calendar shows days, dates, and events.',
          ),
          LessonConceptCard(
            title: 'Kahiwatan',
            hiligaynon: 'Buluhaton nga may kasadya ukon importansya.',
            english: 'An event or celebration.',
          ),
          LessonConceptCard(
            title: 'Pat-od nga Hitabo',
            hiligaynon: 'Eksakto nga ngalan sang isa ka hitabo.',
            english: 'A proper event noun names one specific event.',
          ),
        ],
        examples: [
          LessonExample(
            category: 'Pat-od',
            hiligaynon: 'Bag-ong Tuig',
            english: 'New Year',
            note: 'Enero 1',
          ),
          LessonExample(
            category: 'Pat-od',
            hiligaynon: 'Adlaw sang Kahilwayan',
            english: 'Independence Day',
            note: 'Hunyo 12',
          ),
          LessonExample(
            category: 'Kinaandan',
            hiligaynon: 'kahiwatan',
            english: 'event',
            note: 'Ordinaryo nga ngalan',
          ),
          LessonExample(
            category: 'Kinaandan',
            hiligaynon: 'pista',
            english: 'festival',
            note: 'Ordinaryo nga ngalan',
          ),
        ],
      ),
      _ => const LessonLevelContent(
        title: 'Pagbinalaybay',
        storyTitle: 'Baganihan sang Kabuhi Ko',
        story:
            'Ang binalaybay nagahambal sang handum, kapisan, kag pagserbisyo. Ginmitlang si Gat Jose Rizal bilang baganihan nga nagtinguha para sa Pilipinas, kag ginpakita man ang handum nga mangin manunudlo.',
        shortLesson:
            'Sa pagbinalaybay, mahimo naton makilala ang mga pangalan nga pat-od kag kinaandan. Ang Dr. Jose Rizal kag Pilipinas mga pat-od nga pangalan. Ang baganihan, manunudlo, pulis, kag pungsod mga kinaandan nga pangalan.',
        concepts: [
          LessonConceptCard(
            title: 'Binalaybay',
            hiligaynon: 'Sinulat nga may ritmo kag pagbati.',
            english: 'A poem uses rhythm and feeling.',
          ),
          LessonConceptCard(
            title: 'Baganihan',
            hiligaynon: 'Tawo nga nagaserbisyo para sa kaayuhan sang iban.',
            english: 'A hero serves others bravely.',
          ),
          LessonConceptCard(
            title: 'Sakripisyo',
            hiligaynon: 'Paghalad ukon pagbuhat para sa kaayuhan sang iban.',
            english: 'A sacrifice is giving something for others.',
          ),
        ],
        examples: [
          LessonExample(
            category: 'Pat-od',
            hiligaynon: 'Dr. Jose Rizal',
            english: 'national hero',
            note: 'Eksakto nga ngalan sang tawo',
          ),
          LessonExample(
            category: 'Pat-od',
            hiligaynon: 'Pilipinas',
            english: 'Philippines',
            note: 'Eksakto nga ngalan sang lugar',
          ),
          LessonExample(
            category: 'Kinaandan',
            hiligaynon: 'baganihan',
            english: 'hero',
            note: 'Ordinaryo nga ngalan',
          ),
          LessonExample(
            category: 'Kinaandan',
            hiligaynon: 'manunudlo',
            english: 'teacher',
            note: 'Ordinaryo nga ngalan',
          ),
        ],
      ),
    };
  }

  static LessonLevelContent _gradeThreePdfContentForLevel(int level) {
    final localLevel = ((level - 1) % AppData.unitLevels) + 1;
    if (localLevel == 2) {
      return const LessonLevelContent(
        title: 'Count Nouns and Mass Nouns',
        storyTitle: 'Sa Merkado sang Pamilya',
        story:
            'Nag-upod si Rina sa iya nanay sa merkado. Nagbakal sila sang tatlo ka mansanas, duha ka libro, bugas, tubig, kag asukar para sa ila panimalay.',
        shortLesson:
            'Ang count noun amo ang pangalan sang butang nga maisip naton, pareho sang mansanas kag libro. Ang mass noun amo ang pangalan sang butang nga indi dali maisip isa-isa, pareho sang tubig, bugas, kag asukar.',
        concepts: [
          LessonConceptCard(
            title: 'Count Noun',
            hiligaynon: 'Pangalan nga maisip',
            english: 'Names things we can count one by one.',
          ),
          LessonConceptCard(
            title: 'Mass Noun',
            hiligaynon: 'Pangalan nga indi maisip isa-isa',
            english: 'Names things measured as a group or amount.',
          ),
        ],
        examples: [
          LessonExample(
            category: 'Count Noun',
            hiligaynon: 'mansanas',
            english: 'apple',
            note: 'isa, duha, tatlo ka mansanas',
          ),
          LessonExample(
            category: 'Count Noun',
            hiligaynon: 'libro',
            english: 'book',
            note: 'isa ka libro',
          ),
          LessonExample(
            category: 'Mass Noun',
            hiligaynon: 'tubig',
            english: 'water',
            note: 'isa ka baso nga tubig',
          ),
          LessonExample(
            category: 'Mass Noun',
            hiligaynon: 'bugas',
            english: 'rice',
            note: 'isa ka kilo nga bugas',
          ),
        ],
      );
    }

    return const LessonLevelContent(
      title: 'Ako kag ang Akon Pamilya',
      storyTitle: 'Dalayawon nga Bulig',
      story:
          'Si Rina isa ka bata nga masinulundon sa iya pamilya. Upod sang iya mga kaeskwela, nagtinlo sila sang dalan, nagtubo sang mga bulak, kag nagbulig sa pagpaninlo sang ila barangay.',
      shortLesson:
          'Ang pangalan, ukon noun, amo ang ngalan sang tawo, lugar, sapat, butang, kag hitabo. Sa istorya, ginatan-aw man naton ang katawhan, halamtangan, kag hinabo.',
      concepts: [
        LessonConceptCard(
          title: 'Pangalan',
          hiligaynon: 'Ngalan sang tawo, lugar, sapat, butang, ukon hitabo.',
          english: 'A noun names a person, place, animal, thing, or event.',
        ),
        LessonConceptCard(
          title: 'Katawhan',
          hiligaynon: 'Mga tawo ukon karakter sa istorya.',
          english: 'The characters in a story.',
        ),
        LessonConceptCard(
          title: 'Halamtangan',
          hiligaynon: 'Lugar kag tion nga natabo ang istorya.',
          english: 'The setting, or where and when the story happens.',
        ),
        LessonConceptCard(
          title: 'Hinabo',
          hiligaynon: 'Mga natabo sa istorya.',
          english: 'The events that happen in a story.',
        ),
      ],
      examples: [
        LessonExample(
          category: 'Tawo',
          hiligaynon: 'Rina',
          english: 'child',
          note: 'Pat-od nga pangalan',
        ),
        LessonExample(
          category: 'Tawo',
          hiligaynon: 'Nanay Rowena',
          english: 'mother',
          note: 'Pat-od nga pangalan',
        ),
        LessonExample(
          category: 'Lugar',
          hiligaynon: 'Iloilo River',
          english: 'river',
          note: 'Ngalan sang lugar',
        ),
        LessonExample(
          category: 'Lugar',
          hiligaynon: 'Plaza Libertad',
          english: 'park',
          note: 'Ngalan sang lugar',
        ),
        LessonExample(
          category: 'Kinaandan nga Pangalan',
          hiligaynon: 'bata',
          english: 'child',
          note: 'Tanan nga bata',
        ),
        LessonExample(
          category: 'Kinaandan nga Pangalan',
          hiligaynon: 'suba',
          english: 'river',
          note: 'Tanan nga suba',
        ),
      ],
    );
  }

  static List<LessonQuestion> questionsForLevel(int level) {
    final rng = math.Random(level + AppData.selectedGradeLevel.number * 1000);
    if (AppData.selectedGradeLevel == GradeLevel.grade3 && level == 1) {
      return _gradeThreePdfQuestionSet(rng);
    }

    if (_isGradeTwoUnitOneTextbookLevel(level)) {
      return _gradeTwoUnitOneQuestionSet(level);
    }

    if (level == 1) {
      return _unitOneLevelOneQuestionSet(rng);
    }

    final unit = unitForLevel(level);
    final unitTerms = termsForUnit(unit);
    final scopedUnitTerms = _termsForUnitLessonScope(level);
    final levelTerms = _termsForLocalLesson(level);
    final practiceTerms = _nonScenarioTerms(levelTerms);
    final practiceUnitTerms = _nonScenarioTerms(scopedUnitTerms);

    // Unit 1 Level 1 is the polished showcase level and gets the complete
    // activity mix requested for demo/testing. Other levels use the normal
    // flexible generator so image questions are not forced into every unit.
    final isShowcaseLevel = level == 1;
    final questions = <LessonQuestion>[
      for (var index = 0; index < 3; index++)
        _translationChoiceQuestion(
          term: practiceTerms[(level + index) % practiceTerms.length],
          englishToHiligaynon: index.isEven,
          pool: practiceTerms,
          rng: rng,
        ),
      for (var index = 0; index < 3; index++)
        _arrangeWordsQuestion(level + index, practiceTerms, rng),
      for (var index = 0; index < 2; index++)
        _matchingQuestion(practiceTerms, practiceUnitTerms, level + index * 3),
      for (var index = 0; index < 2; index++)
        _missingWordQuestion(
          level + index,
          levelTerms,
          rng,
          unitFallbackTerms: scopedUnitTerms,
        ),
    ];
    final firstImageQuestion = _imageChoiceQuestion(
      levelTerms,
      rng,
      seed: level,
      allowGlobalFallback: isShowcaseLevel,
    );
    final secondImageQuestion = _imageChoiceQuestion(
      levelTerms,
      rng,
      seed: level + 7,
      avoidAnswer: firstImageQuestion?.answer,
      allowGlobalFallback: isShowcaseLevel,
    );
    if (firstImageQuestion != null) questions.add(firstImageQuestion);
    if (secondImageQuestion != null) questions.add(secondImageQuestion);

    if (isShowcaseLevel) {
      return _completeShowcaseQuestionSet(
        questions,
        level: level,
        levelTerms: practiceTerms,
        unitTerms: practiceUnitTerms,
        scenarioTerms: levelTerms,
        scenarioUnitTerms: unitTerms,
        rng: rng,
      );
    }

    return _completeFlexibleQuestionSet(
      questions,
      level: level,
      levelTerms: practiceTerms,
      unitTerms: practiceUnitTerms,
      scenarioTerms: levelTerms,
      scenarioUnitTerms: scopedUnitTerms,
      rng: rng,
    );
  }

  static String lessonTitleForLevel(int level) {
    return contentForLevel(level).title;
  }

  static List<LessonQuestion> _unitOneLevelOneQuestionSet(math.Random rng) {
    // Unit 1 Level 1 is the showcase level, so it uses a fixed set from the
    // lesson plan instead of the flexible generator used by later levels.
    final levelTerms = _termsForLocalLesson(1);
    LessonTerm term(String hil) =>
        levelTerms.firstWhere((term) => term.hil == hil);
    List<String> shuffled(List<String> values) => values;

    final familyChoices = [
      term('Nanay'),
      term('Tatay'),
      term('Lola'),
      term('Lolo'),
    ];
    final transportationChoices = [
      term('Jeep'),
      term('Bangka'),
      term('Eroplano'),
      term('Traysikad'),
    ];

    final questions = [
      LessonQuestion.translationChoice(
        prompt: 'Which of these is "Yes"?',
        answer: 'Huo',
        choices: shuffled(['Huo', 'Indi', 'Palihog', 'Maayong aga']),
        targetPhrase: 'Yes',
        targetMeaning: 'Huo',
        directionLabel: 'English to Hiligaynon',
      ),
      LessonQuestion.translationChoice(
        prompt: 'Which of these is "Please"?',
        answer: 'Palihog',
        choices: shuffled(['Palihog', 'Huo', 'Indi', 'Kamusta ka?']),
        targetPhrase: 'Please',
        targetMeaning: 'Palihog',
        directionLabel: 'English to Hiligaynon',
      ),
      LessonQuestion.translationChoice(
        prompt: 'Which of these is "How are you?"',
        answer: 'Kamusta ka?',
        choices: shuffled(['Kamusta ka?', 'Maayong aga', 'Palihog', 'Huo']),
        targetPhrase: 'How are you?',
        targetMeaning: 'Kamusta ka?',
        directionLabel: 'English to Hiligaynon',
      ),
      LessonQuestion.translationChoice(
        prompt: 'Which of these is "Good morning"?',
        answer: 'Maayong aga',
        choices: shuffled(['Maayong aga', 'Kamusta ka?', 'Palihog', 'Indi']),
        targetPhrase: 'Good morning',
        targetMeaning: 'Maayong aga',
        directionLabel: 'English to Hiligaynon',
      ),
      LessonQuestion.translationChoice(
        prompt: 'Which of these is "No"?',
        answer: 'Indi',
        choices: shuffled(['Indi', 'Huo', 'Palihog', 'Maayong aga']),
        targetPhrase: 'No',
        targetMeaning: 'Indi',
        directionLabel: 'English to Hiligaynon',
      ),
      LessonQuestion.arrangeWords(
        prompt: 'Arrange the words to say: "How are you?"',
        answer: 'Kamusta ka?',
        sentenceWords: shuffled(['Kamusta', 'ka?']),
        targetPhrase: 'How are you?',
        targetMeaning: 'Kamusta ka?',
        directionLabel: 'English to Hiligaynon',
      ),
      LessonQuestion.arrangeWords(
        prompt: 'Arrange the words to say: "It\'s really hot today"',
        answer: 'Grabe gid ya ang init subong',
        sentenceWords: shuffled([
          'Grabe',
          'gid',
          'ya',
          'ang',
          'init',
          'subong',
        ]),
        imagePath:
            'assets/images/level_game/unit 1/arrange-words/It\'s-really-hot-today.png',
        targetPhrase: "It's really hot today",
        targetMeaning: 'Grabe gid ya ang init subong',
        directionLabel: 'English to Hiligaynon',
      ),
      LessonQuestion.arrangeWords(
        prompt: 'Arrange the words to say: "Good morning, Josh! How are you?"',
        answer: 'Maayong aga, Josh! Kamusta ka?',
        sentenceWords: shuffled(['Maayong', 'aga,', 'Josh!', 'Kamusta', 'ka?']),
        imagePath:
            'assets/images/level_game/unit 1/arrange-words/good-morning-how-are-you.png',
        targetPhrase: 'Good morning, Josh! How are you?',
        targetMeaning: 'Maayong aga, Josh! Kamusta ka?',
        directionLabel: 'English to Hiligaynon',
      ),
      LessonQuestion.matching(
        prompt: 'Match each Hiligaynon word to English.',
        leftItems: ['Lamig', 'Init', 'Nanay', 'Tatay'],
        rightItems: shuffled(['Cold', 'Hot', 'Mother', 'Father']),
      ),
      LessonQuestion.matching(
        prompt: 'Match each Hiligaynon word to English.',
        leftItems: ['Jeep', 'Eroplano', 'Bangka', 'Traysikad'],
        rightItems: shuffled(['Jeepney', 'Airplane', 'Boat', 'Tricycle']),
      ),
      _fillBlankQuestion(
        term('Na basa akon bayo kay nag-ulan gulpi.'),
        levelTerms,
        rng,
      ),
      _fillBlankQuestion(term('Ga pila kami para mag bayad.'), levelTerms, rng),
      _fillBlankQuestion(term('Ga hulat ako sang jeep.'), levelTerms, rng),
      LessonQuestion.imageChoice(
        prompt: 'Which of these is "Mother"?',
        answer: 'Nanay',
        imageChoices: familyChoices,
        targetPhrase: 'Nanay',
        targetMeaning: 'Mother',
        directionLabel: 'Hiligaynon to English',
      ),
      LessonQuestion.imageChoice(
        prompt: 'Which of these is "Jeepney"?',
        answer: 'Jeep',
        imageChoices: transportationChoices,
        targetPhrase: 'Jeep',
        targetMeaning: 'Jeepney',
        directionLabel: 'Hiligaynon to English',
      ),
    ];

    return [
      questions[0],
      questions[1],
      questions[2],
      questions[5],
      questions[6],
      questions[8],
      questions[10],
      questions[11],
      questions[13],
      questions[14],
    ];
  }

  static List<LessonQuestion> _gradeTwoUnitOneQuestionSet(int level) {
    final localLevel = ((level - 1) % AppData.unitLevels) + 1;
    List<String> shuffled(List<String> values) => values;

    return switch (localLevel) {
      1 => [
        LessonQuestion.translationChoice(
          prompt:
              'Ano ang tawag sa ngalan sang tawo, butang, lugar, sapat, ukon hitabo?',
          answer: 'Pangalan',
          choices: shuffled(['Pangalan', 'Tanda', 'Kahiwatan', 'Sakripisyo']),
          targetPhrase: 'Pangalan',
          targetMeaning: 'Noun',
          directionLabel: 'Hiligaynon concept',
        ),
        LessonQuestion.translationChoice(
          prompt: 'Diin nga grupo nasakop ang "Rina"?',
          answer: 'Tawo',
          choices: shuffled(['Tawo', 'Lugar', 'Sapat', 'Hitabo']),
          targetPhrase: 'Rina',
          targetMeaning: 'Person',
          directionLabel: 'Noun category',
        ),
        LessonQuestion.translationChoice(
          prompt: 'Diin nga grupo nasakop ang "parke"?',
          answer: 'Lugar',
          choices: shuffled(['Butang', 'Lugar', 'Tawo', 'Sapat']),
          targetPhrase: 'parke',
          targetMeaning: 'Place',
          directionLabel: 'Noun category',
        ),
        LessonQuestion.arrangeWords(
          prompt: 'Ipahamtang ang mga pulong para mahimo ang ideya.',
          answer: 'Ang pangalan nagatudlo sang ngalan',
          sentenceWords: shuffled([
            'Ang',
            'pangalan',
            'nagatudlo',
            'sang',
            'ngalan',
          ]),
          targetPhrase: 'Ang pangalan nagatudlo sang ngalan',
          targetMeaning: 'A noun points to a name.',
          directionLabel: 'Hiligaynon sentence',
        ),
        LessonQuestion.arrangeWords(
          prompt: 'Ipahamtang ang mga pulong para mahimo ang sentence.',
          answer: 'Mabuot ang amon kasilingan',
          sentenceWords: shuffled(['Mabuot', 'ang', 'amon', 'kasilingan']),
          targetPhrase: 'Mabuot ang amon kasilingan',
          targetMeaning: 'Our neighbor is kind.',
          directionLabel: 'Hiligaynon sentence',
        ),
        LessonQuestion.matching(
          prompt: 'Ipares ang grupo sang pangalan kag kahulugan.',
          leftItems: ['Tawo', 'Butang', 'Lugar', 'Hitabo'],
          rightItems: shuffled(['Person', 'Thing', 'Place', 'Event']),
        ),
        LessonQuestion.matching(
          prompt: 'Ipares ang halimbawa kag kahulugan.',
          leftItems: ['Rina', 'Lapis', 'Parke', 'Pispis'],
          rightItems: shuffled(['Child', 'Pencil', 'Park', 'Bird']),
        ),
        LessonQuestion.fillBlank(
          prompt: 'Kompletoha: Ang ___ amo ang ngalan sang tawo ukon butang.',
          answer: 'pangalan',
          choices: shuffled(['pangalan', 'tanda', 'baganihan', 'kalendaryo']),
          targetPhrase: 'Ang pangalan amo ang ngalan sang tawo ukon butang.',
          targetMeaning: 'A noun is the name of a person or thing.',
          directionLabel: 'Fill in the blank',
        ),
        LessonQuestion.fillBlank(
          prompt: 'Kompletoha: Ang ___ isa ka pangalan sang lugar.',
          answer: 'parke',
          choices: shuffled(['parke', 'kuring', 'lapis', 'pispis']),
          targetPhrase: 'Ang parke isa ka pangalan sang lugar.',
          targetMeaning: 'Park is a place noun.',
          directionLabel: 'Fill in the blank',
        ),
        LessonQuestion.translationChoice(
          prompt: 'Ano ang kahulugan sang "kasilingan"?',
          answer: 'Neighbor',
          choices: shuffled(['Neighbor', 'Teacher', 'Calendar', 'Hero']),
          targetPhrase: 'Kasilingan',
          targetMeaning: 'Neighbor',
          directionLabel: 'Hiligaynon to English',
        ),
      ],
      2 => [
        LessonQuestion.translationChoice(
          prompt: 'Ano ang tawag sa eksakto nga ngalan sang tawo?',
          answer: 'Pat-od nga pangalan',
          choices: shuffled([
            'Pat-od nga pangalan',
            'Kinaandan nga pangalan',
            'Lugar',
            'Hitabo',
          ]),
          targetPhrase: 'Pat-od nga pangalan',
          targetMeaning: 'Proper noun',
          directionLabel: 'Hiligaynon concept',
        ),
        LessonQuestion.translationChoice(
          prompt: 'Ano ang tawag sa ordinaryo nga ngalan sang tawo?',
          answer: 'Kinaandan nga pangalan',
          choices: shuffled([
            'Kinaandan nga pangalan',
            'Pat-od nga pangalan',
            'Kalendaryo',
            'Tanda',
          ]),
          targetPhrase: 'Kinaandan nga pangalan',
          targetMeaning: 'Common noun',
          directionLabel: 'Hiligaynon concept',
        ),
        LessonQuestion.translationChoice(
          prompt: 'Pilion ang pat-od nga pangalan.',
          answer: 'Mayor Basilio',
          choices: shuffled(['Mayor Basilio', 'mayor', 'bata', 'manunudlo']),
          targetPhrase: 'Mayor Basilio',
          targetMeaning: 'Proper noun',
          directionLabel: 'Proper or common',
        ),
        LessonQuestion.arrangeWords(
          prompt: 'Ipahamtang ang mga pulong para mahimo ang sentence.',
          answer: 'Si Rina isa ka bata',
          sentenceWords: shuffled(['Si', 'Rina', 'isa', 'ka', 'bata']),
          targetPhrase: 'Si Rina isa ka bata',
          targetMeaning: 'Rina is a child.',
          directionLabel: 'Hiligaynon sentence',
        ),
        LessonQuestion.arrangeWords(
          prompt: 'Ipahamtang ang mga pulong para mahimo ang ideya.',
          answer: 'Mayor Basilio ang pat-od nga pangalan',
          sentenceWords: shuffled([
            'Mayor',
            'Basilio',
            'ang',
            'pat-od',
            'nga',
            'pangalan',
          ]),
          targetPhrase: 'Mayor Basilio ang pat-od nga pangalan',
          targetMeaning: 'Mayor Basilio is the proper noun.',
          directionLabel: 'Hiligaynon sentence',
        ),
        LessonQuestion.matching(
          prompt: 'Ipares ang pat-od kag kinaandan nga pangalan.',
          leftItems: ['Rina', 'Nanay Rowena', 'Mayor Basilio', 'Manunudlo'],
          rightItems: shuffled(['Child', 'Mother', 'Mayor', 'Teacher']),
        ),
        LessonQuestion.matching(
          prompt: 'Ipares ang konsepto kag kahulugan.',
          leftItems: [
            'Pat-od nga pangalan',
            'Kinaandan nga pangalan',
            'Rina',
            'Mayor Basilio',
          ],
          rightItems: shuffled([
            'Proper noun',
            'Common noun',
            'Child',
            'Mayor',
          ]),
        ),
        LessonQuestion.fillBlank(
          prompt: 'Kompletoha: Ang ___ eksakto nga ngalan sang bata.',
          answer: 'Rina',
          choices: shuffled(['Rina', 'bata', 'mayor', 'manunudlo']),
          targetPhrase: 'Ang Rina eksakto nga ngalan sang bata.',
          targetMeaning: 'Rina is the exact name of the child.',
          directionLabel: 'Fill in the blank',
        ),
        LessonQuestion.fillBlank(
          prompt: 'Kompletoha: Ang ___ ordinaryo nga ngalan sang tawo.',
          answer: 'bata',
          choices: shuffled(['bata', 'Rina', 'Mayor Basilio', 'Nanay Rowena']),
          targetPhrase: 'Ang bata ordinaryo nga ngalan sang tawo.',
          targetMeaning: 'Child is a common noun for a person.',
          directionLabel: 'Fill in the blank',
        ),
        LessonQuestion.translationChoice(
          prompt: 'Which means "common noun"?',
          answer: 'Kinaandan nga pangalan',
          choices: shuffled([
            'Kinaandan nga pangalan',
            'Pat-od nga pangalan',
            'Baganihan',
            'Kahiwatan',
          ]),
          targetPhrase: 'common noun',
          targetMeaning: 'Kinaandan nga pangalan',
          directionLabel: 'English to Hiligaynon',
        ),
      ],
      3 => [
        LessonQuestion.translationChoice(
          prompt: 'Ano ang tawag sa eksakto nga ngalan sang lugar?',
          answer: 'Pat-od nga pangalan',
          choices: shuffled([
            'Pat-od nga pangalan',
            'Kinaandan nga pangalan',
            'Tanda',
            'Kahiwatan',
          ]),
          targetPhrase: 'Pat-od nga pangalan sang lugar',
          targetMeaning: 'Proper place noun',
          directionLabel: 'Hiligaynon concept',
        ),
        LessonQuestion.translationChoice(
          prompt: 'Pilion ang pat-od nga pangalan sang lugar.',
          answer: 'Iloilo River',
          choices: shuffled(['Iloilo River', 'suba', 'merkado', 'ospital']),
          targetPhrase: 'Iloilo River',
          targetMeaning: 'Specific place',
          directionLabel: 'Proper or common',
        ),
        LessonQuestion.translationChoice(
          prompt: 'Pilion ang kinaandan nga pangalan sang lugar.',
          answer: 'merkado',
          choices: shuffled([
            'merkado',
            'Boracay',
            'Plaza Libertad',
            'Iloilo River',
          ]),
          targetPhrase: 'merkado',
          targetMeaning: 'Common place noun',
          directionLabel: 'Proper or common',
        ),
        LessonQuestion.arrangeWords(
          prompt: 'Ipahamtang ang mga pulong para mahimo ang sentence.',
          answer: 'Ang Boracay isa ka lugar',
          sentenceWords: shuffled(['Ang', 'Boracay', 'isa', 'ka', 'lugar']),
          targetPhrase: 'Ang Boracay isa ka lugar',
          targetMeaning: 'Boracay is a place.',
          directionLabel: 'Hiligaynon sentence',
        ),
        LessonQuestion.arrangeWords(
          prompt: 'Ipahamtang ang mga pulong para mahimo ang ideya.',
          answer: 'Ang tanda nagabulig magtultol',
          sentenceWords: shuffled(['Ang', 'tanda', 'nagabulig', 'magtultol']),
          targetPhrase: 'Ang tanda nagabulig magtultol',
          targetMeaning: 'A sign helps give direction.',
          directionLabel: 'Hiligaynon sentence',
        ),
        LessonQuestion.matching(
          prompt: 'Ipares ang lugar kag kahulugan.',
          leftItems: ['Iloilo River', 'Boracay', 'Plaza Libertad', 'Merkado'],
          rightItems: shuffled(['River', 'Beach place', 'Park', 'Market']),
        ),
        LessonQuestion.matching(
          prompt: 'Ipares ang pulong kag kahulugan.',
          leftItems: [
            'Tanda',
            'Lugar',
            'Pat-od nga pangalan',
            'Kinaandan nga pangalan',
          ],
          rightItems: shuffled(['Sign', 'Place', 'Proper noun', 'Common noun']),
        ),
        LessonQuestion.fillBlank(
          prompt: 'Kompletoha: Ang ___ isa ka pat-od nga pangalan sang lugar.',
          answer: 'Boracay',
          choices: shuffled(['Boracay', 'merkado', 'ospital', 'simbahan']),
          targetPhrase: 'Ang Boracay isa ka pat-od nga pangalan sang lugar.',
          targetMeaning: 'Boracay is a proper place noun.',
          directionLabel: 'Fill in the blank',
        ),
        LessonQuestion.fillBlank(
          prompt: 'Kompletoha: Ang ___ ordinaryo nga ngalan sang lugar.',
          answer: 'merkado',
          choices: shuffled([
            'merkado',
            'Iloilo River',
            'Boracay',
            'Plaza Libertad',
          ]),
          targetPhrase: 'Ang merkado ordinaryo nga ngalan sang lugar.',
          targetMeaning: 'Market is a common place noun.',
          directionLabel: 'Fill in the blank',
        ),
        LessonQuestion.translationChoice(
          prompt: 'Ano ang kahulugan sang "tanda"?',
          answer: 'Sign',
          choices: shuffled(['Sign', 'Hero', 'Calendar', 'Teacher']),
          targetPhrase: 'Tanda',
          targetMeaning: 'Sign',
          directionLabel: 'Hiligaynon to English',
        ),
      ],
      4 => [
        LessonQuestion.translationChoice(
          prompt: 'Ano ang gamit sang kalendaryo?',
          answer: 'Listahan sang adlaw kag petsa',
          choices: shuffled([
            'Listahan sang adlaw kag petsa',
            'Ngalan sang tawo',
            'Ngalan sang sapat',
            'Pulong nga nagatudlo sang lugar',
          ]),
          targetPhrase: 'Kalendaryo',
          targetMeaning: 'Calendar',
          directionLabel: 'Reading check',
        ),
        LessonQuestion.translationChoice(
          prompt: 'Pilion ang pat-od nga pangalan sang hitabo.',
          answer: 'Adlaw sang Kahilwayan',
          choices: shuffled([
            'Adlaw sang Kahilwayan',
            'kahiwatan',
            'pista',
            'adlaw sang paghanduraw',
          ]),
          targetPhrase: 'Adlaw sang Kahilwayan',
          targetMeaning: 'Proper event noun',
          directionLabel: 'Proper or common',
        ),
        LessonQuestion.translationChoice(
          prompt: 'Ano ang kahulugan sang "kahiwatan"?',
          answer: 'Event or celebration',
          choices: shuffled([
            'Event or celebration',
            'Specific person',
            'A sign',
            'A poem',
          ]),
          targetPhrase: 'Kahiwatan',
          targetMeaning: 'Event or celebration',
          directionLabel: 'Hiligaynon to English',
        ),
        LessonQuestion.arrangeWords(
          prompt: 'Ipahamtang ang mga pulong para mahimo ang sentence.',
          answer: 'Tan-awa ang kalendaryo',
          sentenceWords: shuffled(['Tan-awa', 'ang', 'kalendaryo']),
          targetPhrase: 'Tan-awa ang kalendaryo',
          targetMeaning: 'Look at the calendar.',
          directionLabel: 'Hiligaynon sentence',
        ),
        LessonQuestion.arrangeWords(
          prompt: 'Ipahamtang ang mga pulong para mahimo ang ideya.',
          answer: 'Ang Bag-ong Tuig isa ka hitabo',
          sentenceWords: shuffled([
            'Ang',
            'Bag-ong',
            'Tuig',
            'isa',
            'ka',
            'hitabo',
          ]),
          targetPhrase: 'Ang Bag-ong Tuig isa ka hitabo',
          targetMeaning: 'New Year is an event.',
          directionLabel: 'Hiligaynon sentence',
        ),
        LessonQuestion.matching(
          prompt: 'Ipares ang hitabo kag kahulugan.',
          leftItems: [
            'Bag-ong Tuig',
            'Adlaw sang Kahilwayan',
            'Rizal Day',
            'Kahiwatan',
          ],
          rightItems: shuffled([
            'New Year',
            'Independence Day',
            'Rizal Day',
            'Event or celebration',
          ]),
        ),
        LessonQuestion.matching(
          prompt: 'Ipares ang pulong kag kahulugan.',
          leftItems: [
            'Kalendaryo',
            'Hitabo',
            'Pat-od nga pangalan',
            'Kinaandan nga pangalan',
          ],
          rightItems: shuffled([
            'Calendar',
            'Event',
            'Proper noun',
            'Common noun',
          ]),
        ),
        LessonQuestion.fillBlank(
          prompt: 'Kompletoha: Ang ___ nagapakita sang adlaw kag petsa.',
          answer: 'kalendaryo',
          choices: shuffled(['kalendaryo', 'baganihan', 'tanda', 'sapat']),
          targetPhrase: 'Ang kalendaryo nagapakita sang adlaw kag petsa.',
          targetMeaning: 'A calendar shows days and dates.',
          directionLabel: 'Fill in the blank',
        ),
        LessonQuestion.fillBlank(
          prompt: 'Kompletoha: Ang ___ isa ka pat-od nga ngalan sang hitabo.',
          answer: 'Rizal Day',
          choices: shuffled(['Rizal Day', 'kahiwatan', 'pista', 'lugar']),
          targetPhrase: 'Ang Rizal Day isa ka pat-od nga ngalan sang hitabo.',
          targetMeaning: 'Rizal Day is a proper event name.',
          directionLabel: 'Fill in the blank',
        ),
        LessonQuestion.translationChoice(
          prompt: 'Which means "calendar"?',
          answer: 'Kalendaryo',
          choices: shuffled(['Kalendaryo', 'Kahiwatan', 'Baganihan', 'Tanda']),
          targetPhrase: 'calendar',
          targetMeaning: 'Kalendaryo',
          directionLabel: 'English to Hiligaynon',
        ),
      ],
      _ => [
        LessonQuestion.translationChoice(
          prompt: 'Ano ang tawag sa tawo nga nagaserbisyo para sa iban?',
          answer: 'Baganihan',
          choices: shuffled(['Baganihan', 'Kalendaryo', 'Tanda', 'Merkado']),
          targetPhrase: 'Baganihan',
          targetMeaning: 'Hero',
          directionLabel: 'Hiligaynon concept',
        ),
        LessonQuestion.translationChoice(
          prompt: 'Sin-o ang baganihan nga ginmitlang sa binalaybay?',
          answer: 'Dr. Jose Rizal',
          choices: shuffled([
            'Dr. Jose Rizal',
            'Rina',
            'Mayor Basilio',
            'Ayessa',
          ]),
          targetPhrase: 'Dr. Jose Rizal',
          targetMeaning: 'National hero',
          directionLabel: 'Reading check',
        ),
        LessonQuestion.translationChoice(
          prompt: 'Pilion ang kinaandan nga pangalan.',
          answer: 'manunudlo',
          choices: shuffled([
            'manunudlo',
            'Pilipinas',
            'Dr. Jose Rizal',
            'Rina',
          ]),
          targetPhrase: 'manunudlo',
          targetMeaning: 'Common noun',
          directionLabel: 'Proper or common',
        ),
        LessonQuestion.arrangeWords(
          prompt: 'Ipahamtang ang mga pulong para mahimo ang titulo.',
          answer: 'Baganihan sang Kabuhi Ko',
          sentenceWords: shuffled(['Baganihan', 'sang', 'Kabuhi', 'Ko']),
          targetPhrase: 'Baganihan sang Kabuhi Ko',
          targetMeaning: 'Hero of My Life',
          directionLabel: 'Poem title',
        ),
        LessonQuestion.arrangeWords(
          prompt: 'Ipahamtang ang mga pulong para mahimo ang ideya.',
          answer: 'Ako may isa ka handum',
          sentenceWords: shuffled(['Ako', 'may', 'isa', 'ka', 'handum']),
          targetPhrase: 'Ako may isa ka handum',
          targetMeaning: 'I have one dream.',
          directionLabel: 'Hiligaynon sentence',
        ),
        LessonQuestion.matching(
          prompt: 'Ipares ang pulong kag kahulugan.',
          leftItems: ['Baganihan', 'Sakripisyo', 'Dr. Jose Rizal', 'Pilipinas'],
          rightItems: shuffled([
            'Hero',
            'Sacrifice',
            'National hero',
            'Philippines',
          ]),
        ),
        LessonQuestion.matching(
          prompt: 'Ipares ang pangalan kag klase.',
          leftItems: ['Dr. Jose Rizal', 'Pilipinas', 'Baganihan', 'Manunudlo'],
          rightItems: shuffled([
            'National hero',
            'Philippines',
            'Hero',
            'Teacher',
          ]),
        ),
        LessonQuestion.fillBlank(
          prompt: 'Kompletoha: Si ___ isa ka pinasahi nga baganihan.',
          answer: 'Dr. Jose Rizal',
          choices: shuffled([
            'Dr. Jose Rizal',
            'baganihan',
            'pungsod',
            'pulis',
          ]),
          targetPhrase: 'Si Dr. Jose Rizal isa ka pinasahi nga baganihan.',
          targetMeaning: 'Dr. Jose Rizal is a special hero.',
          directionLabel: 'Fill in the blank',
        ),
        LessonQuestion.fillBlank(
          prompt: 'Kompletoha: Ang ___ isa ka kinaandan nga pangalan.',
          answer: 'baganihan',
          choices: shuffled([
            'baganihan',
            'Pilipinas',
            'Dr. Jose Rizal',
            'Rina',
          ]),
          targetPhrase: 'Ang baganihan isa ka kinaandan nga pangalan.',
          targetMeaning: 'Hero is a common noun.',
          directionLabel: 'Fill in the blank',
        ),
        LessonQuestion.translationChoice(
          prompt: 'Ano ang kahulugan sang "sakripisyo"?',
          answer: 'Sacrifice',
          choices: shuffled(['Sacrifice', 'Calendar', 'Market', 'Neighbor']),
          targetPhrase: 'Sakripisyo',
          targetMeaning: 'Sacrifice',
          directionLabel: 'Hiligaynon to English',
        ),
      ],
    };
  }

  static List<LessonQuestion> _gradeThreePdfQuestionSet(math.Random rng) {
    List<String> shuffled(List<String> values) => values;

    return [
      LessonQuestion.translationChoice(
        prompt:
            'Ano ang tawag sa ngalan sang tawo, lugar, sapat, butang, ukon hitabo?',
        answer: 'Pangalan',
        choices: shuffled(['Pangalan', 'Hinabo', 'Katawhan', 'Halamtangan']),
        targetPhrase: 'Pangalan',
        targetMeaning: 'Noun',
        directionLabel: 'Hiligaynon concept',
      ),
      LessonQuestion.translationChoice(
        prompt: 'Ano ang tawag sa mga tawo ukon karakter sa istorya?',
        answer: 'Katawhan',
        choices: shuffled(['Katawhan', 'Halamtangan', 'Hinabo', 'Lugar']),
        targetPhrase: 'Katawhan',
        targetMeaning: 'Katawhan',
        directionLabel: 'Konsepto sang istorya',
      ),
      LessonQuestion.translationChoice(
        prompt: 'Ano ang tawag sa lugar kag tion sang istorya?',
        answer: 'Halamtangan',
        choices: shuffled(['Halamtangan', 'Katawhan', 'Hinabo', 'Butang']),
        targetPhrase: 'Halamtangan',
        targetMeaning: 'Halamtangan',
        directionLabel: 'Konsepto sang istorya',
      ),
      LessonQuestion.translationChoice(
        prompt: 'Ano ang tawag sa mga natabo sa istorya?',
        answer: 'Hinabo',
        choices: shuffled(['Hinabo', 'Tawo', 'Lugar', 'Katawhan']),
        targetPhrase: 'Hinabo',
        targetMeaning: 'Hinabo',
        directionLabel: 'Konsepto sang istorya',
      ),
      LessonQuestion.arrangeWords(
        prompt: 'Ipahamtang ang mga pulong para mahimo ang titulo.',
        answer: 'Ako kag ang Akon Pamilya',
        sentenceWords: shuffled(['Ako', 'kag', 'ang', 'Akon', 'Pamilya']),
        targetPhrase: 'Ako kag ang Akon Pamilya',
        targetMeaning: 'Me and My Family',
        directionLabel: 'Story title',
      ),
      LessonQuestion.arrangeWords(
        prompt: 'Ipahamtang ang mga pulong para mahimo ang pangungusap.',
        answer: 'Si Rina isa ka bata',
        sentenceWords: shuffled(['Si', 'Rina', 'isa', 'ka', 'bata']),
        targetPhrase: 'Si Rina isa ka bata',
        targetMeaning: 'Rina is a child',
        directionLabel: 'Hiligaynon sentence',
      ),
      LessonQuestion.matching(
        prompt: 'Ipares ang pulong kag kahulugan.',
        leftItems: ['Pangalan', 'Katawhan', 'Halamtangan', 'Hinabo'],
        rightItems: shuffled([
          'ngalan',
          'mga karakter',
          'lugar kag tion',
          'natabo',
        ]),
      ),
      LessonQuestion.matching(
        prompt: 'Ipares ang halimbawa kag kahulugan.',
        leftItems: ['Rina', 'Nanay Rowena', 'Iloilo River', 'Plaza Libertad'],
        rightItems: shuffled(['Child', 'Mother', 'River', 'Park']),
      ),
      LessonQuestion.fillBlank(
        prompt:
            'Kompletoha: Ang ___ amo ang ngalan sang tawo, lugar, sapat, butang, ukon hitabo.',
        answer: 'pangalan',
        choices: shuffled(['pangalan', 'hinabo', 'suba', 'bulak']),
        targetPhrase:
            'Ang pangalan amo ang ngalan sang tawo, lugar, sapat, butang, ukon hitabo.',
        targetMeaning: 'A noun names a person, place, animal, thing, or event.',
        directionLabel: 'Fill in the blank',
      ),
      LessonQuestion.fillBlank(
        prompt: 'Kompletoha: Si ___ ang bata sa istorya.',
        answer: 'Rina',
        choices: shuffled(['Rina', 'suba', 'parke', 'butang']),
        targetPhrase: 'Si Rina ang bata sa istorya.',
        targetMeaning: 'Rina is the child in the story.',
        directionLabel: 'Fill in the blank',
      ),
    ];
  }

  static List<LessonTerm> termsForLevel(int level) {
    return _termsForLocalLesson(level);
  }

  static List<LessonTerm> termsForUnit(int unitNumber) {
    return terms.where((term) => term.unitNumber == unitNumber).toList();
  }

  static int unitForLevel(int level) {
    final unit = ((level - 1) ~/ AppData.unitLevels) + 1;
    return unit.clamp(1, unitTitles.length);
  }

  static List<LessonTerm> _termsForLocalLesson(int level) {
    final allUnitTerms = termsForUnit(unitForLevel(level));
    var unitTerms = allUnitTerms.where(_activeGradeDataset.includes).toList();
    if (unitTerms.length < 4) unitTerms = allUnitTerms;
    final localLevel = (level - 1) % AppData.unitLevels;
    final explicitTerms = unitTerms
        .where((term) => term.lessonNumber == localLevel + 1)
        .toList();

    // Each grade file owns the content pool. Levels rotate through that pool
    // so the unit stays grade-appropriate.
    final selected = <LessonTerm>[...explicitTerms];
    final start = (localLevel * 4).clamp(0, unitTerms.length - 1);
    for (var offset = 0; offset < unitTerms.length; offset++) {
      final term = unitTerms[(start + offset) % unitTerms.length];
      if (term.lessonNumber != null && term.lessonNumber != localLevel + 1) {
        continue;
      }
      if (selected.any((item) => item.hil == term.hil)) continue;
      selected.add(term);
      if (selected.length >= math.min(12, unitTerms.length)) break;
    }
    return selected;
  }

  static List<LessonTerm> _termsForUnitLessonScope(int level) {
    final localLesson = ((level - 1) % AppData.unitLevels) + 1;
    final allUnitTerms = termsForUnit(unitForLevel(level));
    var unitTerms = allUnitTerms.where(_activeGradeDataset.includes).toList();
    if (unitTerms.length < 4) unitTerms = allUnitTerms;
    return unitTerms.where((term) {
      return term.lessonNumber == null || term.lessonNumber == localLesson;
    }).toList();
  }

  static LessonQuestion _missingWordQuestion(
    int level,
    List<LessonTerm> unitTerms,
    math.Random rng, {
    List<LessonTerm> unitFallbackTerms = const [],
    bool preferScenario = true,
  }) {
    var templates = preferScenario
        ? _assetBackedMissingTerms(unitTerms)
        : _plainMissingTerms(unitTerms);
    if (templates.isEmpty && unitFallbackTerms.isNotEmpty) {
      // Complete-the-sentence should remain image-backed. If the current local
      // level has no scenario asset, reuse the scenario asset from the same
      // unit, such as Unit 1 Level 1's complete-sentence picture.
      templates = preferScenario
          ? _assetBackedMissingTerms(unitFallbackTerms)
          : _plainMissingTerms(unitFallbackTerms);
    }
    if (templates.isEmpty && !preferScenario) {
      templates = _assetBackedMissingTerms(unitTerms);
    }
    if (templates.isEmpty && !preferScenario && unitFallbackTerms.isNotEmpty) {
      templates = _assetBackedMissingTerms(unitFallbackTerms);
    }
    if (!preferScenario &&
        templates.length == 1 &&
        !_isScenarioMissingTerm(templates.first)) {
      final term = unitTerms[level % unitTerms.length];
      return _generatedFillBlankQuestion(term, unitTerms, rng);
    }
    if (templates.isEmpty) {
      final plainTemplates = _uniqueTerms([
        ..._plainMissingTerms(unitTerms),
        ..._plainMissingTerms(unitFallbackTerms),
      ]);
      if (plainTemplates.isNotEmpty &&
          (plainTemplates.length > 1 || preferScenario)) {
        final term = plainTemplates[(level - 1) % plainTemplates.length];
        return _fillBlankQuestion(term, unitTerms, rng);
      }
      if (plainTemplates.length == 1 && !preferScenario) {
        final term = unitTerms[level % unitTerms.length];
        return _generatedFillBlankQuestion(term, unitTerms, rng);
      }
      final term = unitTerms.firstWhere(
        (term) => term.missingSentence != null && term.missingAnswer != null,
        orElse: () => unitTerms[level % unitTerms.length],
      );
      if (term.missingSentence != null && term.missingAnswer != null) {
        return _fillBlankQuestion(term, unitTerms, rng);
      }
      return _generatedFillBlankQuestion(term, unitTerms, rng);
    }
    final term = templates[(level - 1) % templates.length];
    return _fillBlankQuestion(term, unitTerms, rng);
  }

  static LessonQuestion _fillBlankQuestion(
    LessonTerm term,
    List<LessonTerm> unitTerms,
    math.Random rng,
  ) {
    return LessonQuestion.fillBlank(
      prompt: 'Complete the sentence "${term.missingSentence}"',
      answer: term.missingAnswer!,
      choices: term.choices.isEmpty
          ? _missingChoices(term, unitTerms, rng)
          : term.choices,
      imagePath: term.imagePath ?? '',
      sentenceMeaning: term.eng,
      wordMeanings: term.wordMeanings,
      targetPhrase: term.hil,
      targetMeaning: term.eng,
      directionLabel: 'Hiligaynon to English',
    );
  }

  static LessonQuestion _generatedFillBlankQuestion(
    LessonTerm term,
    List<LessonTerm> unitTerms,
    math.Random rng,
  ) {
    return LessonQuestion.fillBlank(
      prompt: 'Complete the sentence "${term.hil} ___"',
      answer: term.eng,
      choices: _optionsFor(
        answer: term.eng,
        values: unitTerms.map((term) => term.eng).toList(),
        fallbackValues: unitTerms.map((term) => term.eng).toList(),
        rng: rng,
      ),
      targetPhrase: term.hil,
      targetMeaning: term.eng,
      directionLabel: 'Hiligaynon to English',
    );
  }

  static List<LessonTerm> _assetBackedMissingTerms(List<LessonTerm> source) {
    return source.where(_isScenarioMissingTerm).toList();
  }

  static List<LessonTerm> _plainMissingTerms(List<LessonTerm> source) {
    return source
        .where(
          (term) =>
              term.missingSentence != null &&
              term.missingAnswer != null &&
              !_isScenarioMissingTerm(term),
        )
        .toList();
  }

  static List<LessonTerm> _uniqueTerms(List<LessonTerm> source) {
    final seen = <String>{};
    final unique = <LessonTerm>[];
    for (final term in source) {
      final key = _conceptKey(term);
      if (seen.add(key)) unique.add(term);
    }
    return unique;
  }

  static List<LessonTerm> _nonScenarioTerms(List<LessonTerm> source) {
    final terms = source
        .where((term) => !_isScenarioMissingTerm(term))
        .toList();
    return terms.isEmpty ? source : terms;
  }

  static bool _isScenarioMissingTerm(LessonTerm term) {
    return term.missingSentence != null &&
        term.missingAnswer != null &&
        term.imagePath != null &&
        term.imagePath!.contains('/complete_the_sentence/');
  }

  static LessonQuestion _translationChoiceQuestion({
    required LessonTerm term,
    required bool englishToHiligaynon,
    required List<LessonTerm> pool,
    required math.Random rng,
  }) {
    if (englishToHiligaynon) {
      return LessonQuestion.translationChoice(
        prompt: 'Translate: "${term.eng}"',
        answer: term.hil,
        choices: _optionsFor(
          answer: term.hil,
          values: pool.map((term) => term.hil).toList(),
          fallbackValues: pool.map((term) => term.hil).toList(),
          rng: rng,
        ),
        targetPhrase: term.eng,
        targetMeaning: term.hil,
        directionLabel: 'English to Hiligaynon',
      );
    }

    return LessonQuestion.translationChoice(
      prompt: 'Translate: "${term.hil}"',
      answer: term.eng,
      choices: _optionsFor(
        answer: term.eng,
        values: pool.map((term) => term.eng).toList(),
        fallbackValues: pool.map((term) => term.eng).toList(),
        rng: rng,
      ),
      targetPhrase: term.hil,
      targetMeaning: term.eng,
      directionLabel: 'Hiligaynon to English',
    );
  }

  static LessonQuestion _matchingQuestion(
    List<LessonTerm> source,
    List<LessonTerm> unitTerms,
    int seed,
  ) {
    // Matching pair activities stay word-based. The first pool keeps the
    // current lesson slice on-theme, and the second pool fills with other
    // word-like terms from the same unit if needed.
    final sourceWords = _matchingTerms(source);
    final unitWords = _matchingTerms(unitTerms);
    final selected = _takeUniqueTerms(sourceWords, 4, seed);
    for (
      var offset = 0;
      selected.length < 4 && offset < unitWords.length;
      offset++
    ) {
      final candidate = unitWords[(seed + offset) % unitWords.length];
      if (!selected.any((term) => term.hil == candidate.hil)) {
        selected.add(candidate);
      }
    }
    final globalWords = _matchingTerms(
      terms.where((term) => term.lessonNumber != 1).toList(),
    );
    for (
      var offset = 0;
      selected.length < 4 && offset < globalWords.length;
      offset++
    ) {
      final candidate = globalWords[(seed + offset) % globalWords.length];
      if (!selected.any((term) => term.hil == candidate.hil)) {
        selected.add(candidate);
      }
    }
    final rightItems = selected.map((term) => term.eng).toList()
      ..shuffle(math.Random(seed));
    return LessonQuestion.matching(
      prompt: 'Match each Hiligaynon word to English.',
      leftItems: selected.map((term) => term.hil).toList(),
      rightItems: rightItems,
    );
  }

  static LessonQuestion _arrangeWordsQuestion(
    int level,
    List<LessonTerm> unitTerms,
    math.Random rng,
  ) {
    final practiceTerms = _nonScenarioTerms(unitTerms);
    final sentences = practiceTerms.where(_isSentenceTerm).toList();
    final source = sentences.isEmpty ? unitTerms : sentences;
    final term = source[(level - 1) % source.length];
    final answerWords = _words(term.hil);
    final configuredBlocks = term.wordBlocks.where((word) {
      return word.trim().isNotEmpty;
    });
    final distractors =
        practiceTerms
            .expand((term) => _words(term.hil))
            .where((word) => !answerWords.contains(word))
            .toSet()
            .toList()
          ..shuffle(rng);
    final blocks = <String>[
      ...(configuredBlocks.isEmpty ? answerWords : configuredBlocks),
      ...distractors.take(3),
    ]..shuffle(rng);
    return LessonQuestion.arrangeWords(
      prompt: 'Arrange the words to say: "${term.eng}"',
      answer: term.hil,
      sentenceWords: blocks,
      targetPhrase: term.eng,
      targetMeaning: term.hil,
      directionLabel: 'English to Hiligaynon',
    );
  }

  static LessonQuestion? _imageChoiceQuestion(
    List<LessonTerm> unitTerms,
    math.Random rng, {
    int seed = 0,
    String? avoidAnswer,
    bool allowGlobalFallback = false,
  }) {
    var imageTerms = unitTerms.where(_isImageChoiceTerm).toList();
    if (imageTerms.length < 4 && allowGlobalFallback) {
      // Unit 1 Level 1 is the showcase level. It may use the approved people
      // and transportation visual pools even though those images live outside
      // Unit 1's local lesson slice.
      imageTerms = terms
          .where(_isImageChoiceTerm)
          .where((term) => term.lessonNumber != 1)
          .toList();
    }
    imageTerms = _sameImageFolderTerms(imageTerms, seed);
    if (imageTerms.length < 4) return null;
    imageTerms.shuffle(rng);
    final selected = _takeUniqueTerms(imageTerms, 4, seed);
    final fallbackAnswer = selected[seed.abs() % selected.length];
    final answer = avoidAnswer == null
        ? fallbackAnswer
        : selected.firstWhere(
            (term) => term.hil != avoidAnswer,
            orElse: () => fallbackAnswer,
          );
    return LessonQuestion.imageChoice(
      prompt: 'Which of these is "${answer.eng}"?',
      answer: answer.hil,
      imageChoices: selected..shuffle(rng),
      targetPhrase: answer.hil,
      targetMeaning: answer.eng,
      directionLabel: 'Hiligaynon to English',
    );
  }

  static List<LessonQuestion> _completeShowcaseQuestionSet(
    List<LessonQuestion> questions, {
    required int level,
    required List<LessonTerm> levelTerms,
    required List<LessonTerm> unitTerms,
    required List<LessonTerm> scenarioTerms,
    required List<LessonTerm> scenarioUnitTerms,
    required math.Random rng,
  }) {
    const targets = {
      QuestionType.translationChoice: 3,
      QuestionType.arrangeWords: 2,
      QuestionType.matching: 1,
      QuestionType.fillBlank: 2,
      QuestionType.imageChoice: 2,
    };
    final completed = <LessonQuestion>[];
    final seen = <String>{};
    final counts = <QuestionType, int>{};

    void addIfNeeded(LessonQuestion? question) {
      if (question == null) return;
      final target = targets[question.type];
      if (target == null) return;
      if ((counts[question.type] ?? 0) >= target) return;
      final key = _questionKey(question);
      if (!seen.add(key)) return;
      completed.add(question);
      counts[question.type] = (counts[question.type] ?? 0) + 1;
    }

    for (final question in questions) {
      addIfNeeded(question);
    }

    LessonQuestion? candidateFor(QuestionType type, int cursor) {
      final term = levelTerms[cursor % levelTerms.length];
      return switch (type) {
        QuestionType.translationChoice => _translationChoiceQuestion(
          term: term,
          englishToHiligaynon: cursor.isEven,
          pool: levelTerms,
          rng: rng,
        ),
        QuestionType.arrangeWords => _arrangeWordsQuestion(
          level + cursor,
          levelTerms,
          rng,
        ),
        QuestionType.matching => _matchingQuestion(
          levelTerms,
          unitTerms,
          level + cursor,
        ),
        QuestionType.fillBlank =>
          cursor < scenarioUnitTerms.length
              ? _missingWordQuestion(
                  level + cursor,
                  scenarioUnitTerms,
                  rng,
                  unitFallbackTerms: scenarioUnitTerms,
                  preferScenario: cursor.isEven,
                )
              : _generatedFillBlankQuestion(
                  scenarioUnitTerms[(level + cursor) %
                      scenarioUnitTerms.length],
                  scenarioUnitTerms,
                  rng,
                ),
        QuestionType.imageChoice => _imageChoiceQuestion(
          scenarioTerms,
          rng,
          seed: level + cursor,
          allowGlobalFallback: true,
        ),
        _ => null,
      };
    }

    for (final entry in targets.entries) {
      var cursor = 0;
      while ((counts[entry.key] ?? 0) < entry.value && cursor < 160) {
        addIfNeeded(candidateFor(entry.key, cursor));
        cursor++;
      }
    }
    return completed.take(AppData.questionsPerUnit).toList();
  }

  static List<LessonQuestion> _completeFlexibleQuestionSet(
    List<LessonQuestion> questions, {
    required int level,
    required List<LessonTerm> levelTerms,
    required List<LessonTerm> unitTerms,
    required List<LessonTerm> scenarioTerms,
    required List<LessonTerm> scenarioUnitTerms,
    required math.Random rng,
  }) {
    const targets = {
      QuestionType.translationChoice: 3,
      QuestionType.arrangeWords: 2,
      QuestionType.matching: 1,
      QuestionType.fillBlank: 2,
      QuestionType.imageChoice: 2,
    };
    final completed = <LessonQuestion>[];
    final seen = <String>{};
    final counts = <QuestionType, int>{};

    void addIfNeeded(LessonQuestion? question) {
      if (question == null) return;
      final target = targets[question.type];
      if (target == null) return;
      if ((counts[question.type] ?? 0) >= target) return;
      final key = _questionKey(question);
      if (!seen.add(key)) return;
      completed.add(question);
      counts[question.type] = (counts[question.type] ?? 0) + 1;
    }

    for (final question in questions) {
      addIfNeeded(question);
    }

    LessonQuestion? candidateFor(QuestionType type, int cursor) {
      final term = levelTerms[cursor % levelTerms.length];
      return switch (type) {
        QuestionType.translationChoice => _translationChoiceQuestion(
          term: term,
          englishToHiligaynon: cursor.isEven,
          pool: levelTerms,
          rng: rng,
        ),
        QuestionType.arrangeWords => _arrangeWordsQuestion(
          level + cursor,
          levelTerms,
          rng,
        ),
        QuestionType.matching => _matchingQuestion(
          levelTerms,
          unitTerms,
          level + cursor,
        ),
        QuestionType.fillBlank =>
          cursor < scenarioUnitTerms.length
              ? _missingWordQuestion(
                  level + cursor,
                  scenarioUnitTerms,
                  rng,
                  unitFallbackTerms: scenarioUnitTerms,
                  preferScenario: cursor.isEven,
                )
              : _generatedFillBlankQuestion(
                  scenarioUnitTerms[(level + cursor) %
                      scenarioUnitTerms.length],
                  scenarioUnitTerms,
                  rng,
                ),
        QuestionType.imageChoice => _imageChoiceQuestion(
          unitTerms,
          rng,
          seed: level + cursor,
          allowGlobalFallback: true,
        ),
        _ => null,
      };
    }

    for (final entry in targets.entries) {
      var cursor = 0;
      while ((counts[entry.key] ?? 0) < entry.value && cursor < 180) {
        addIfNeeded(candidateFor(entry.key, cursor));
        cursor++;
      }
    }

    return completed.take(AppData.questionsPerUnit).toList();
  }

  static String _questionKey(LessonQuestion question) {
    return [
      question.type.name,
      question.prompt.trim().toLowerCase(),
      question.answer.trim().toLowerCase(),
      question.leftItems.join('|').toLowerCase(),
      question.imageChoices.map((term) => term.hil).join('|').toLowerCase(),
    ].join('::');
  }

  static GradeLessonDataset get _activeGradeDataset {
    return gradeDatasets[AppData.selectedGradeLevel] ?? grade1LessonDataset;
  }

  static String _applyGradeTemplate(
    String template, {
    required String unitTitle,
    required String focusWords,
  }) {
    return template
        .replaceAll('{unitTitle}', unitTitle)
        .replaceAll('{focusWords}', focusWords);
  }

  static String _joinQuoted(List<String> values) {
    final cleaned = values.where((value) => value.trim().isNotEmpty).toList();
    if (cleaned.isEmpty) return 'from this lesson';
    if (cleaned.length == 1) return '"${cleaned.first}"';
    if (cleaned.length == 2) {
      return '"${cleaned.first}" and "${cleaned.last}"';
    }
    final head = cleaned.take(cleaned.length - 1).map((value) => '"$value"');
    return '${head.join(', ')}, and "${cleaned.last}"';
  }

  static bool _isImageChoiceTerm(LessonTerm term) {
    final imagePath = term.imagePath;
    if (imagePath == null || imagePath.isEmpty) return false;
    // Keep image-choice questions to the approved visual vocabulary folders.
    // Scenario images under "complete the sentence" belong exclusively to
    // fill-blank activities.
    return imagePath.contains('/animal/') ||
        imagePath.contains('/fruits/') ||
        imagePath.contains('/action/');
  }

  static List<LessonTerm> _sameImageFolderTerms(
    List<LessonTerm> imageTerms,
    int seed,
  ) {
    final grouped = <String, List<LessonTerm>>{};
    for (final term in imageTerms) {
      grouped.putIfAbsent(_imageFolderKey(term), () => []).add(term);
    }
    final groups = grouped.values.where((group) => group.length >= 4).toList();
    if (groups.isEmpty) return const [];
    groups.sort(
      (a, b) => _imageFolderKey(a.first).compareTo(_imageFolderKey(b.first)),
    );
    return groups[seed.abs() % groups.length];
  }

  static String _imageFolderKey(LessonTerm term) {
    final path = term.imagePath ?? '';
    final lastSlash = path.lastIndexOf('/');
    if (lastSlash <= 0) return path;
    return path.substring(0, lastSlash);
  }

  static List<String> _missingChoices(
    LessonTerm term,
    List<LessonTerm> unitTerms,
    math.Random rng,
  ) {
    final choices = <String>{term.missingAnswer!};
    final unitWords =
        unitTerms
            .expand((term) => _words(term.hil))
            .where((word) => !word.contains('?'))
            .toList()
          ..shuffle(rng);
    for (final word in unitWords) {
      if (choices.length >= 4) break;
      choices.add(word);
    }
    return choices.toList()..shuffle(rng);
  }

  static List<String> _optionsFor({
    required String answer,
    required List<String> values,
    required List<String> fallbackValues,
    required math.Random rng,
  }) {
    // Wrong choices prefer the current unit so lessons stay on-theme. Fallback
    // values are used only when there are not enough unique same-unit choices.
    final options = <String>{answer};
    final sameUnit = values.where((value) => value != answer).toList()
      ..shuffle(rng);
    for (final value in sameUnit) {
      if (options.length >= 4) break;
      options.add(value);
    }
    final fallback = fallbackValues.where((value) => value != answer).toList()
      ..shuffle(rng);
    for (final value in fallback) {
      if (options.length >= 4) break;
      options.add(value);
    }
    return options.toList()..shuffle(rng);
  }

  static List<LessonTerm> _takeUniqueTerms(
    List<LessonTerm> pool,
    int count,
    int seed,
  ) {
    final selected = <LessonTerm>[];
    var index = seed;
    while (selected.length < count && index < seed + pool.length * 2) {
      final term = pool[index % pool.length];
      if (!selected.any((item) => item.hil == term.hil)) selected.add(term);
      index++;
    }
    return selected;
  }

  static bool _isSentenceTerm(LessonTerm term) {
    final type = term.type;
    if (type != null) return type == LessonContentType.sentence;
    return term.hil.contains(' ') && term.eng.contains(' ');
  }

  static List<LessonTerm> _matchingTerms(List<LessonTerm> pool) {
    final words = pool.where(_isMatchingWordTerm).toList();
    if (words.length >= 4) return words;

    final phraseFallback = pool.where((term) {
      return !_isScenarioMissingTerm(term) &&
          term.imagePath == null &&
          !term.hil.contains('?') &&
          !term.eng.contains('?') &&
          term.hil.split(RegExp(r'\s+')).length <= 4 &&
          term.eng.split(RegExp(r'\s+')).length <= 4;
    });
    return _uniqueTerms([...words, ...phraseFallback]);
  }

  static bool _isMatchingWordTerm(LessonTerm term) {
    // Match tiles should be simple vocabulary cards such as Lakat, Kadto, or
    // Hambal. Multi-word phrases and questions belong in translation exercises.
    final type = term.type;
    if (type != null) return type == LessonContentType.word;
    return !term.hil.trim().contains(' ') &&
        !term.hil.contains('?') &&
        !term.eng.trim().contains(' ') &&
        !term.eng.contains('?');
  }

  static List<String> _words(String value) {
    return value
        .replaceAll(RegExp(r'[.!?"]'), '')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
  }

  static String _conceptKey(LessonTerm term) {
    return '${term.unitNumber}|${term.hil.toLowerCase()}|${term.eng.toLowerCase()}';
  }
}
