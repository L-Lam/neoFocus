import '../models/buddy.dart';

final List<Buddy> allBuddies = [
  // Common
  const Buddy(
    id: '1',
    name: 'Bobby',
    rarity: BuddyRarity.common,
    description: 'Whenever you can\'t concentrate, Bobby will be here for you!',
    image: 'assets/bobbys/Bobby.png',
  ),

  // Rare
  const Buddy(
    id: '2',
    name: 'Bao Bobby',
    rarity: BuddyRarity.rare,
    description:
        'Bobby has come from pre-industrial China to teach you their wisdom!\n'
        '"Remember, if you are ever feeling down, appreciate that you are '
        'not hoeing in the fields. Every grain of rice is a farmer\'s hard '
        'work."',
    image: 'assets/bobbys/BaoBobby.png',
  ),
  const Buddy(
    id: '3',
    name: 'Brain Bobby',
    rarity: BuddyRarity.rare,
    description:
        'Bobby has come fresh from the cranium of your skull! Please do not '
        'overload it with stimulation. Uh, what? Bobby looks kinda cute? '
        'Why of course, it is your big beautiful brain after all!',
    image: 'assets/bobbys/BrainBobby.png',
  ),
  const Buddy(
    id: '4',
    name: 'Neko Bobby',
    rarity: BuddyRarity.rare,
    description:
        'Bobby has turned into a domesticated calico cat. It is eager to daze '
        'you with its cuteness! Everyone needs some joy in their lives!',
    image: 'assets/bobbys/NekoBobby.png',
  ),
  const Buddy(
    id: '5',
    name: 'Nerdy Bobby',
    rarity: BuddyRarity.rare,
    description:
        'Bobby has become an absolute GEEK. Bobby has acquired so much knowledge '
        'that it is sprouting on Bobby\'s head! "Errm actually... this '
        'sproutling is purely cosmetic. It is impossible to grow a living plant '
        'on one\'s head unless it receives a source of nutrients and water. '
        'Therefore, the roots of the system would likely have to penetrate the '
        'skull and bypass the meninges to gain access to the brain. That in '
        'itself is already a challenge. However, even if the plant does '
        'accomplish this, the change in environment would most likely be '
        'unfeasible for the host. In other words, the plant would act as a '
        'parasite on one\'s brain, redirecting limited nutrients towards itself '
        'at the expense of the host\'s brain. Furthermore, the roots of the '
        'system would increase intracranial pressure, which mimics the effects '
        'of benign brain tumors, causing permanent brain damage that ultimately '
        'leads to death. Therefore, these limitations would make it impossible '
        'for a living sproutling and its host to coexist, disproving your '
        'assertion."',
    image: 'assets/bobbys/NerdyBobby.png',
  ),

  // Exotic
  const Buddy(
    id: '6',
    name: 'Cake Bobby',
    rarity: BuddyRarity.exotic,
    description:
        'In order to improve your concentration and motivation, Bobby has turned '
        'into a cupcake! A sugary treat is not only tasty, but it provides more'
        ' energy for studying! Wait, you\'re not going to eat your friend, are '
        'you?',
    image: 'assets/bobbys/CakeBobby.png',
  ),
  const Buddy(
    id: '7',
    name: 'Clockwork Bobby',
    rarity: BuddyRarity.exotic,
    description:
        'Bobby has come from the industrial-Victorian timeline where time '
        'dominates at the premium currency! As a trained time manager, '
        'Bobby wants you to remember one thing: "time waits for no one, '
        'and time lost is lost forever. Liquidate as much of it as you can."',
    image: 'assets/bobbys/ClockworkBobby.png',
  ),
  const Buddy(
    id: '8',
    name: 'Enlightened Bobby',
    rarity: BuddyRarity.exotic,
    description:
        'Bobby sat under a tree and ascended to nirvana! Bobby does not want to'
        ' start a religion, but just wants to share wisdom.\n"Study '
        'is inevitable, but suffering is optional."\nWhat wise words!',
    image: 'assets/bobbys/EnlightenedBobby.png',
  ),
  const Buddy(
    id: '9',
    name: 'Fibonacci Bobby',
    rarity: BuddyRarity.exotic,
    description:
        'Bobbby has found its passion in Neo-Romanticism art! Bobby is trying to '
        'learn more about the golden ratio NOT to win a cross-country race on '
        'horseback or regain the ability to walk, but to create more visually '
        'appealing artworks.',
    image: 'assets/bobbys/FibonacciBobby.png',
  ),

  // Unique
  const Buddy(
    id: '10',
    name: 'Freudian Bobby',
    rarity: BuddyRarity.unique,
    description:
        'Bobby has finally found the harmony between the superego and the id, and '
        'the newfound wisdom has manifested into a unique gradient skin. '
        'Whether one views Bobby from the left or the right, they should '
        'consciously recognize that the other side still exists; it is just'
        'hidden from view.',
    image: 'assets/bobbys/FreudianBobby.png',
    source: [BuddySource.shop],
  ),
  const Buddy(
    id: '11',
    name: 'Magical Bobby',
    rarity: BuddyRarity.unique,
    description:
        '"~~Witch of Concentration, Bobby has arrived! ;) I cast upon thee, my '
        'magical speciality: Arcana Focus Pocus!!! Oh? Fret not, for the '
        'eldritch horrors thou dost ponders, I shall purge them posthaste!~~"',
    image: 'assets/bobbys/MagicalBobby.png',
  ),
];
