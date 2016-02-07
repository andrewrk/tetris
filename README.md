# Tetris 

A simple tetris clone written in
[zig programming language](https://github.com/andrewrk/zig).

![](http://i.imgur.com/yowEnE2.png)

## Status

 * Playable game. Missing features:
   - Sound effects and music

## Controls

 * Left/Right/Down Arrow - Move piece left/right/down.
 * Up Arrow - Rotate piece clockwise.
 * Shift - Rotate piece counter clockwise.
 * Space - Drop piece immediately.
 * R - Start new game.
 * Escape - Quit.

## Dependencies

 * [Zig compiler](https://github.com/andrewrk/zig) - use the debug build.
 * [libepoxy](https://github.com/anholt/libepoxy)
 * [GLFW](http://www.glfw.org/)
 * [libpng](http://www.libpng.org/pub/png/libpng.html)

## Building and Running

 0. Install the dependencies.
 0. `zig build src/main.zig`
 0. `./tetris`
