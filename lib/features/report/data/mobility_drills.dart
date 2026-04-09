import '../../../domain/models.dart';

// ---------------------------------------------------------------------------
// Static drill content database keyed by CompensationType.
// Each type has 2+ drills with 3-5 action-oriented instruction steps.
// Language follows body-path conventions: no jargon, plain movement cues.
// ---------------------------------------------------------------------------

const mobilityDrillsByType = <CompensationType, List<MobilityDrill>>{
  CompensationType.ankleRestriction: [
    MobilityDrill(
      name: 'Ankle Circles',
      targetArea: 'ankle',
      durationSeconds: 60,
      compensationType: CompensationType.ankleRestriction,
      steps: [
        'Sit with one leg crossed over the other so your foot hangs free',
        'Slowly draw large circles with your toes, moving only at the ankle',
        'Complete 10 circles in each direction',
        'Switch legs and repeat',
      ],
    ),
    MobilityDrill(
      name: 'Wall Ankle Mobilization',
      targetArea: 'ankle',
      durationSeconds: 90,
      compensationType: CompensationType.ankleRestriction,
      steps: [
        'Stand facing a wall with one foot about a fist-width from the base',
        'Keep your heel flat on the ground',
        'Push your knee forward toward the wall, moving only at the ankle',
        'Hold for 5 seconds, then return to the start',
        'Repeat 10 times on each side',
      ],
    ),
  ],
  CompensationType.kneeValgus: [
    MobilityDrill(
      name: 'Clamshells',
      targetArea: 'hip',
      durationSeconds: 90,
      compensationType: CompensationType.kneeValgus,
      steps: [
        'Lie on your side with knees bent at about 45 degrees and feet together',
        'Keep your feet touching and lift your top knee as high as comfortable',
        'Pause briefly at the top, then lower slowly',
        'Complete 15 repetitions, then switch sides',
      ],
    ),
    MobilityDrill(
      name: 'Single-Leg Glute Bridge',
      targetArea: 'hip',
      durationSeconds: 90,
      compensationType: CompensationType.kneeValgus,
      steps: [
        'Lie on your back with knees bent and feet flat on the floor',
        'Lift one foot off the ground and extend that leg straight',
        'Press through the planted foot to raise your hips until your body forms a straight line',
        'Hold for 2 seconds at the top, then lower with control',
        'Repeat 10 times on each side',
      ],
    ),
  ],
  CompensationType.hipDrop: [
    MobilityDrill(
      name: 'Side-Lying Hip Abduction',
      targetArea: 'hip',
      durationSeconds: 90,
      compensationType: CompensationType.hipDrop,
      steps: [
        'Lie on your side with legs straight and stacked',
        'Keep your hips square -- do not roll backward',
        'Slowly lift your top leg about 12 inches',
        'Hold briefly, then lower with control',
        'Complete 15 repetitions, then switch sides',
      ],
    ),
    MobilityDrill(
      name: 'Standing Hip Hike',
      targetArea: 'hip',
      durationSeconds: 60,
      compensationType: CompensationType.hipDrop,
      steps: [
        'Stand on a step or sturdy platform with one foot hanging off the edge',
        'Let the hanging leg drop so that hip lowers below the standing hip',
        'Use the muscles on the standing side to hike the hanging hip back to level',
        'Repeat 12 times on each side',
      ],
    ),
  ],
  CompensationType.trunkLean: [
    MobilityDrill(
      name: 'Pallof Press Hold',
      targetArea: 'core',
      durationSeconds: 60,
      compensationType: CompensationType.trunkLean,
      steps: [
        'Anchor a light resistance band at chest height',
        'Stand sideways to the anchor and hold the band at your chest with both hands',
        'Press the band straight out in front of you, resisting the pull to rotate',
        'Hold for 10 seconds, then bring hands back to chest',
        'Repeat 5 times on each side',
      ],
    ),
    MobilityDrill(
      name: 'Dead Bug',
      targetArea: 'core',
      durationSeconds: 90,
      compensationType: CompensationType.trunkLean,
      steps: [
        'Lie on your back with arms reaching toward the ceiling and knees bent at 90 degrees',
        'Press your lower back firmly into the floor',
        'Slowly extend your right arm overhead and left leg straight out, hovering above the floor',
        'Return to the start and repeat on the opposite side',
        'Alternate for 10 repetitions on each side',
      ],
    ),
  ],
};

// ---------------------------------------------------------------------------
// Stability-focused drills for hypermobility findings.
// These emphasize control and strength, not range of motion.
// ---------------------------------------------------------------------------

const stabilityDrills = <MobilityDrill>[
  MobilityDrill(
    name: 'Slow Eccentric Single-Leg Squat',
    targetArea: 'knee and hip',
    durationSeconds: 90,
    compensationType: CompensationType.kneeValgus,
    steps: [
      'Stand on one leg with the other foot just off the floor',
      'Slowly bend your standing knee over 5 seconds, keeping it tracking over your toes',
      'Lower only as far as you can control without wobbling',
      'Press back up with control',
      'Repeat 8 times on each side',
    ],
  ),
  MobilityDrill(
    name: 'Banded Terminal Knee Extension',
    targetArea: 'knee',
    durationSeconds: 60,
    compensationType: CompensationType.kneeValgus,
    steps: [
      'Loop a light band behind your knee and anchor it behind you',
      'Stand facing away from the anchor with a slight bend in your knee',
      'Straighten your knee fully against the band resistance',
      'Hold for 3 seconds, then slowly release',
      'Repeat 12 times on each side',
    ],
  ),
];
