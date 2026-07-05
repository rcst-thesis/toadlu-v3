import 'dart:math' as math;

import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank_item.dart';
import 'units/unit1/leksyon1/dataset.dart';
import 'units/unit4/leksyonAll/dataset.dart';
import 'units/unit5/leksyonAll/dataset.dart';
import 'units/unit6/leksyonAll/dataset.dart';
export 'units/unit1/leksyon1/activities.dart';
export 'units/unit4/leksyonAll/activities.dart';
export 'units/unit5/leksyonAll/activities.dart';
export 'units/unit6/leksyonAll/activities.dart';

const grade3LessonDataset = GradeLessonDataset(
  gradeLevel: GradeLevel.grade3,
  maxTermGrade: 3,
  storyTemplate:
      'Use {unitTitle} in a fuller conversation. Listen for {focusWords}, then think about how each phrase changes the meaning of the whole message.',
  lessonTemplate:
      'Practice the meaning and sentence pattern together. Use the examples first, then answer each quiz item by checking both translation and word order.',
);

const List<LessonTerm> grade3LessonTerms = [
  ...grade3Unit1Leksyon1Terms,
  ...grade3Unit4LeksyonAllTerms,
  ...grade3Unit5LeksyonAllTerms,
  ...grade3Unit6LeksyonAllTerms,
];

const grade3Unit1SourceLessons = [grade3Unit1Leksyon1SourceLesson];

LessonLevelContent gradeThreePdfContentForLevel(int level) {
  final localLevel = ((level - 1) % AppData.unitLevels) + 1;
  if (localLevel == 1) {
    return _grade3SourceContent(grade3Unit1Leksyon1SourceLesson);
  }
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

LessonLevelContent _grade3SourceContent(GradeLessonSource source) {
  final reading = source.readingText;
  final storyTitle = reading.isEmpty ? source.lessonTitle : reading.first;
  final storyBody = reading.length <= 1 ? '' : reading.skip(1).join('\n\n');

  return LessonLevelContent(
    title: 'Leksyon ${source.lessonNumber}: ${source.lessonTitle}',
    storyTitle: storyTitle,
    story: storyBody,
    shortLesson: source.paminsaraIni.join('\n\n'),
    concepts: [
      for (final objective in source.katuyuan)
        LessonConceptCard(
          title: 'Katuyuan',
          hiligaynon: objective,
          english: '',
        ),
      for (var index = 0; index < source.pasanyugaIni.length; index += 2)
        LessonConceptCard(
          title: source.pasanyugaIni[index].split(' - ').first,
          hiligaynon: source.pasanyugaIni[index],
          english: index + 1 < source.pasanyugaIni.length
              ? source.pasanyugaIni[index + 1]
              : '',
        ),
    ],
    examples: [
      for (final term in grade3Unit1Leksyon1Terms)
        LessonExample(hiligaynon: term.hil, english: term.eng),
    ],
  );
}

List<LessonQuestion> gradeThreePdfQuestionSet(math.Random rng) {
  List<String> shuffled(List<String> values) => values;

  return [
    LessonQuestion.translationChoice(
      prompt:
          'Ano ang tawag sa mga pangalan nga pareho sang luto nga kamatis, prutas, kag tatlo ka adlaw?',
      answer: 'Pangalan nga pang-isip',
      choices: shuffled([
        'Pangalan nga pang-isip',
        'Pangalan nga indi maisip',
        'Katawhan',
        'Hinabo',
      ]),
      targetPhrase: 'Pangalan nga pang-isip',
      targetMeaning: 'Count noun',
      directionLabel: 'Hiligaynon concept',
    ),
    LessonQuestion.translationChoice(
      prompt: 'Ano ang kahulugan sang "estasyon"?',
      answer: 'balantayan sang salakyan',
      choices: shuffled([
        'balantayan sang salakyan',
        'dalagku nga mga edipisyo',
        'talamnan sang ulutanon',
        'bandehado nga kan-on',
      ]),
      targetPhrase: 'estasyon',
      targetMeaning: 'balantayan sang salakyan',
      directionLabel: 'Vocabulary',
    ),
    LessonQuestion.translationChoice(
      prompt: 'Ano ang kahulugan sang "establisyemento"?',
      answer: 'dalagku nga mga edipisyo ukon building',
      choices: shuffled([
        'dalagku nga mga edipisyo ukon building',
        'balantayan sang salakyan',
        'ulutanon sa talamnan',
        'pinirito nga isda',
      ]),
      targetPhrase: 'establisyemento',
      targetMeaning: 'large buildings',
      directionLabel: 'Vocabulary',
    ),
    LessonQuestion.translationChoice(
      prompt:
          'Ngaa aga pa ginpukaw ni Nanay Rowena ang iya pamilya kag si Rina?',
      answer: 'Makadto sila sa lugar sang tatay ni Rina.',
      choices: shuffled([
        'Makadto sila sa lugar sang tatay ni Rina.',
        'May klase si Rina.',
        'Magbakal sila sa merkado.',
        'Magpaninlo sila sang barangay.',
      ]),
      targetPhrase: 'Isipon Mo!',
      targetMeaning: 'Reading check',
      directionLabel: 'Reading check',
    ),
    LessonQuestion.arrangeWords(
      prompt: 'Ano ini sa Hiligaynon.',
      answer: 'Mga Pangalan nga Maisip',
      sentenceWords: shuffled(['Mga', 'Pangalan', 'nga', 'Maisip']),
      targetPhrase: 'Mga Pangalan nga Maisip',
      targetMeaning: 'Count Nouns',
      directionLabel: 'Lesson title',
    ),
    LessonQuestion.arrangeWords(
      prompt: 'Ano ini sa Hiligaynon.',
      answer: 'May tatlo ka pinirito nga itlog',
      sentenceWords: shuffled([
        'May',
        'tatlo',
        'ka',
        'pinirito',
        'nga',
        'itlog',
      ]),
      targetPhrase: 'May tatlo ka pinirito nga itlog',
      targetMeaning: 'There are three fried eggs',
      directionLabel: 'Hiligaynon sentence',
    ),
    LessonQuestion.matching(
      prompt: 'Ipares ang tinaga kag kahulugan.',
      leftItems: ['estasyon', 'establisyemento', 'kamatis', 'talong'],
      rightItems: shuffled([
        'balantayan sang salakyan',
        'dalagku nga edipisyo',
        'tomato',
        'eggplant',
      ]),
    ),
    LessonQuestion.matching(
      prompt: 'Ipares ang numero kag butang halin sa istorya.',
      leftItems: ['tatlo', 'anum', 'walo', '20'],
      rightItems: shuffled([
        'pinirito nga itlog',
        'pinirito nga isda',
        'bilog nga saging',
        'bus sa estasyon',
      ]),
    ),
    LessonQuestion.fillBlank(
      prompt: 'Kompletoha: Ang mga ini ginatawag nga pangalan nga ___.',
      answer: 'pang-isip',
      choices: shuffled(['pang-isip', 'hinabo', 'katawhan', 'halamtangan']),
      targetPhrase: 'Ang mga ini ginatawag nga pangalan nga pang-isip.',
      targetMeaning: 'These are called count nouns.',
      directionLabel: 'Fill in the blank',
    ),
    LessonQuestion.fillBlank(
      prompt: 'Kompletoha: Si ___ ang bata sa istorya.',
      answer: 'Rina',
      choices: shuffled(['Rina', 'Lola Ensang', 'Mam Espinosa', 'Yani']),
      targetPhrase: 'Si Rina ang bata sa istorya.',
      targetMeaning: 'Rina is the child in the story.',
      directionLabel: 'Fill in the blank',
    ),
  ];
}
