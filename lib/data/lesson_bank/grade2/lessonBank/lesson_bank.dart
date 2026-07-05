import 'package:tudloapp/core/data/app_data.dart';
import 'package:tudloapp/core/models/grade_level.dart';
import 'package:tudloapp/data/lesson_bank/lesson_bank_item.dart';
import 'units/unit1/leksyon1/dataset.dart';
import 'units/unit1/leksyon2/dataset.dart';
import 'units/unit2/leksyonAll/dataset.dart';
import 'units/unit3/leksyonAll/dataset.dart';
export 'units/unit1/leksyon1/activities.dart';
export 'units/unit1/leksyon2/activities.dart';
export 'units/unit2/leksyonAll/activities.dart';
export 'units/unit3/leksyonAll/activities.dart';

const grade2LessonDataset = GradeLessonDataset(
  gradeLevel: GradeLevel.grade2,
  maxTermGrade: 2,
  storyTemplate:
      'Use {unitTitle} in a story-based lesson. Listen for {focusWords}, then think about how each word helps name a person, place, thing, animal, or event.',
  lessonTemplate:
      'Practice the meaning and sentence pattern together. Read the examples first, then answer each quiz item by checking the concept, translation, and word order.',
);

const List<LessonTerm> grade2LessonTerms = [
  ...grade2Unit1Leksyon1Terms,
  ...grade2Unit1Leksyon2Terms,
  ...grade2Unit2LeksyonAllTerms,
  ...grade2Unit3LeksyonAllTerms,
];

const grade2Unit1SourceLessons = [grade2Unit1Leksyon1SourceLesson];

LessonLevelContent gradeTwoUnitOneContentForLevel(int level) {
  final localLevel = ((level - 1) % AppData.unitLevels) + 1;
  return switch (localLevel) {
    1 => _grade2SourceContent(grade2Unit1Leksyon1SourceLesson),
    2 => const LessonLevelContent(
      title: 'Leksyon 2: Pat-od kag Kinaandan nga Pangalan sang Tawo',
      storyTitle: 'Masarangan Ko Man Ini!',
      story:
          'Aga pa nagbugtaw si Rina. Gilayon niya nga ginpangita ang iya iloy. Ginpangita niya ang iya iloy sa ila hulot hiligdaan apang wala ini. Nagkadto sia sa kusina apang wala man niya nakita didto. Nagaisahanon sia sa ila balay! Naglumawlumaw ang mga mata ni Rina nga nagpungko sa sala.\n\nNakibot sia sang mabatian nga may nagaistoryahanay nga mga tawo sa ila palibot. Nagsid-ing sia sa bintana kag nakita niya ang iya iloy nga may ginaistorya nga ila kasilingan. Gilayon nga nadula ang iya kahadlok. Nagpalapit sia sa iya iloy kag iya nadiparahan nga may mga dala sila nga inugpaninlo kasubong sang silhig, dust pan, pangkaykay kag pala.\n\n"Nanay, abi ko ginbayaan mo ako nga nagaisahanon sa balay. Diin kamo naghalin kag ngaa may dala kamo nga inugpaninlo? Tapos naman ang Brigada Eskwela sa amon buluthuan," pamangkot ni Rina sa iya iloy.\n\n"Anak, ginhagad ako sang aton kasilingan nga sanday Tiya Marina, Tiya Tess, Tiyo Ador kag Tiyo Gusting nga maupod sa ila sa pagpaninlo sang aton palibot. Proyekto ini ni Mayor Basilio," paathag ni Nanay Rowena sa iya bata.\n\n"Proyekto ini kada tuig sang aton alkalde kaupod ang iban nga konsehal agud masiguro ang katinlo sang aton palibot," sugpon ni Nanay Rowena.\n\n"A, tingala ko man nga naghambal ang amon manunudlo nga si Gg. Ramos nga hambalon ang amon mga ginikanan nga maghugpong sang isa ka manami nga proyekto sa aton," hambal ni Rina sa iya iloy.\n\n"Nay, pwede bala ako mag-upod bulig sa inyo? Sarangan ko man magbulig sa proyekto ni Mayor!" may pagpabugal nga hambal ni Rina sa iya iloy.\n\n"Abaw, sige agud pagsulod mo sa Lunes may i-istorya ka sa imo mga kaeskwela kag manunudlo nahanungod sa imo inagihan sa pagbulig sa aton barangay," malipayon nga sugpon ni Nanay Rowena.',
      shortLesson:
          'Ang pangalan nga ginagamit agud itudlo ang pat-od nga pangalan ginatawag nga pat-od nga pangalan. Nagauumpisa ini sa daku nga letra. Ang pangalan nga kinaandan nagapatuhoy sa ordinaryo nga ngalan sang tawo, butang, ukon hitabo. Nagauumpisa ini sa gamay nga letra.',
      concepts: [
        LessonConceptCard(
          title: 'Pat-od nga Pangalan',
          hiligaynon:
              'Pangalan nga ginagamit agud itudlo ang pat-od nga pangalan. Nagauumpisa ini sa daku nga letra.',
          english: 'A proper noun names one specific person.',
        ),
        LessonConceptCard(
          title: 'Kinaandan nga Pangalan',
          hiligaynon:
              'Ordinaryo nga ngalan sang tawo, butang, ukon hitabo. Nagauumpisa ini sa gamay nga letra.',
          english: 'A common noun names an ordinary person, thing, or event.',
        ),
        LessonConceptCard(
          title: 'Nagalumawlumaw',
          hiligaynon: 'Daw mahibi.',
          english: 'About to cry.',
        ),
      ],
      examples: [
        LessonExample(
          category: 'Pat-od',
          hiligaynon: 'Rina',
          english: 'Child',
          note: 'Pat-od nga ngalan',
        ),
        LessonExample(
          category: 'Pat-od',
          hiligaynon: 'Nanay Rowena',
          english: 'Mother',
          note: 'Pat-od nga ngalan',
        ),
        LessonExample(
          category: 'Pat-od',
          hiligaynon: 'Mayor Basilio',
          english: 'Mayor',
          note: 'Pat-od nga ngalan',
        ),
        LessonExample(
          category: 'Kinaandan',
          hiligaynon: 'bata',
          english: 'Child',
          note: 'Ordinaryo nga ngalan',
        ),
        LessonExample(
          category: 'Kinaandan',
          hiligaynon: 'manunudlo',
          english: 'Teacher',
          note: 'Ordinaryo nga ngalan',
        ),
      ],
    ),
    _ => const LessonLevelContent(
      title: 'Leksyon',
      storyTitle: 'Listen and Learn',
      story: 'Grade 2 source content is available for Leksyon 1 and 2.',
      shortLesson:
          'Add the next Grade 2 source transcription before enabling this lesson.',
      examples: [],
    ),
  };
}

LessonLevelContent _grade2SourceContent(GradeLessonSource source) {
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
      for (final term in grade2Unit1Leksyon1Terms.take(8))
        LessonExample(hiligaynon: term.hil, english: term.eng),
    ],
  );
}

List<LessonQuestion> gradeTwoUnitOneQuestionSet(int level) {
  final localLevel = ((level - 1) % AppData.unitLevels) + 1;
  List<String> shuffled(List<String> values) => values;

  return switch (localLevel) {
    1 => [
      LessonQuestion.translationChoice(
        prompt:
            'Ano ang tawag sa mga tinaga nga nagatumod sa ngalan sang tawo, butang, sapat, lugar kag hitabo?',
        answer: 'Pangalan',
        choices: shuffled(['Pangalan', 'Kasilingan', 'Buluthuan', 'Barangay']),
        targetPhrase: 'Pangalan',
        targetMeaning: 'Noun',
        directionLabel: 'Hiligaynon concept',
      ),
      LessonQuestion.translationChoice(
        prompt: 'Sin-o ang bata sa istorya nga "Dalayawon"?',
        answer: 'Rina',
        choices: shuffled([
          'Rina',
          'Nanay Rowena',
          'Mayor Basilio',
          'Gg. Ramos',
        ]),
        targetPhrase: 'Dalayawon',
        targetMeaning: 'Rina',
        directionLabel: 'Reading check',
      ),
      LessonQuestion.translationChoice(
        prompt: 'Ano nga proyekto ang ginahimo sa barangay?',
        answer: 'Matinlo kag Berde nga Barangay, Manggad kag Kalipay',
        choices: shuffled([
          'Matinlo kag Berde nga Barangay, Manggad kag Kalipay',
          'Brigada Eskwela',
          'Adlaw sang Kahilwayan',
          'Lakbay Aral',
        ]),
        targetPhrase: 'Matinlo kag Berde nga Barangay, Manggad kag Kalipay',
        targetMeaning: 'Clean and Green Barangay, Wealth and Joy',
        directionLabel: 'Reading check',
      ),
      LessonQuestion.translationChoice(
        prompt: 'Ano ang kahulugan sang "kasilingan"?',
        answer: 'Mga tawo nga nagaistar sa tupad sang aton balay',
        choices: shuffled([
          'Mga tawo nga nagaistar sa tupad sang aton balay',
          'Mga bata nga nagasulod sa buluthuan',
          'Mga sapat nga yara sa parke',
          'Mga butang nga ginagamit sa pagsulat',
        ]),
        targetPhrase: 'Kasilingan',
        targetMeaning: 'Neighbor',
        directionLabel: 'Vocabulary',
      ),
      LessonQuestion.arrangeWords(
        prompt: 'Ano ini sa Hiligaynon.',
        answer: 'Ang pangalan nagatuhoy sa ngalan sang tawo',
        sentenceWords: shuffled([
          'Ang',
          'pangalan',
          'nagatuhoy',
          'sa',
          'ngalan',
          'sang',
          'tawo',
        ]),
        targetPhrase: 'Ang pangalan nagatuhoy sa ngalan sang tawo',
        targetMeaning: 'A noun refers to the name of a person.',
        directionLabel: 'Hiligaynon sentence',
      ),
      LessonQuestion.arrangeWords(
        prompt: 'Ano ini sa Hiligaynon.',
        answer: 'Mabuot kag mabinuligon ang amon mga kasilingan',
        sentenceWords: shuffled([
          'Mabuot',
          'kag',
          'mabinuligon',
          'ang',
          'amon',
          'mga',
          'kasilingan',
        ]),
        targetPhrase: 'Mabuot kag mabinuligon ang amon mga kasilingan.',
        targetMeaning: 'Our neighbors are kind and helpful.',
        directionLabel: 'Hiligaynon sentence',
      ),
      LessonQuestion.matching(
        prompt: 'Ipares ang grupo sang pangalan kag kahulugan.',
        leftItems: ['Tawo', 'Butang', 'Sapat', 'Lugar'],
        rightItems: shuffled(['Person', 'Thing', 'Animal', 'Place']),
      ),
      LessonQuestion.matching(
        prompt: 'Ipares ang halimbawa kag kahulugan.',
        leftItems: ['Rina', 'Lapis', 'Kuring', 'Buluthuan'],
        rightItems: shuffled(['Child', 'Pencil', 'Cat', 'School']),
      ),
      LessonQuestion.fillBlank(
        prompt:
            'Kompletoha: Ang ___ nagatuhoy sa ngalan sang tawo, butang, lugar, sapat kag hitabo.',
        answer: 'pangalan',
        choices: shuffled(['pangalan', 'kasilingan', 'buluthuan', 'barangay']),
        targetPhrase:
            'Ang pangalan nagatuhoy sa ngalan sang tawo, butang, lugar, sapat kag hitabo.',
        targetMeaning:
            'A noun refers to the name of a person, thing, place, animal, or event.',
        directionLabel: 'Fill in the blank',
      ),
      LessonQuestion.fillBlank(
        prompt:
            'Kompletoha: Naagyan niya ang iya mga ___ nga nagapaninlo sa Kalye Malinong.',
        answer: 'kasilingan',
        choices: shuffled(['kasilingan', 'lapis', 'kuring', 'bulak']),
        targetPhrase:
            'Naagyan niya ang iya mga kasilingan nga nagapaninlo sa Kalye Malinong.',
        targetMeaning: 'She passed by her neighbors cleaning Malinong Street.',
        directionLabel: 'Fill in the blank',
      ),
    ],
    2 => [
      LessonQuestion.translationChoice(
        prompt: 'Ano ang kahulugan sang "nagalumawlumaw"?',
        answer: 'Daw mahibi',
        choices: shuffled([
          'Daw mahibi',
          'Daw magkadlaw',
          'Daw maglakat',
          'Daw magtulog',
        ]),
        targetPhrase: 'Nagalumawlumaw',
        targetMeaning: 'About to cry',
        directionLabel: 'Vocabulary',
      ),
      LessonQuestion.translationChoice(
        prompt:
            'Ano ang tawag sa pangalan nga nagatudlo sang pat-od nga ngalan?',
        answer: 'Pat-od nga pangalan',
        choices: shuffled([
          'Pat-od nga pangalan',
          'Kinaandan nga pangalan',
          'Kasilingan',
          'Pangalan',
        ]),
        targetPhrase: 'Pat-od nga pangalan',
        targetMeaning: 'Proper noun',
        directionLabel: 'Hiligaynon concept',
      ),
      LessonQuestion.translationChoice(
        prompt:
            'Ano ang tawag sa ordinaryo nga ngalan sang tawo, butang, ukon hitabo?',
        answer: 'Kinaandan nga pangalan',
        choices: shuffled([
          'Kinaandan nga pangalan',
          'Pat-od nga pangalan',
          'Barangay',
          'Buluthuan',
        ]),
        targetPhrase: 'Kinaandan nga pangalan',
        targetMeaning: 'Common noun',
        directionLabel: 'Hiligaynon concept',
      ),
      LessonQuestion.translationChoice(
        prompt: 'Pilion ang pat-od nga pangalan.',
        answer: 'Nanay Rowena',
        choices: shuffled(['Nanay Rowena', 'bata', 'iloy', 'manunudlo']),
        targetPhrase: 'Nanay Rowena',
        targetMeaning: 'Proper noun',
        directionLabel: 'Proper or common',
      ),
      LessonQuestion.arrangeWords(
        prompt: 'Ano ini sa Hiligaynon.',
        answer: 'Si Rina isa ka bata',
        sentenceWords: shuffled(['Si', 'Rina', 'isa', 'ka', 'bata']),
        targetPhrase: 'Si Rina isa ka bata',
        targetMeaning: 'Rina is a child.',
        directionLabel: 'Hiligaynon sentence',
      ),
      LessonQuestion.arrangeWords(
        prompt: 'Ano ini sa Hiligaynon.',
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
        prompt: 'Ipares ang ngalan kag kahulugan.',
        leftItems: ['Rina', 'Nanay Rowena', 'Mayor Basilio', 'Gg. Ramos'],
        rightItems: shuffled(['Child', 'Mother', 'Mayor', 'Mr. Ramos']),
      ),
      LessonQuestion.matching(
        prompt: 'Ipares ang konsepto kag kahulugan.',
        leftItems: [
          'Pat-od nga pangalan',
          'Kinaandan nga pangalan',
          'Nagalumawlumaw',
          'Manunudlo',
        ],
        rightItems: shuffled([
          'Proper noun',
          'Common noun',
          'About to cry',
          'Teacher',
        ]),
      ),
      LessonQuestion.fillBlank(
        prompt:
            'Kompletoha: Ang pat-od nga pangalan nagauumpisa sa ___ nga letra.',
        answer: 'daku',
        choices: shuffled(['daku', 'gamay', 'duha', 'wala']),
        targetPhrase: 'Ang pat-od nga pangalan nagauumpisa sa daku nga letra.',
        targetMeaning: 'A proper noun begins with a capital letter.',
        directionLabel: 'Fill in the blank',
      ),
      LessonQuestion.fillBlank(
        prompt:
            'Kompletoha: Ang kinaandan nga pangalan nagauumpisa sa ___ nga letra.',
        answer: 'gamay',
        choices: shuffled(['gamay', 'daku', 'duha', 'wala']),
        targetPhrase:
            'Ang kinaandan nga pangalan nagauumpisa sa gamay nga letra.',
        targetMeaning: 'A common noun begins with a lowercase letter.',
        directionLabel: 'Fill in the blank',
      ),
    ],
    _ => [
      LessonQuestion.translationChoice(
        prompt:
            'Available pa lang ang Grade 2 source dataset para sa Leksyon 1 kag 2.',
        answer: 'Leksyon 1 kag 2',
        choices: shuffled([
          'Leksyon 1 kag 2',
          'Leksyon 3 kag 4',
          'Leksyon 5',
          'Wala',
        ]),
        targetPhrase: 'Grade 2 source dataset',
        targetMeaning: 'Leksyon 1 and 2',
        directionLabel: 'Dataset status',
      ),
    ],
  };
}
