const Builder = @import("std").build.Builder;
const builtin = @import("builtin");

pub fn build(b: &Builder) %void {
    const mode = b.standardReleaseOptions();
    const windows = b.option(bool, "windows", "create windows build") ?? false;

    var exe = b.addExecutable("tetris", "src/main.zig");
    exe.setBuildMode(mode);

    if (windows) {
        exe.setTarget(builtin.Arch.x86_64, builtin.Os.windows, builtin.Environ.gnu);
    }

    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("m");
    exe.linkSystemLibrary("glfw");
    exe.linkSystemLibrary("epoxy");
    exe.linkSystemLibrary("png");
    exe.linkSystemLibrary("z");

    b.default_step.dependOn(&exe.step);

    b.installArtifact(exe);

    const play = b.step("play", "Play the game");
    const run = b.addCommand(".", b.env_map,
        [][]const u8{exe.getOutputPath(), });
    play.dependOn(&run.step);
    run.step.dependOn(&exe.step);

}
