import '../domain/astronomy.dart';

typedef LunarEditorial = ({
  String prompt,
  String colour,
  int background,
  int foreground,
  String association,
});

const _lunarEditorial = <LunarEditorial>[
  (
    prompt: 'What would you like to begin quietly?',
    colour: 'Midnight Plum',
    background: 0xff37223f,
    foreground: 0xfff6e5ff,
    association: 'Quiet beginnings',
  ),
  (
    prompt: 'What small step would make a difference today?',
    colour: 'Soft Lilac',
    background: 0xffc8abe2,
    foreground: 0xff30213e,
    association: 'Taking a first step',
  ),
  (
    prompt: 'What decision would give you room to move?',
    colour: 'Dusty Iris',
    background: 0xffa58bc4,
    foreground: 0xff251732,
    association: 'Making a decision',
  ),
  (
    prompt: 'What could you refine before sharing it?',
    colour: 'Rose Quartz',
    background: 0xffe2b0c5,
    foreground: 0xff402337,
    association: 'Refining what you have started',
  ),
  (
    prompt: 'What feels worth acknowledging today?',
    colour: 'Moonstone',
    background: 0xffe2dbe8,
    foreground: 0xff30253d,
    association: 'Recognising what has come to fruition',
  ),
  (
    prompt: 'What have you learned that you could pass on?',
    colour: 'Muted Copper',
    background: 0xffc48776,
    foreground: 0xff2d1821,
    association: 'Sharing what you have learned',
  ),
  (
    prompt: 'What obligation are you ready to reconsider?',
    colour: 'Blue Slate',
    background: 0xff8191b1,
    foreground: 0xff151c2d,
    association: 'Reconsidering commitments',
  ),
  (
    prompt: 'Where could you make a little more space for rest?',
    colour: 'Quiet Sage',
    background: 0xffacb7a0,
    foreground: 0xff223027,
    association: 'Making time for rest',
  ),
];

LunarEditorial lunarEditorial(String phase) =>
    _lunarEditorial[lunarPhases.indexOf(phase)];
