import 'package:tudloapp/data/lesson_bank/lesson_bank_item.dart';

const List<LessonTerm> grade1Unit1Leksyon3Terms = [
  LessonTerm(
    unitNumber: 1,
    unitTitle: 'Mga Ginakawilihan Ko',
    gradeLevel: 1,
    type: LessonContentType.word,
    hil: 'edad',
    eng: 'numero sang tuig halin sang pagkabun-ag.',
    exampleSentenceHiligaynon: 'Pila ang imo edad?',
    lessonNumber: 3,
  ),
  LessonTerm(
    unitNumber: 1,
    unitTitle: 'Mga Ginakawilihan Ko',
    gradeLevel: 1,
    type: LessonContentType.word,
    hil: 'nalipay',
    eng: 'nasadyahan',
    exampleSentenceHiligaynon: 'Nalipay ako nga nakilala ko ikaw.',
    lessonNumber: 3,
  ),
  LessonTerm(
    unitNumber: 1,
    unitTitle: 'Mga Ginakawilihan Ko',
    gradeLevel: 1,
    type: LessonContentType.word,
    hil: 'Ngalan',
    eng: 'Ngalan',
    lessonNumber: 3,
  ),
  LessonTerm(
    unitNumber: 1,
    unitTitle: 'Mga Ginakawilihan Ko',
    gradeLevel: 1,
    type: LessonContentType.phrase,
    hil: 'Lugar nga ginapuy-an',
    eng: 'Lugar nga ginapuy-an',
    lessonNumber: 3,
  ),
  LessonTerm(
    unitNumber: 1,
    unitTitle: 'Mga Ginakawilihan Ko',
    gradeLevel: 1,
    type: LessonContentType.phrase,
    hil: 'Ngalan sang Nanay',
    eng: 'Ngalan sang Nanay',
    lessonNumber: 3,
  ),
  LessonTerm(
    unitNumber: 1,
    unitTitle: 'Mga Ginakawilihan Ko',
    gradeLevel: 1,
    type: LessonContentType.phrase,
    hil: 'Ngalan sang Tatay',
    eng: 'Ngalan sang Tatay',
    lessonNumber: 3,
  ),
];

const grade1Unit1Leksyon3SourceLesson = GradeLessonSource(
  unitTitle: 'Mga Ginakawilihan Ko',
  lessonNumber: 3,
  lessonTitle: 'Pagpakilala sa Kaugalingon',
  katuyuan: [
    'Mahatag ang mga importante nga impormasyon tuhoy sa kaugalingon.',
  ],
  nakahibaloKaSini: ['Paano mo ginapakilala ang imo kaugalingon?'],
  pasanyugaIni: [
    'edad - numero sang tuig halin sang pagkabun-ag.',
    'Pila ang imo edad?',
    'nalipay â€“ nasadyahan',
    'Nalipay ako nga nakilala ko ikaw.',
  ],
  pamatiITulukaBasaha: [
    'Ano ang mga impormasyon nga dapat mo mahibaluan natuhoy sa imo kaugalingon?',
    'Pamati-i ang malip-ot nga tinagpong.',
  ],
  readingText: [
    'Ako si MicaÃ¨la Samson, anum ka tuig na ako. Nagapuyo ako sa 26 D. Mabini Street, lloilo City. Sanday Ginuong Juan kag Ginang Marites Samson ang akon mga ginikanan.',
    'Nalipay ako nga makilala ka.',
  ],
  istoryahanNaton: [
    'Sabti ang mga pamangkot.',
    '1.Ano ang mga impormasyon nga ginhambal sang bata tuhoy sa iya kaugalingon? Ngaa kinahanglan gid nga nahibaluan mo ang mga ini?',
    '2. Ikaw, paano mo ginapakilala ang imo kaugalingon?',
  ],
  paminsaraIni: [
    'May mga kinahanglan gid nga impormasyon tuhoy sa aton kaugalingon nga dapat naton mahibaluan.',
    'Makabulig ini agud makilala kita sang madamo nga tawo.',
  ],
  masaranganKoIni: [
    'A. Pamati-i ang pagpakilala nga ihambal sang manunudlo sunod ikaw naman ang magpakilala sa imo kaugalingon. Ihambal ang impormasyon tuhoy sa imo kaugalingon.',
    'Ngalan: _________________________________',
    'Edad: _________________________________',
    'Lugar nga ginapuy-an: _________________________________',
    'Ngalan sang Nanay: _________________________________',
    'Ngalan sang Tatay: _________________________________',
    'B. Tun-i ang pagpakilala sa imo kaugalingon gamit ang graphic organizer. Pun-a sang detalye ukon impormasyon nga ginapangayo.',
  ],
  activities: [
    GradeLessonActivity(
      activityType: 'pagpakilala',
      questions: [
        'Pamati-i ang pagpakilala nga ihambal sang manunudlo sunod ikaw naman ang magpakilala sa imo kaugalingon. Ihambal ang impormasyon tuhoy sa imo kaugalingon.',
        'Ngalan: _________________________________',
        'Edad: _________________________________',
        'Lugar nga ginapuy-an: _________________________________',
        'Ngalan sang Nanay: _________________________________',
        'Ngalan sang Tatay: _________________________________',
      ],
    ),
    GradeLessonActivity(
      activityType: 'graphic organizer',
      questions: [
        'Tun-i ang pagpakilala sa imo kaugalingon gamit ang graphic organizer. Pun-a sang detalye ukon impormasyon nga ginapangayo.',
      ],
      imageDescription: 'graphic organizer',
    ),
  ],
);
