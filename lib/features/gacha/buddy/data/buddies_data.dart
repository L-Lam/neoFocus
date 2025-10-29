import '../models/buddy.dart';

final List<Buddy> allBuddies = [
  // Common
  const Buddy(
    id: '1',
    name: 'Suki',
    rarity: BuddyRarity.common,
    species: 'Tabby cat',
    description:
        'Utterly heartbroken his owners misspelled his name. Eats excessively '
        'to cope with the pain.',
    image: 'assets/images/buddies/SukiFinal.png',
  ),
  const Buddy(
    id: '2',
    name: 'Little Bell',
    rarity: BuddyRarity.common,
    species: 'Angora rabbit',
    description:
        'Huge and fluffy! Sits and snoozes around all day. Cons: her excessive '
        'fluff makes you sneeze a lot.',
    image: 'assets/images/buddies/LittleBellFinal.png',
  ),

  // Rare
  const Buddy(
    id: '3',
    name: 'Queen',
    rarity: BuddyRarity.rare,
    species: 'Sphynx cat',
    description:
        'Used to be a killer, but became a changed cat after losing a life. '
        'Secretly planning a rebellion against his owner. The reason? They '
        'won\'t get him a scratching post.',
    image: 'assets/images/buddies/QueenFinal.png',
  ),
  const Buddy(
    id: '4',
    name: 'Moonlight',
    rarity: BuddyRarity.rare,
    species: 'Grey wolf',
    description:
        'A respectable young fella in the wolf pack. Soon, he will lead his '
        'pack. His friends don\'t know this, but he often howls beneath the '
        'full moon to feel more ALPHA.',
    image: 'assets/images/buddies/MoonlightFinal.png',
  ),

  // Epic
  const Buddy(
    id: '5',
    name: 'Chroma T',
    rarity: BuddyRarity.epic,
    species: 'Barn owl',
    description:
        'Always groomed and dripped out for the ladies. Still doesn\'t get any. '
        'Maybe it\'s because of those eyes...',
    image: 'assets/images/buddies/ChromatiqueFinal.png',
  ),
  const Buddy(
    id: '6',
    name: 'Love Dream',
    rarity: BuddyRarity.epic,
    species: 'American flamingo',
    description:
        'He is very much in love. Wears a fedora and tie to look extra '
        'professional. Really though, he\'s just a cornball, no offense. '
        'Takes dance classes in hopes of attracting his crush one day.',
    image: 'assets/images/buddies/LoveDreamFinal.png',
  ),

  // Legendary
  const Buddy(
    id: '7',
    name: 'Winter Wind',
    rarity: BuddyRarity.legendary,
    species: 'Arctic fox',
    description:
        'She is the princess of the snow, wielding a bone-chilling gaze and an '
        'ice-cold demeanor. Stalks her prey, waiting for the right time to '
        ' strike. It\'s totally not because she is awkward!',
    image: 'assets/images/buddies/WinterWindFinal.png',
  ),
  const Buddy(
    id: '8',
    name: 'Revolutionary',
    rarity: BuddyRarity.legendary,
    species: 'Bald eagle',
    description:
        'Always angry and aggressive. Led a coup to take administration of an '
        'also angry nation. Almost conquered the world before he got exiled '
        'to a tiny island. TWICE.',
    image: 'assets/images/buddies/RevolutionaryFinal.png',
  ),
];
