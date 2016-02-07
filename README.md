# Tetris 

A simple tetris clone written in
[zig programming language](https://github.com/andrewrk/zig).

![](http://i.imgur.com/Z7y4WeY.png)

## Status

 * Playable game. Missing features:
   - Speed up over time
   - Display score
   - Display ghost of where piece would drop
   - Sound effects and music
   - Game over animation

## Dependencies

 * [Zig compiler](https://github.com/andrewrk/zig) - use the debug build.
 * [libepoxy](https://github.com/anholt/libepoxy)
 * [GLFW](http://www.glfw.org/)

## Building and Running

 0. Install the dependencies.
 0. `zig build src/main.zig`
 0. `./tetris`
