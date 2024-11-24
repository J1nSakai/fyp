import 'package:flutter/material.dart';

class CommandDetails {
  final String command;
  final String description;
  final List<String>? variations;
  final String? imagePath;

  CommandDetails({
    required this.command,
    required this.description,
    this.variations,
    this.imagePath,
  });
}

class VoiceCommandsDialog extends StatefulWidget {
  const VoiceCommandsDialog({super.key});

  @override
  State<VoiceCommandsDialog> createState() => _VoiceCommandsDialogState();
}

class _VoiceCommandsDialogState extends State<VoiceCommandsDialog> {
  CommandDetails? _selectedCommand;
  String _selectedCategory = 'Base Commands';
  final List<CommandDetails> baseCommands = [
    CommandDetails(
      imagePath: 'base_command_pics/default_base.png',
      command: '"create base"',
      description:
          'Creates a base on the current floor with default dimensions (30ft by 20ft).',
      variations: ['new base', 'add base', 'create base', 'base'],
    ),
    CommandDetails(
      command: '"create a base that is <width> ft by <height> ft"',
      description:
          'Creates a base with specified width and height. If a base is already present, it overrides the base to the new base with specified width and height.',
      variations: [
        'make a base that is <width> ft by <height> ft',
        'base <width> <height>',
      ],
    ),
    CommandDetails(
      command: '"remove base"',
      description: 'Removes the current base from the floor.',
      variations: ['delete base', 'remove base'],
    ),
    // Add more commands...
  ];

  final List<CommandDetails> roomCommands = [
    CommandDetails(
      command: '"add room"',
      description:
          'Creates a room with default dimensions (5ft by 5ft) within the base.',
      variations: [
        "add another room",
        "add a new room",
        "create a room",
        "room"
      ],
      imagePath: 'room_command_pics/default_room.png',
    ),
    CommandDetails(
      command: '"add a room that is <width> ft by <height> ft"',
      description: 'Creates a room with specified width and height.',
      variations: [
        'make a room that is <width> ft by <height> ft',
        'room <width> <height>',
      ],
    ),
    CommandDetails(
      command: '"select room <room number>"',
      description:
          'Selects the room with the specified number to perform actions on it. The selected room will have a red border around it.',
      imagePath: "room_command_pics/select_room.png",
    ),
    CommandDetails(
      command: '"move to <position>"',
      description: "Requirements:\n"
          "   • The desired room should be selected.\n\n"
          "Moves the selected room to a specified position inside the base. This <position> could be:\n"
          "   • \"center\"\n"
          "        Moves the room to the center of the base.\n"
          "   • \"top left\"\n"
          "        Moves the room to the top-left corner of the base.\n"
          "   • \"top right\"\n"
          "        Moves the room to the top-right corner of the base.\n"
          "   • \"bottom left\"\n"
          "        Moves the room to the bottom-left corner of the base.\n"
          "   • \"bottom right\"\n"
          "        Moves the room to the bottom-right corner of the base.",
    ),
    CommandDetails(
      command: '"move <distance> ft to <direction>"',
      description: 'Requirement:\n'
          '•  The desired room must be selected.\n\n'
          'Moves the selected room to a specified distance, relative to the specified direction.\n\n'
          '   • The <distance> could be any number. It represents the displacement of the room (in ft).\n'
          '   • The <direction> could be:\n'
          '       • "right" or "east"\n'
          '       • "left" or "west"\n'
          '       • "up" or "north"\n'
          '       • "down" or "south"\n',
    ),
    CommandDetails(
      command: '"move to <direction> of <reference room>"',
      description: "Requirements:\n"
          "   • The desired room must be selected.\n"
          "   • The reference room must be present on the current floor.\n\n"
          "Moves the selected room to the specified direction, relative to a reference room.\n"
          "   • The <direction> could be:\n"
          "       • \"right\" or \"east\"\n"
          "       • \"left\" or \"west\"\n"
          "       • \"above\" or \"north\"\n"
          "       • \"below\" or \"south\"\n"
          "The <reference room> is the name of the room that you want to move the selected room relative to (e.g. \"room 1\", \"bedroom\", etc.).",
    ),
    CommandDetails(
      command: '"move to <direction> of <reference cutout>"',
      description: "Requirements:\n"
          "   • The desired room must be selected.\n"
          "   • The reference cutout must be present on the current floor.\n\n"
          "Moves the selected room to the specified direction, relative to a reference cutout.\n"
          "   • The <direction> could be:\n"
          "       • \"right\" or \"east\"\n"
          "       • \"left\" or \"west\"\n"
          "       • \"above\" or \"north\"\n"
          "       • \"below\" or \"south\"\n"
          "The <reference cutout> is the name of the cutout that you want to move the selected room relative to (e.g. \"cutout 1\", etc.).",
    ),
    CommandDetails(
      command: '"move to <direction> of <reference stairs>"',
      description: "Requirements:\n"
          "   • The desired room must be selected.\n"
          "   • The reference stairs must be present on the current floor.\n\n"
          "Moves the selected room to the specified direction, relative to a reference stairs.\n"
          "   • The <direction> could be:\n"
          "       • \"right\" or \"east\"\n"
          "       • \"left\" or \"west\"\n"
          "       • \"above\" or \"north\"\n"
          "       • \"below\" or \"south\"\n"
          "The <reference stairs> is the name of the stairs that you want to move the selected room relative to (e.g. \"stairs 1\", etc.).",
    ),
    CommandDetails(
      command: '"resize to <width> ft by <height> ft"',
      description: "Requirements:\n"
          "   • The desired room must be selected.\n\n"
          "Resizes the selected room to the specified width and height.\n"
          "   • The <width> and <height> could be any number. They represent the new dimensions of the room (in ft).",
      variations: [
        "change to <width> ft by <height> ft",
        "change <width> <height>",
        "resize to <width> <height>",
      ],
    ),
    CommandDetails(
      command: '"resize width to <width> ft"',
      description: "Requirements:\n"
          "   • The desired room must be selected.\n\n"
          "Resizes the selected room to the specified width.\n"
          "   • The <width> could be any number. It represents the new width of the room (in ft).",
      variations: [
        "change width to <width> ft",
        "resize width to <width>",
        "increase width to <width>",
        "decrease width to <width>",
      ],
    ),
    CommandDetails(
      command: '"resize height to <height> ft"',
      description: "Requirements:\n"
          "   • The desired room must be selected.\n\n"
          "Resizes the selected room to the specified height.\n"
          "   • The <height> could be any number. It represents the new height of the room (in ft).",
      variations: [
        "change height to <height> ft",
        "resize height to <height>",
        "increase height to <height>",
        "decrease height to <height>",
      ],
    ),
    CommandDetails(
      command: '"rename to <new name>"',
      description: "Requirements:\n"
          "   • The desired room must be selected.\n\n"
          "Renames the selected room to the specified new name.\n"
          "   • The <new name> is the name that you want to rename the selected room to (e.g. \"bedroom\", \"bathroom\", \"Living room\", etc.).",
      variations: ["rename <new name>"],
    ),
    CommandDetails(
      command: '"hide walls"',
      description: "Requirements:\n"
          "   • The desired room must be selected.\n\n"
          "Hides the walls of the selected room.",
    ),
    CommandDetails(
      command: '"show walls"',
      description: "Requirements:\n"
          "   • The desired room must be selected.\n\n"
          "Shows the walls of the selected room.",
    ),
    CommandDetails(
      command: '"remove room"',
      description: "Requirements:\n"
          "   • The desired room must be selected.\n\n"
          "Removes the selected room from the base.",
    ),
    CommandDetails(
      command: '"remove all rooms"',
      description: "Removes all rooms from the base.",
      variations: ["remove rooms"],
    ),
    CommandDetails(
      command: '"remove last room"',
      description: "Removes the last room added to the base.",
    ),
    CommandDetails(
      command: '"deselect"',
      description: 'Deselects the currently selected room.',
    ),
  ];

  final List<CommandDetails> stairsCommands = [
    CommandDetails(
      command: '"add stairs"',
      description: 'Creates a stair case within the base.',
      variations: ['add new stairs', 'stairs'],
      imagePath: 'stairs_command_pics/default_stairs.png',
    ),
    CommandDetails(
      command: '"add stairs that is <width> ft by <length> ft"',
      description: 'Creates a stair case with specified width and length.',
      variations: [
        'make a stairs that is <width> ft by <length> ft',
        'stairs <width> <length>',
      ],
    ),
    CommandDetails(
      command: '"select stairs <stairs number>"',
      description:
          'Selects the stairs with the specified number to perform actions on it. The selected stairs will have a blue border around it.',
      imagePath: 'stairs_command_pics/select_stairs.png',
    ),
    CommandDetails(
      command: '"move to <position>"',
      description: "Requirements:\n"
          "   • The desired stairs must be selected.\n\n"
          "Moves the selected stairs to a specified position inside the base.\n"
          "   • The <position> could be:\n"
          "       • \"center\"\n"
          "           Moves the stairs to the center of the base.\n"
          "       • \"top left\"\n"
          "           Moves the stairs to the top-left corner of the base.\n"
          "       • \"top right\"\n"
          "           Moves the stairs to the top-right corner of the base.\n"
          "       • \"bottom left\"\n"
          "           Moves the stairs to the bottom-left corner of the base.\n"
          "       • \"bottom right\"\n"
          "           Moves the stairs to the bottom-right corner of the base.",
    ),
    CommandDetails(
      command: '"move <distance> ft to <direction>"',
      description: 'Requirements:\n'
          '   • The desired stairs must be selected.\n\n'
          'Moves the selected stairs to a specified distance, relative to the specified direction.\n\n'
          '   • The <distance> could be any number. It represents the displacement of the stairs (in ft).\n'
          '   • The <direction> could be:\n'
          '       • "right" or "east"\n'
          '       • "left" or "west"\n'
          '       • "up" or "north"\n'
          '       • "down" or "south"\n',
    ),
    CommandDetails(
      command: '"move to <direction> of <reference stairs>"',
      description: 'Requirements:\n'
          '   • The desired stairs must be selected.\n'
          '   • The reference stairs must be present on the current floor.\n\n'
          'Moves the selected stairs to the specified direction, relative to a reference stairs.\n'
          '   • The <direction> could be:\n'
          '       • "right" or "east"\n'
          '       • "left" or "west"\n'
          '       • "above" or "north"\n'
          '       • "below" or "south"\n'
          'The <reference stairs> is the name of the stairs that you want to move the selected stairs relative to (e.g. "stairs 1", etc.).',
    ),
    CommandDetails(
      command: '"move to <direction> of <reference room>"',
      description: 'Requirements:\n'
          '   • The desired stairs must be selected.\n'
          '   • The reference room must be present on the current floor.\n\n'
          'Moves the selected stairs to the specified direction, relative to a reference room.\n'
          '   • The <direction> could be:\n'
          '       • "right" or "east"\n'
          '       • "left" or "west"\n'
          '       • "above" or "north"\n'
          '       • "below" or "south"\n'
          'The <reference room> is the name of the room that you want to move the selected stairs relative to (e.g. "room 1", "bedroom", etc.).',
    ),
    CommandDetails(
      command: '"move to <direction> of <reference cutout>"',
      description: 'Requirements:\n'
          '   • The desired stairs must be selected.\n'
          '   • The reference cutout must be present on the current floor.\n\n'
          'Moves the selected stairs to the specified direction, relative to a reference cutout.\n'
          '   • The <direction> could be:\n'
          '       • "right" or "east"\n'
          '       • "left" or "west"\n'
          '       • "above" or "north"\n'
          '       • "below" or "south"\n'
          'The <reference cutout> is the name of the cutout that you want to move the selected stairs relative to (e.g. "cutout 1", etc.).',
    ),
    CommandDetails(
      command: '"resize to <width> ft by <length> ft"',
      description: 'Requirements:\n'
          '   • The desired stairs must be selected.\n\n'
          'Resizes the selected stairs to the specified width and length.\n'
          '   • The <width> and <length> could be any number. They represent the new dimensions of the stairs (in ft).',
      variations: [
        'change to <width> ft by <length> ft',
        'change <width> <length>',
        'resize to <width> <length>',
      ],
    ),
    CommandDetails(
      command: '"resize width to <width> ft"',
      description: 'Requirements:\n'
          '   • The desired stairs must be selected.\n\n'
          'Resizes the selected stairs to the specified width.\n'
          '   • The <width> could be any number. It represents the new width of the stairs (in ft).',
      variations: [
        'change width to <width> ft',
        'increase width to <width>',
        'decrease width to <width>',
      ],
    ),
    CommandDetails(
      command: '"resize length to <length> ft"',
      description: 'Requirements:\n'
          '   • The desired stairs must be selected.\n\n'
          'Resizes the selected stairs to the specified length.\n'
          '   • The <length> could be any number. It represents the new length of the stairs (in ft).',
      variations: [
        'change length to <length> ft',
        'increase length to <length>',
        'decrease length to <length>',
      ],
    ),
    CommandDetails(
      command: '"rotate"',
      description: 'Requirements:\n'
          '   • The desired stairs must be selected.\n\n'
          'Rotates the selected stairs 90 degrees clockwise.',
      variations: [
        'rotate right',
        'rotate clockwise',
      ],
      imagePath: 'stairs_command_pics/rotate_clockwise.png',
    ),
    CommandDetails(
      command: '"rotate left"',
      description: 'Requirements:\n'
          '   • The desired stairs must be selected.\n\n'
          'Rotates the selected stairs 90 degrees counterclockwise.',
      variations: [
        'rotate anticlockwise',
      ],
      imagePath: 'stairs_command_pics/rotate_counterclockwise.png',
    ),
    CommandDetails(
      command: '"remove stairs"',
      description: 'Requirements:\n'
          '   • The desired stairs must be selected.\n\n'
          'Removes the selected stairs from the base.',
    ),
    CommandDetails(
      command: '"deselect"',
      description: 'Deselects the currently selected stairs.',
    ),
  ];

  final List<CommandDetails> cutoutCommands = [
    CommandDetails(
      command: '"add cutout"',
      description: 'Creates a cutout within the base.',
      variations: ['add new cutout', 'add cut out', 'add new cut out'],
      imagePath: 'cutout_command_pics/default_cutout.png',
    ),
    CommandDetails(
      command: '"add cutout that is <width> ft by <height> ft"',
      description: 'Creates a cutout with specified width and height.',
      variations: [
        'make a cutout that is <width> ft by <height> ft',
        'add cutout <width> <height>',
      ],
    ),
    CommandDetails(
      command: '"select cutout <cutout number>"',
      description:
          'Selects the cutout with the specified number to perform actions on it. The selected cutout will have a blue border around it.',
      imagePath: 'cutout_command_pics/select_cutout.png',
      variations: ['select cut out <cutout number>'],
    ),
    CommandDetails(
      command: '"move to <position>"',
      description: 'Requirements:\n'
          '   • The desired cutout must be selected.\n\n'
          'Moves the selected cutout to a specified position inside the base.\n'
          '   • The <position> could be:\n'
          '       • "center"\n'
          '           Moves the cutout to the center of the base.\n'
          '       • "top left"\n'
          '           Moves the cutout to the top-left corner of the base.\n'
          '       • "top right"\n'
          '           Moves the cutout to the top-right corner of the base.\n'
          '       • "bottom left"\n'
          '           Moves the cutout to the bottom-left corner of the base.\n'
          '       • "bottom right"\n'
          '           Moves the cutout to the bottom-right corner of the base.',
    ),
    CommandDetails(
      command: '"move <distance> ft to <direction>"',
      description: 'Requirements:\n'
          '   • The desired cutout must be selected.\n\n'
          'Moves the selected cutout to a specified distance, relative to the specified direction.\n\n'
          '   • The <distance> could be any number. It represents the displacement of the cutout (in ft).\n'
          '   • The <direction> could be:\n'
          '       • "right" or "east"\n'
          '       • "left" or "west"\n'
          '       • "up" or "north"\n'
          '       • "down" or "south"\n',
    ),
    CommandDetails(
      command: '"move to <direction> of <reference cutout>"',
      description: 'Requirements:\n'
          '   • The desired cutout must be selected.\n'
          '   • The reference cutout must be present on the current floor.\n\n'
          'Moves the selected cutout to the specified direction, relative to a reference cutout.\n'
          '   • The <direction> could be:\n'
          '       • "right" or "east"\n'
          '       • "left" or "west"\n'
          '       • "above" or "north"\n'
          '       • "below" or "south"\n'
          '   • The <reference cutout> is the name of the cutout that you want to move the selected cutout relative to (e.g. "cutout 1", etc.).',
    ),
    CommandDetails(
      command: '"move to <direction> of <reference room>"',
      description: 'Requirements:\n'
          '   • The desired cutout must be selected.\n'
          '   • The reference room must be present on the current floor.\n\n'
          'Moves the selected cutout to the specified direction, relative to a reference room.\n'
          '   • The <direction> could be:\n'
          '       • "right" or "east"\n'
          '       • "left" or "west"\n'
          '       • "above" or "north"\n'
          '       • "below" or "south"\n'
          '   • The <reference room> is the name of the room that you want to move the selected cutout relative to (e.g. "room 1", "bedroom", etc.).',
    ),
    CommandDetails(
      command: '"move to <direction> of <reference stairs>"',
      description: 'Requirements:\n'
          '   • The desired cutout must be selected.\n'
          '   • The reference stairs must be present on the current floor.\n\n'
          'Moves the selected cutout to the specified direction, relative to a reference stairs.\n'
          '   • The <direction> could be:\n'
          '       • "right" or "east"\n'
          '       • "left" or "west"\n'
          '       • "above" or "north"\n'
          '       • "below" or "south"\n'
          '   • The <reference stairs> is the name of the stairs that you want to move the selected cutout relative to (e.g. "stairs 1", etc.).',
    ),
    CommandDetails(
      command: '"resize to <width> ft by <height> ft"',
      description: 'Requirements:\n'
          '   • The desired cutout must be selected.\n\n'
          'Resizes the selected cutout to the specified width and height.\n'
          '   • The <width> and <height> could be any number. They represent the new dimensions of the cutout (in ft).',
      variations: [
        'change to <width> ft by <height> ft',
        'change <width> <height>',
        'resize to <width> <height>',
      ],
    ),
    CommandDetails(
      command: '"resize width to <width> ft"',
      description: 'Requirements:\n'
          '   • The desired cutout must be selected.\n\n'
          'Resizes the selected cutout to the specified width.\n'
          '   • The <width> could be any number. It represents the new width of the cutout (in ft).',
      variations: [
        'change width to <width> ft',
        'increase width to <width>',
        'decrease width to <width>',
      ],
    ),
    CommandDetails(
      command: '"resize height to <height> ft"',
      description: 'Requirements:\n'
          '   • The desired cutout must be selected.\n\n'
          'Resizes the selected cutout to the specified height.\n'
          '   • The <height> could be any number. It represents the new height of the cutout (in ft).',
      variations: [
        'change height to <height> ft',
        'increase height to <height>',
        'decrease height to <height>',
      ],
    ),
    CommandDetails(
      command: '"remove cutout"',
      description: 'Requirements:\n'
          '   • The desired cutout must be selected.\n\n'
          'Removes the selected cutout from the base.',
      variations: ['remove cut out'],
    ),
    CommandDetails(
      command: '"deselect"',
      description: 'Deselects the currently selected cutout.',
    ),
  ];

  final List<CommandDetails> doorCommands = [
    CommandDetails(
      command: '"add door on <side>"',
      description:
          'Creates a door on the specified side of the selected room or cutout.\n'
          '   • The <side> could be:\n'
          '       • "left" or "west"\n'
          '       • "right" or "east"\n'
          '       • "up" or "north"\n'
          '       • "down" or "south"\n\n'
          'Note:\n'
          '   • By default, the width of the door will be 1/3 of the length of the <side> it is being added to.',
      imagePath: 'door_command_pics/default_door.png',
    ),
    CommandDetails(
      command: '"select door <door number>"',
      description:
          'Selects the door with the specified number to perform actions on it. The selected door will be colored green.\n'
          '   • The <door number> is the number of the door that you want to select (e.g. "door 1", etc.).\n\n'
          'Note:\n'
          '   • The <door number> can be found by selecting the door and viewing the Info Panel.',
      imagePath: 'door_command_pics/select_door.png',
    ),
    CommandDetails(
      command: '"move door to <offset>"',
      description:
          'Moves the selected door to a specified offset from the corner of the wall of the room or cutout it is attached to.\n'
          '   • The <offset> could be any number. It represents the displacement of the door (in ft).',
    ),
    CommandDetails(
      command: '"door opens <direction>"',
      description:
          'Changes the direction in which the selected door opens. By default, every door\'s <direction> is set to "left".\n'
          '   • The <direction> could be:\n'
          '       • "left"\n'
          '       • "right"',
    ),
    CommandDetails(
      command: '"door swing <direction>"',
      description:
          'Changes the selected door to swing in the specified direction.\n'
          '   • The <direction> could be:\n'
          '       • "inward"\n'
          '       • "outward"\n'
          '       • "in"\n'
          '       • "out"',
    ),
    CommandDetails(
      command: '"resize door to <width>"',
      description:
          'Changes the width of the selected door to the specified width.\n'
          '   • The <width> could be any number. It represents the new width of the door (in ft).',
    ),
    CommandDetails(
      command: '"remove door"',
      description: 'Removes the selected door from the base.',
    ),
    CommandDetails(
      command: '"deselect"',
      description: 'Deselects the currently selected door.',
    ),
  ];
  final List<CommandDetails> windowCommands = [
    CommandDetails(
      command: '"add window on <side>"',
      description:
          'Creates a window on the specified side of the selected room or cutout.\n'
          '   • The <side> could be:\n'
          '       • "left" or "west"\n'
          '       • "right" or "east"\n'
          '       • "up" or "north"\n'
          '       • "down" or "south"\n\n'
          'Note:\n'
          '   • By default, the width of the window will be 1/3 of the length of the <side> it is being added to.',
      imagePath: 'window_command_pics/default_window.png',
    ),
    CommandDetails(
      command: '"select window <window number>"',
      description:
          'Selects the window with the specified number to perform actions on it. The selected window will be colored yellow.\n'
          '   • The <window number> is the number of the window that you want to select (e.g. "window 1", etc.).\n\n'
          'Note:\n'
          '   • The <window number> can be found by selecting the window and viewing the Info Panel.',
      imagePath: 'window_command_pics/select_window.png',
    ),
    CommandDetails(
      command: '"move window to <offset>"',
      description:
          'Moves the selected window to a specified offset from the corner of the wall of the room or cutout it is attached to.\n'
          '   • The <offset> could be any number. It represents the displacement of the window (in ft).',
    ),
    CommandDetails(
      command: '"resize window to <width>"',
      description:
          'Changes the width of the selected window to the specified width.\n'
          '   • The <width> could be any number. It represents the new width of the window (in ft).',
    ),
    CommandDetails(
      command: '"remove window"',
      description: 'Removes the selected window from the base.',
    ),
    CommandDetails(
      command: '"deselect"',
      description: 'Deselects the currently selected window.',
    ),
  ];

  final List<CommandDetails> spaceCommands = [
    CommandDetails(
      command: '"add space on <side>"',
      description:
          'Creates a space between the selected room or cutout and the adjacent room or cutout.\n'
          '   • The <side> could be:\n'
          '       • "left" or "west"\n'
          '       • "right" or "east"\n'
          '       • "up" or "north"\n'
          '       • "down" or "south"\n\n'
          'Note:\n'
          '   • By default, the width of the space will be 1/3 of the length of the <side> it is being added to.',
      imagePath: 'space_command_pics/default_space.png',
    ),
    CommandDetails(
      command: '"select space <space number>"',
      description:
          'Selects the space with the specified number to perform actions on it. The selected space will be colored yellow.\n'
          '   • The <space number> is the number of the space that you want to select (e.g. "space 1", etc.).\n\n'
          'Note:\n'
          '   • The <space number> can be found by selecting the space and viewing the Info Panel.',
      imagePath: 'space_command_pics/select_space.png',
    ),
    CommandDetails(
      command: '"move space to <offset>"',
      description:
          'Moves the selected space to a specified offset from the corner of the wall of the room or cutout it is attached to.\n'
          '   • The <offset> could be any number. It represents the displacement of the space (in ft).',
    ),
    CommandDetails(
      command: '"resize space to <width>"',
      description:
          'Changes the width of the selected space to the specified width.\n'
          '   • The <width> could be any number. It represents the new width of the space (in ft).',
    ),
    CommandDetails(
      command: '"remove space"',
      description: 'Removes the selected space from the base.',
    ),
    CommandDetails(
      command: '"deselect"',
      description: 'Deselects the currently selected space.',
    ),
  ];

  final List<CommandDetails> miscellaneousCommands = [
    CommandDetails(
      command: '"scale <way>"',
      description: 'Zooms in or out, depending on the <way>.\n'
          '   • The <way> could be:\n'
          '       • "in"\n'
          '       • "out"',
    ),
    CommandDetails(
      command: '"reset scale"',
      description: 'Resets the zoom level to the default level.',
    ),
    CommandDetails(
      command: '"scale to <level>"',
      description: 'Changes the zoom level to the specified <level>.\n'
          '   • The <level> could be any number. It represents the new zoom level.',
    ),
    CommandDetails(
      command: '"deselect"',
      description: 'Deselects the currently selected element.',
    ),
  ];

  Widget _buildCommandCategory(String title, IconData icon,
      {bool isSelected = false}) {
    return Container(
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        selected: isSelected,
        onTap: () {
          setState(() {
            _selectedCategory = title;
            _selectedCommand = null;
          });
        },
      ),
    );
  }

  List<CommandDetails> _getCurrentCategoryCommands() {
    switch (_selectedCategory) {
      case 'Miscellaneous Commands':
        return miscellaneousCommands;
      case 'Base Commands':
        return baseCommands;
      case 'Room Commands':
        return roomCommands;
      case 'Stairs Commands':
        return stairsCommands;
      case 'Cutout Commands':
        return cutoutCommands;
      case 'Door Commands':
        return doorCommands;
      case 'Window Commands':
        return windowCommands;
      case 'Space Commands':
        return spaceCommands;
      // Add other categories here
      default:
        return [];
    }
  }

  String _getCurrentCategoryDescription() {
    switch (_selectedCategory) {
      case 'Miscellaneous Commands':
        return 'This category contains commands that are not related to the floor plan design itself, but rather to the overall floor plan.';
      case 'Base Commands':
        return 'The \'base\' is the first thing that you will create when creating your floor plan design. There can ONLY be one base per floor in a floor plan design.';
      case 'Room Commands':
        return 'Rooms are the building blocks of your floor plan. You can add multiple rooms within a base.\n\n'
            'Requirement:\n'
            '   • Base must be present on the current floor.';
      case 'Stairs Commands':
        return 'Stairs are used to connect different floors of a building. You can add multiple stairs within a base.\n\n'
            'Requirement:\n'
            '   • Base must be present on the current floor.';
      case 'Cutout Commands':
        return 'Cutouts are used to show the expansions of a room. These should be used usually with a Space, to show that this cutout is a part of a room.\n\n'
            'Requirement:\n'
            '   • Base must be present on the current floor.';
      case 'Door Commands':
        return 'Doors show the entrances to rooms or cutouts.\n\n'
            'Requirement:\n'
            '   • Base must be present on the current floor.\n'
            '   • Room or Cutout must be selected.';
      case 'Window Commands':
        return 'Windows are used to show the windows in a room or cutout.\n\n'
            'Requirement:\n'
            '   • Base must be present on the current floor.\n'
            '   • Room or Cutout must be selected.';
      case 'Space Commands':
        return 'Spaces are used to show the spaces between rooms or cutouts.\n\n'
            'Requirement:\n'
            '   • Base must be present on the current floor.\n'
            '   • Room or Cutout must be selected.';
      // Add other categories here
      default:
        return '';
    }
  }

  Widget _buildCommandDetailsView(CommandDetails command) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.all(32),
      child: ListView(
        children: [
          Text(
            'Description',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          if (command.imagePath != null) ...[
            Image.asset(
              command.imagePath!,
              fit: BoxFit.contain,
              height: 300,
            ),
            const SizedBox(height: 32),
          ],
          Text(
            command.description,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 32),
          if (command.variations != null && command.variations!.isNotEmpty) ...[
            Text(
              'Variations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            ...command.variations!.map(
              (variation) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• "$variation"',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: 1200,
        height: 800,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Column(
            children: [
              // Dialog Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Row(
                  children: [
                    if (_selectedCommand != null)
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 28,
                        ),
                        onPressed: () =>
                            setState(() => _selectedCommand = null),
                      ),
                    Text(
                      _selectedCommand?.command ?? 'Voice Commands',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: Row(
                  children: [
                    // Left Navigation Panel (Categories)
                    Container(
                      width: 300,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      child: ListView(
                        children: [
                          _buildCommandCategory(
                            'Miscellaneous Commands',
                            Icons.more_horiz,
                            isSelected:
                                _selectedCategory == 'Miscellaneous Commands',
                          ),
                          _buildCommandCategory(
                            'Base Commands',
                            Icons.home,
                            isSelected: _selectedCategory == 'Base Commands',
                          ),
                          _buildCommandCategory(
                            'Room Commands',
                            Icons.square_outlined,
                            isSelected: _selectedCategory == 'Room Commands',
                          ),
                          _buildCommandCategory(
                            'Stairs Commands',
                            Icons.stairs,
                            isSelected: _selectedCategory == 'Stairs Commands',
                          ),
                          _buildCommandCategory(
                            'Cutout Commands',
                            Icons.cut,
                            isSelected: _selectedCategory == 'Cutout Commands',
                          ),
                          _buildCommandCategory(
                            'Door Commands',
                            Icons.door_front_door,
                            isSelected: _selectedCategory == 'Door Commands',
                          ),
                          _buildCommandCategory(
                            'Window Commands',
                            Icons.window,
                            isSelected: _selectedCategory == 'Window Commands',
                          ),
                          _buildCommandCategory(
                            'Space Commands',
                            Icons.space_bar,
                            isSelected: _selectedCategory == 'Space Commands',
                          ),
                          // ... other categories
                        ],
                      ),
                    ),
                    // Right Content Panel
                    Expanded(
                      child: _selectedCommand == null
                          ? Container(
                              padding: const EdgeInsets.all(24),
                              child: ListView(
                                children: [
                                  Text(
                                    _getCurrentCategoryDescription(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  Text(
                                    'Commands',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ..._getCurrentCategoryCommands()
                                      .map((cmd) => InkWell(
                                            onTap: () => setState(
                                                () => _selectedCommand = cmd),
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                  bottom: 8),
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surface,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Theme.of(context)
                                                      .dividerColor,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.chevron_right,
                                                    size: 20,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(cmd.command),
                                                ],
                                              ),
                                            ),
                                          )),
                                ],
                              ),
                            )
                          : _buildCommandDetailsView(_selectedCommand!),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
