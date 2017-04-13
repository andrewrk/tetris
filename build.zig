const Builder = @import("std").build.Builder;

pub fn build(b: &Builder) {
    const release = b.option(bool, "release", "optimizations on and safety off") ?? false;

    var exe = b.addExecutable("tetris", "src/main.zig");
    exe.setRelease(release);

    exe.linkLibrary("c");
    exe.linkLibrary("m");
    exe.linkLibrary("glfw");
    exe.linkLibrary("epoxy");
    exe.linkLibrary("png");
    exe.linkLibrary("z");

    b.default_step.dependOn(&exe.step);
}
