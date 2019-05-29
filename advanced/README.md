# advanced/ folder of zig tetris project ...

Note that there are files named "repo.symlink" where each is a symlink
to the root of the repo. This makes it easier for advanced implementations to reuse
the core tetris logic such as tetris.zig.

## advanced/ncurses

Implementation that uses ncurses instead of glfw.

Requires libncurses5-dev to be installed to build.

    $ cd advanced/ncurses
    $ zig build play
