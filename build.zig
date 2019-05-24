const Builder = @import("std").build.Builder;
const builtin = @import("builtin");

pub fn build(b: *Builder) void {
    const mode = b.standardReleaseOptions();
    const windows = b.option(bool, "windows", "create windows build") orelse false;

    var exe = b.addExecutable("tetris", "src/main.zig");
    exe.addCSourceFile("stb_image-2.22/stb_image_impl.c", [][]const u8{"-std=c99"});
    exe.setBuildMode(mode);

    if (windows) {
        exe.setTarget(builtin.Arch.x86_64, builtin.Os.windows, builtin.Abi.gnu);
    }

    exe.addIncludeDir("stb_image-2.22");

    exe.linkSystemLibrary("c");
    exe.linkSystemLibrary("m");
    exe.linkSystemLibrary("glfw");
    exe.linkSystemLibrary("epoxy");

    b.default_step.dependOn(&exe.step);

    b.installArtifact(exe);

    const play = b.step("play", "Play the game");
    const run = exe.run();
    play.dependOn(&run.step);
}
