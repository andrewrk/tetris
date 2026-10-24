# Tetris 

A simple Tetris clone written in [Zig](https://ziglang.org/).

![](http://i.imgur.com/umuNndz.png)

## Controls

 * Left/Right/Down Arrow - Move piece left/right/down.
 * Up Arrow - Rotate piece clockwise.
 * Shift - Rotate piece counter clockwise.
 * Space - Drop piece immediately.
 * Left Ctrl - Hold piece.
 * R - Start new game.
 * P - Pause and unpause game.
 * Escape - Quit.

## Dependencies

 * [Zig compiler](https://ziglang.org/) - minimum version 0.17.0-dev.657+2faf8debf (see `build.zig.zon`)
 * [libepoxy](https://github.com/anholt/libepoxy)
 * [GLFW](http://www.glfw.org/)

## Building and Running

```
zig build play
```
