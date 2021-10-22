# Tetris 

A simple tetris clone written in
[zig programming language](https://github.com/andrewrk/zig).

[YouTube Demo](https://www.youtube.com/watch?v=AiintPutWrE).


![](http://i.imgur.com/umuNndz.png)

[Windows 64-bit build](http://superjoe.s3.amazonaws.com/temp/tetris.zip)

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

 * [Zig compiler](https://github.com/andrewrk/zig) - use the debug build.
 * [libepoxy](https://github.com/anholt/libepoxy)
 * [GLFW](http://www.glfw.org/)

## Building and Running

```
zig build play
```

## Building on windows using vcpkg

* Install vcpkg https://github.com/microsoft/vcpkg
* Install dependencies using `x64-windows` triplet
* Use the flags `-Dwindows -Dvcpkg` when building the project

