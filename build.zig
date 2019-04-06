const buildImport = @import("std").build;
const Builder = buildImport.Builder;
const builtin = @import("builtin");

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const windows = b.option(bool, "windows", "create windows build") orelse false;
    buildGlfw(b, mode, windows);
    buildNcurses(b, mode, windows);
}

pub fn buildGlfw(b: *Builder, mode: builtin.Mode, windows: bool) void {
    var exe = b.addExecutable("tetris", "src/main.zig");
    exe.setBuildMode(mode);

    if (windows) {
        exe.setTarget(builtin.Arch.x86_64, builtin.Os.windows, builtin.Abi.gnu);
    }

    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("m");
    exe.linkSystemLibrary("glfw");
    exe.linkSystemLibrary("epoxy");
    exe.linkSystemLibrary("png");
    exe.linkSystemLibrary("z");

    b.installArtifact(exe);

    const play = b.step("play", "Play the game");
    const run = exe.run();
    play.dependOn(&run.step);

    b.default_step.dependOn(&exe.step);
}

pub fn buildNcurses(b: *Builder, mode: builtin.Mode, windows: bool) void {
    var exe = b.addExecutable("ncurses-tetris", "src/ncursesmain.zig");
    exe.setBuildMode(mode);

    if (windows) {
        exe.setTarget(builtin.Arch.x86_64, builtin.Os.windows, builtin.Abi.gnu);
    }

    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("m");
    exe.linkSystemLibrary("ncurses");

    b.installArtifact(exe);

    const play = b.step("play-ncurses-tetris", "Play the (ncurses) game");
    const run = exe.run();
    play.dependOn(&run.step);

    const ncurses = b.step("ncurses-tetris", "Build (ncurses) game");
    ncurses.dependOn(&exe.step);
}
