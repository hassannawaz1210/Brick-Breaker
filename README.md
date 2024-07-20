# Brick-Breaker
Brick Breaker in x86 Assembly language 

## Overview

Welcome to the Brick Breaker game! This classic arcade-style game challenges you to eliminate all the bricks at the top of the screen by hitting them with a ball. Your objective is to complete all the levels without losing all your lives. The game is split into multiple levels, and you have a time limit of 4 minutes to complete each level.

## Game Features

### Levels

#### Level 1

- **Title Page**: The game starts with a title page displaying the game's name and allows you to enter your name, which will be displayed on the screen.
- **Menu Page**: The second screen is menu-driven, enabling you to navigate through different game options.
- **Gameplay Page**: This is the main game screen where you control a paddle to hit the ball and eliminate the bricks. You can move the paddle left and right using arrow keys or other designated keys. The game tracks your lives, and a heart-shaped icon indicates your remaining lives. The score is displayed on the screen.

#### Level 2

- The ball speed increases.
- The paddle's length shortens.
- Bricks require two hits to disappear, changing color after the first hit.

#### Level 3

- Some bricks are fixed and will bounce the ball back when hit.
- Normal bricks now require 3 hits to disappear.
- A special brick randomly appears. When hit, it causes 5 random bricks (or all remaining bricks if less than 5) to disappear.
- Ball speed increases.

### File Handling

- The game stores all players' scores, including their names and highest scores, using file handling.
  
## Controls

- Use arrow keys (or designated keys) to move the paddle left and right.
- Interact with menus and screens using keys as specified in the game.

### Sound Features

- The game utilizes sound effects to enhance the gaming experience.

### Screens
<img src="https://github.com/user-attachments/assets/256ef2ab-843b-4932-a5bf-f4fdea936791" width="330px" height="200px">
<img src="https://github.com/user-attachments/assets/19f7e959-09a1-4b71-aa8b-0b9843c1e66f" width="330px" height="200px">
<img src="https://github.com/user-attachments/assets/94ffd9d0-d2cc-478e-aec0-94e80db9faed" width="330px" height="200px">

## Prerequisites:

You need the following to run the game:
1. masm 6.15
2. dosBox

## Getting Started

1. Clone the repository to your local machine.
2. Copy all the files to the bin folder of masm615
3. Compile game.asm
4. Run game in dosBox

## License

This game is distributed under the [MIT License](LICENSE).
