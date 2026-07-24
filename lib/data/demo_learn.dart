class DemoLearnTopic {
  const DemoLearnTopic({
    required this.title,
    required this.iconLabel,
    required this.summary,
    required this.body,
    required this.source,
  });

  final String title;
  final String iconLabel;
  final String summary;
  final String body;
  final String source;
}

const demoLearnTopics = <DemoLearnTopic>[
  DemoLearnTopic(
    title: 'Physical Health',
    iconLabel: 'body',
    summary: 'Everyday care for your body.',
    body:
        'Check in with how you feel. Sleep, movement, and regular checkups '
        'help you stay well. Ask a peer or clinic if something feels off.',
    source: 'CDC',
  ),
  DemoLearnTopic(
    title: 'Mental Health',
    iconLabel: 'mind',
    summary: 'Support for your mind and mood.',
    body:
        'Feeling stressed or low is common. Talking with a peer, counselor, '
        'or trusted person can help. Crisis lines are under Help Now.',
    source: 'SAMHSA',
  ),
  DemoLearnTopic(
    title: 'Nutrition',
    iconLabel: 'food',
    summary: 'Simple ideas for eating well.',
    body:
        'You do not need a perfect diet. Aim for regular meals when you can, '
        'drink water, and ask your clinic about food resources nearby.',
    source: 'USDA',
  ),
  DemoLearnTopic(
    title: 'Exercise',
    iconLabel: 'move',
    summary: 'Move in ways that fit your day.',
    body:
        'Walking, stretching, or light activity counts. Start small. Stop if '
        'you feel pain, and ask a provider before starting a new routine.',
    source: 'CDC',
  ),
  DemoLearnTopic(
    title: 'Medications',
    iconLabel: 'meds',
    summary: 'Keep track of what you take.',
    body:
        'Know the name, dose, and why you take each medicine. Use My Health '
        'as a memory aid — not medical advice. Ask your pharmacist questions.',
    source: 'FDA',
  ),
  DemoLearnTopic(
    title: 'Preventive Care',
    iconLabel: 'shield',
    summary: 'Screenings and shots that help.',
    body:
        'Vaccines and checkups can catch problems early. Ask your clinic which '
        'ones are right for you this year.',
    source: 'CDC',
  ),
];
